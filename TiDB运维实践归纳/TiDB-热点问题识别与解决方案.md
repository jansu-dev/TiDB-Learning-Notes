# TiDB-热点问题识别与解决方案


> - [Batch-DML](#SERIALIZABLE序列化CASE实验)  



## 定位大表并发写入瓶颈
```
[tidb@tiup-tidb41 conf]$ tiup ctl pd region topwrite
Found ctl newer version:

    The latest version:         v4.0.9
    Local installed version:    v4.0.2
    Update current component:   tiup update ctl
    Update all components:      tiup update --all

Starting component `ctl`: /home/tidb/.tiup/components/ctl/v4.0.2/ctl pd region topwrite
{
  "count": 16,
  "regions": [
    {
      "id": 34,
      "start_key": "7480000000000000FF1500000000000000F8",
      "end_key": "7480000000000000FF1700000000000000F8",
      "epoch": {
        "conf_ver": 17,
        "version": 11
      },
      "peers": [
        {
          "id": 36,
          "store_id": 4
        },
        {
          "id": 112,
          "store_id": 6
        },
        {
          "id": 1024,
          "store_id": 1
        }
      ],
      "leader": {
        "id": 112,
        "store_id": 6
      },
      "written_bytes": 890,
      "read_bytes": 290994,
      "written_keys": 14,
      "read_keys": 5351,
      "approximate_size": 1,
      "approximate_keys": 0
    },
    ......
    ......
  ]
}



[tidb@tiup-tidb41 conf]$ curl http://192.168.169.41:10080/regions/34
{
 "start_key": "dIAAAAAAAAAV",
 "end_key": "dIAAAAAAAAAX",
 "start_key_hex": "748000000000000015",
 "end_key_hex": "748000000000000017",
 "region_id": 34,
 "frames": [
  {
   "db_name": "mysql",
   "table_name": "stats_meta",
   "table_id": 21,
   "is_record": false,
   "index_name": "idx_ver",
   "index_id": 1
  },
  {
   "db_name": "mysql",
   "table_name": "stats_meta",
   "table_id": 21,
   "is_record": false,
   "index_name": "tbl",
   "index_id": 2
  },
  {
   "db_name": "mysql",
   "table_name": "stats_meta",
   "table_id": 21,
   "is_record": true
  }
 ]
}[tidb@tiup-tidb41 conf]$ 

```
解决办法

```
TiDB 对于 PK 非整数或没有 PK 的表，会使用一个隐式的自增主键 rowID：_tidb_rowid，这个隐藏的自增主键可以通过设置 SHARD_ROW_ID_BITS 来把 rowID 打散写入多个不同的 Region 中，缓解写入热点问题。但是设置的过大也会造成 RPC 请求数放大，增加 CPU 和网络开销。

SHARD_ROW_ID_BITS = 4 表示 2^4（16） 个分片
SHARD_ROW_ID_BITS = 6 表示 2^6（64） 个分片
SHARD_ROW_ID_BITS = 0 则表示默认值 1 个分片
使用示例：

CREATE TABLE t (c int) SHARD_ROW_ID_BITS = 4;
ALTER TABLE t SHARD_ROW_ID_BITS = 4;
SHARD_ROW_ID_BITS 的值可以动态修改，每次修改之后，只对新写入的数据生效。可以根据业务并发度来设置合适的值来尽量解决此类热点 Region 无法打散的问题。

另外在 TiDB 3.1.0 版本中还引入了一个新的关键字 AUTO_RANDOM （实验功能），这个关键字可以声明在表的整数类型主键上，替代 AUTO_INCREMENT，让 TiDB 在插入数据时自动为整型主键列分配一个值，消除行 ID 的连续性，从而达到打散热点的目的，更详细的信息可以参考 AUTO_RANDOM 详细说明。

2.新表高并发读写的瓶颈问题


MySQL [jan]> ALTER TABLE jan SHARD_ROW_ID_BITS = 4;
ERROR 1146 (42S02): Table 'jan.jan' doesn't exist
MySQL [jan]> ALTER TABLE jan_test SHARD_ROW_ID_BITS = 4;
Query OK, 0 rows affected (3.35 sec)

MySQL [jan]> show create table jan_test\G
*************************** 1. row ***************************
       Table: jan_test
Create Table: CREATE TABLE `jan_test` (
  `id` int(11) DEFAULT NULL,
  `name` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin/*!90000 SHARD_ROW_ID_BITS=4 */
1 row in set (0.00 sec)
```


## 热点打散

```
SPLIT TABLE jan_test BETWEEN (0) AND (1600000) REGIONS 100;

SHOW TABLE test_hotspot REGIONS; 语句查看打散的情况。如果 SCATTERING 列值全部为 0，代表调度成功。
```

也可以通过 table-regions.py 脚本，查看 


## autorandom使用
```
MySQL [jan]> create table t (a int primary key auto_random);
ERROR 8216 (HY000): Invalid auto random: auto_random option must be defined on `bigint` column, but not on `int` column
MySQL [jan]> drop table t;
Query OK, 0 rows affected (0.23 sec)

MySQL [jan]> create table t (a int primary key auto_random);
ERROR 8216 (HY000): Invalid auto random: auto_random option must be defined on `bigint` column, but not on `int` column
MySQL [jan]> create table t (a bigint primary key auto_random);
Query OK, 0 rows affected, 1 warning (0.54 sec)

MySQL [jan]> insert into t values (), ();
Query OK, 2 rows affected (0.03 sec)
Records: 2  Duplicates: 0  Warnings: 0

MySQL [jan]> select * from t;
+---------------------+
| a                   |
+---------------------+
| 5476377146882523137 |
| 5476377146882523138 |
+---------------------+
2 rows in set (0.00 sec)

MySQL [jan]> insert into t values (), ();
Query OK, 2 rows affected (0.02 sec)
Records: 2  Duplicates: 0  Warnings: 0

MySQL [jan]> select * from t;
+---------------------+
| a                   |
+---------------------+
| 1152921504606846979 |
| 1152921504606846980 |
| 5476377146882523137 |
| 5476377146882523138 |
+---------------------+
4 rows in set (0.00 sec)

MySQL [jan]> select last_insert_id();
+---------------------+
| last_insert_id()    |
+---------------------+
| 1152921504606846979 |
+---------------------+
1 row in set (0.00 sec)


```
如果该 INSERT 语句没有指定整型主键列（a 列）的值，TiDB 会为该列自动分配值。该值不保证自增，不保证连续，只保证唯一，避免了连续的行 ID 带来的热点问题。
如果该 INSERT 语句显式指定了整型主键列的值，和 AutoIncrement 属性类似，TiDB 会保存该值。
若在单条 INSERT 语句中写入多个值，AutoRandom 属性会保证分配 ID 的连续性，同时 LAST_INSERT_ID() 返回第一个分配的值，这使得可以通过 LAST_INSERT_ID() 结果推断出所有被分配的 ID。


