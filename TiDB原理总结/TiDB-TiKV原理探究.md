# TiDB-TiKV原理探究
时间：2021-01-07

> - [保存数据总结](#保存数据总结)  
> - [Key-Value存储模型](#Key-Value存储模型)  
> - [Raft协议实现](#Key-Value存储模型)  
> - [percolater冲突case](#percolater冲突case)  



## 保存数据总结

## Key-Value存储模型

TiKV 的映射方案将 Row 和 Index 数据都转换为 Key-Value 数据，每一行或每一条索引数据都是有唯一的 Key 可以很好的支持点查和范围查询

#### 查询ROW_ID

如果表有整数型的 Primary Key，那么会用 Primary Key 的值当做 RowID ，在全局无法查询 _tidb_rowid 虚拟列，直接查询 _tidb_rowid 会报错，如: CASE1

  - CASE1
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

  - CASE2
	未使用int类型主键的表可以直接查看 _tidb_rowid 虚拟列

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

#### 普通表数据编码原则

  ```
   Key: tablePrefix{tableID}_recordPrefixSep{rowID}
   Value: [col1, col2, col3, col4]
  ```


其中 Key 的 tablePrefix/recordPrefixSep 都是特定的字符串常量，用于在 KV 空间内区分其他数据。

#### 索引数据的编码规则

Index 数据还需要考虑 Unique Index 和非 Unique Index 两种情况  

 - 对于 Unique Index  
  数据会按照 Key-Value pair 规则编码
  ```
   Key: tablePrefix{tableID}_indexPrefixSep{indexID}_indexedColumnsValue
   Value: rowID
  ```

 - 非 Unique Index  
 采用 unique index 编码方式不能构造出唯一的 Key，因为同一个 Index 的 tablePrefix{tableID}_indexPrefixSep{indexID} 都一样，可能有多行数据的 ColumnsValue 是一样的，如：同名为 jan 的学生表中对 name 列构建索引，那么不同年龄的 jan 在索引中无法保证唯一有序，不能获取有效的 _tidb_rowid 以供后期的回表操作  
 需要采用 key 中追加 indexedColumnsValue 方式区分命名空间，以免不同类型的数据之间相互冲突  
 **采用 key 中直接包含 _rowID 本人猜测可能是为了提高索引遍历效率**

  ```
   Key: tablePrefix{tableID}_indexPrefixSep{indexID}_indexedColumnsValue_rowID
   Value: null
  ```

#### 编码案例

以ID、NAME、CONTEXT、MEMBER四列表的结构为例。假设表中 ID 为 Int 类型的 Primary Key有 3 行数据，这个表的 Table ID 为 10

 - 表key编码映射如下
   
  ```
   _tidb_rowid/ID    NAME     CONTEXT   MEMBER
       1,           "TiDB", "SQL Layer", 10
       2,           "TiKV", "KV Engine", 20
       3,           "PD",   "Manager",   30
   
              | 映 |
		    | 射 |
              | 编 |
              | 码 |
   
        key            value
      t10_r1 --> ["TiDB", "SQL Layer", 10]
      t10_r2 --> ["TiKV", "KV Engine", 20]
      t10_r3 --> ["PD", "Manager", 30]
  ```

 - 索引key编码映射如下
  除了 Primary Key 外，为 MEMBER 列加非唯一 Index，且假设这个 Index 的 ID 为 1

  ```
      t10_i1_10_1 --> null
      t10_i1_20_2 --> null
      t10_i1_30_3 --> null
  ```


## Raft协议实现



## percolater冲突case
