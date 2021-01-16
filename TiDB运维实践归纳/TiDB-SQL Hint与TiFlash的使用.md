# SQL Hint与TiFlash的使用

> - [TiFlash的使用](#TiFlash的使用)



## TiFlash的使用

```
MySQL [jan]> ALTER TABLE jan.jan_test SET TIFLASH REPLICA 1; 
Query OK, 0 rows affected (0.26 sec)

MySQL [jan]> SELECT * FROM information_schema.tiflash_replica
    -> WHERE TABLE_SCHEMA = 'jan' and TABLE_NAME = 'jan_test';
+--------------+------------+----------+---------------+-----------------+-----------+----------+
| TABLE_SCHEMA | TABLE_NAME | TABLE_ID | REPLICA_COUNT | LOCATION_LABELS | AVAILABLE | PROGRESS |
+--------------+------------+----------+---------------+-----------------+-----------+----------+
| jan          | jan_test   |       48 |             1 |                 |         1 |        1 |
+--------------+------------+----------+---------------+-----------------+-----------+----------+
1 row in set (0.01 sec)

MySQL [jan]> create table jan_test_tiflash like jan.jan_test;
Query OK, 0 rows affected (0.26 sec)

MySQL [jan]> SELECT * FROM information_schema.tiflash_replica
    -> WHERE TABLE_SCHEMA = 'jan' and TABLE_NAME = 'jan_test_tiflash';
+--------------+------------------+----------+---------------+-----------------+-----------+----------+
| TABLE_SCHEMA | TABLE_NAME       | TABLE_ID | REPLICA_COUNT | LOCATION_LABELS | AVAILABLE | PROGRESS |
+--------------+------------------+----------+---------------+-----------------+-----------+----------+
| jan          | jan_test_tiflash |       78 |             1 |                 |         1 |        1 |
+--------------+------------------+----------+---------------+-----------------+-----------+----------+
1 row in set (0.01 sec)

MySQL [jan]> explain select count(*) from jan.jan_test where name='jan_test1';
+------------------------------+---------+--------------+----------------+------------------------------------+
| id                           | estRows | task         | access object  | operator info                      |
+------------------------------+---------+--------------+----------------+------------------------------------+
| StreamAgg_34                 | 1.00    | root         |                | funcs:count(Column#9)->Column#4    |
| └─TableReader_35             | 1.00    | root         |                | data:StreamAgg_9                   |
|   └─StreamAgg_9              | 1.00    | cop[tiflash] |                | funcs:count(1)->Column#9           |
|     └─Selection_31           | 5.12    | cop[tiflash] |                | eq(jan.jan_test.name, "jan_test1") |
|       └─TableFullScan_30     | 5120.00 | cop[tiflash] | table:jan_test | keep order:false                   |
+------------------------------+---------+--------------+----------------+------------------------------------+
5 rows in set (0.03 sec)
```
