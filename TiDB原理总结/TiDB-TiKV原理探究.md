# TiDB-TiKV原理探究
时间：2021/01/07

> - [保存数据总结](#保存数据总结)  
> - [Key-Value存储模型](#Key-Value存储模型)
> - [Raft协议实现](#Key-Value存储模型)
> - [percolater冲突case](#percolater冲突case)



## 保存数据总结


## Key-Value存储模型

#### 查询ROW_ID

如果表有整数型的 Primary Key，那么会用 Primary Key 的值当做 RowID ，在全局无法查询 _tidb_rowid 虚拟列。

```
create table jan_uni_test(id int primary key,name varchar(20),age int);
insert into jan_uni_test values(1,'jan_1',11),(2,'jan_2',12),(3,'jan_3',13);

mysql> show tables;
+---------------+
| Tables_in_jan |
+---------------+
| jan_uni_test  |
+---------------+
1 rows in set (0.00 sec)


mysql> show table jan_uni_test next_row_id;
+---------+--------------+-------------+--------------------+----------------+
| DB_NAME | TABLE_NAME   | COLUMN_NAME | NEXT_GLOBAL_ROW_ID | ID_TYPE        |
+---------+--------------+-------------+--------------------+----------------+
| jan     | jan_uni_test | _tidb_rowid |                  1 | AUTO_INCREMENT |
+---------+--------------+-------------+--------------------+----------------+
1 row in set (0.00 sec)

mysql> select _tidb_rowid,id,name from jan_test;
+-------------+------+-------+
| _tidb_rowid | id   | name  |
+-------------+------+-------+
|           1 |    1 | jan_1 |
|           2 |    2 | jan_2 |
|           3 |    3 | jan_3 |
+-------------+------+-------+
3 rows in set (0.00 sec)
```

普通查询索引查看 _tidb_rowid 虚拟列。

```
mysql> create table jan_test(id int,name varchar(20),age int);
mysql> insert into jan_test values(1,'jan_1',11),(2,'jan_2',12),(3,'jan_3',13);

mysql> show table jan_test next_row_id;
+---------+------------+-------------+--------------------+----------------+
| DB_NAME | TABLE_NAME | COLUMN_NAME | NEXT_GLOBAL_ROW_ID | ID_TYPE        |
+---------+------------+-------------+--------------------+----------------+
| jan     | jan_test   | _tidb_rowid |            2000001 | AUTO_INCREMENT |
+---------+------------+-------------+--------------------+----------------+
1 row in set (0.00 sec)

mysql> select _tidb_rowid,id,name from jan_uni_test;
ERROR 1054 (42S22): Unknown column '_tidb_rowid' in 'field list'
```

```
Key: tablePrefix{tableID}_recordPrefixSep{rowID}
Value: [col1, col2, col3, col4]
```


其中 Key 的 tablePrefix/recordPrefixSep 都是特定的字符串常量，用于在 KV 空间内区分其他数据。

#### 索引数据的编码规则

对于 Index 数据，会按照如下规则编码成 Key-Value pair：

```
Key: tablePrefix{tableID}_indexPrefixSep{indexID}_indexedColumnsValue
Value: rowID
```

Index 数据还需要考虑 Unique Index 和非 Unique Index 两种情况，对于 Unique Index，可以按照上述。


非 Unique Index，通过这种编码并不能构造出唯一的 Key，因为同一个 Index 的 tablePrefix{tableID}_indexPrefixSep{indexID} 都一样，可能有多行数据的 ColumnsValue 是一样的，所以对于非 Unique Index 的编码做了一点调整：

```
Key: tablePrefix{tableID}_indexPrefixSep{indexID}_indexedColumnsValue_rowID
Value: null
```
这样能够对索引中的每行数据构造出唯一的 Key。 注意上述编码规则中的 Key 里面的各种 xxPrefix 都是字符串常量，作用都是区分命名空间，以免不同类型的数据之间相互冲突，定义如下：

```
var(
	tablePrefix     = []byte{'t'}
	recordPrefixSep = []byte("_r")
	indexPrefixSep  = []byte("_i")
)
```


另外请大家注意，上述方案中，无论是 Row 还是 Index 的 Key 编码方案，一个 Table 内部所有的 Row 都有相同的前缀，一个 Index 的数据也都有相同的前缀。这样具体相同的前缀的数据，在 TiKV 的 Key 空间内，是排列在一起。同时只要我们小心地设计后缀部分的编码方案，保证编码前和编码后的比较关系不变，那么就可以将 Row 或者 Index 数据有序地保存在 TiKV 中。


这种保证编码前和编码后的比较关系不变 的方案我们称为 Memcomparable，对于任何类型的值，两个对象编码前的原始类型比较结果，和编码成 byte 数组后（注意，TiKV 中的 Key 和 Value 都是原始的 byte 数组）的比较结果保持一致。具体的编码方案参见 TiDB 的 codec 包。采用这种编码后，

现在我们结合开始提到的需求以及 TiDB 的映射方案来看一下，这个方案是否能满足需求。首先我们通过这个映射方案，将 Row 和 Index 数据都转换为 Key-Value 数据，且每一行、每一条索引数据都是有唯一的 Key。其次，这种映射方案对于点查、范围查询都很友好，我们可以很容易地构造出某行、某条索引所对应的 Key，或者是某一块相邻的行、相邻的索引值所对应的 Key 范围。最后，

 - 在保证表中的一些 Constraint 的时候，可以通过构造并检查某个 Key 是否存在来判断是否能够满足相应的 Constraint

至此我们已经聊完了如何将 Table 映射到 KV 上面，这里再举个简单的例子，便于大家理解，还是以上面的表结构为例。假设表中有 3 行数据：

Copy
1, "TiDB", "SQL Layer", 10
2, "TiKV", "KV Engine", 20
3, "PD", "Manager", 30
那么首先每行数据都会映射为一个 Key-Value pair，注意这个表有一个 Int 类型的 Primary Key，所以 RowID 的值即为这个 Primary Key 的值。假设这个表的 Table ID 为 10，其 Row 的数据为：

Copy
t10_r1 --> ["TiDB", "SQL Layer", 10]
t10_r2 --> ["TiKV", "KV Engine", 20]
t10_r3 --> ["PD", "Manager", 30]
除了 Primary Key 之外，这个表还有一个 Index，假设这个 Index 的 ID 为 1，则其数据为：

Copy
t10_i1_10_1 --> null
t10_i1_20_2 --> null
t10_i1_30_3 --> null
大家可以结合上面的编码规则来理解这个例子，希望大家能理解我们为什么选择了这个映射方案，这样做的目的是

## Raft协议实现



## percolater冲突case








因为整个系统里面我们可以看到上一张图里面有很多 Raft group 给我们，不同 Raft group 之间的通讯都是有开销的。所以我们有一个类似于 MySQL 的 group commit 机制 ，你发消息的时候实际上可以 share 同一个 connection ， 然后 pipeline + batch 发送, 很大程度上可以省掉大量 syscall 的开销



然后 TiKV 的 Raft 实现，是从 etcd 里面 port 过来的，为什么要从 etcd 里面 port 过来呢？首先 TiKV 的 Raft 实现是用 Rust 写的。作为第一个做到生产级别的 Raft 实现，所以我们从 etcd 里面把它用 Go 语言写的 port 到这边





比如说 Leader Election、Membership Changes，这个是非常重要的，整个系统的 scale 过程高度依赖 Membership Changes，



isolation level 就不讲了，MySQL 里面的级别是可以调的，我们的 TiKV 有 SI，还有 SI+lock，默认是支持 SI 的这种隔离级别，然后你写一个 select for update 语句，这个会自动的调整到 SI 加上 lock 这个隔离级别。
这个隔离级别基本上和 SSI 是一致的



本质上分布式事务就是 2PC 或者是 2+xPC，基本上没有 1PC，除非你在别人的级别上做弱化。比如说我允许你读到当前最新的版本，也允许你读到前面的版本，书里面把这个叫做幻读。如果你调到这个程度是比较容易做 1PC 的，这个实际上还是依赖用户设定的隔离级别的，如果用户需要更高的隔离级别，这个 1PC 就不太好做了。




