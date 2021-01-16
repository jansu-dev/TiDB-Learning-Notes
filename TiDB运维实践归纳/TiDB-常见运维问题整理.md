# TiDB-常见运维问题整理
时间：2021-01-14

> - [TiDB转换字符集](#TiDB转换字符集)  
> - [Collation字符集排序问题](#Collation字符集排序问题)  
> - [系统时区问题](#系统时区问题)  
> - [TiKV垃圾回收GC时间](#TiKV垃圾回收GC时间)  




## TiDB转换字符集
```
MySQL [jan]> CREATE TABLE `t` (     
    ->   `a` varchar(10) DEFAULT NULL 
    ->  ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;


MySQL [jan]> show variables like '%tidb_skip_utf8_check%';
+----------------------+-------+
| Variable_name        | Value |
+----------------------+-------+
| tidb_skip_utf8_check | 0     |
+----------------------+-------+
1 row in set (0.00 sec)


MySQL [jan]> insert t values (unhex('f09f8c80'));
Query OK, 1 row affected (0.03 sec)

MySQL [jan]> select * from t;
+------+
| a    |
+------+
|      |
+------+


MySQL [jan]> alter table t change column a a varchar(20) character set utf8mb4;


MySQL [jan]> alter table t convert to character set utf8mb4;


MySQL [jan]> show create table t;
+-------+---------------------------------------------------------------------------------------------------------------+
| Table | Create Table                                                                                                  |
+-------+---------------------------------------------------------------------------------------------------------------+
| t     | CREATE TABLE `t` (
  `a` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin |
+-------+---------------------------------------------------------------------------------------------------------------+
1 row in set (0.00 sec)
```


## Collation字符集排序问题
TiDB 4.0 新增了完整的 Collation 支持框架，允许实现所有 MySQL 中的 Collation；  
配置参数 new_collation_enabled_on_first_boostrap 在集群初次初始化时决定是否启用新 Collation 框架
启用新 Collation 启用后的TiDB 修正了 utf8mb4_general_bin 和 utf8_general_bin 的行为
```shell

# 通过 mysql.tidb 表中的 new_collation_enabled 变量确认是否启用
MySQL [jan]> select VARIABLE_VALUE from mysql.tidb where VARIABLE_NAME='new_collation_enabled'\G
*************************** 1. row ***************************
VARIABLE_VALUE: False
1 row in set (0.00 sec)
```

## 系统时区问题

在 MySQL 中，系统时区 system_time_zone 在 MySQL 服务启动时通过 环境变量 TZ 或命令行参数 --timezone 指定；  
在 TiDB 中，分布式数据库的 TiDB 需要保证整个集群的系统时区始终一致，因此 TiDB 的系统时区在集群初始化时，由负责初始化的 TiDB 节点环境变量 TZ 决定，集群初始化后，固定在集群状态表 mysql.tidb 中；  

```shell
# 通过 mysql.tidb 系统表查看 TiDB 时区
tidb> select VARIABLE_VALUE from mysql.tidb where VARIABLE_NAME='system_tz';
+----------------+
| VARIABLE_VALUE |
+----------------+
| Asia/Shanghai  |
+----------------+

# 通过查看 system_time_zone 变量，可以看到该值与状态表中的 system_tz 保持一致：
tidb> select @@system_time_zone;
+--------------------+
| @@system_time_zone |
+--------------------+
| Asia/Shanghai      |
+--------------------+
1 row in set (0.00 sec)
```
**注意** TiDB 的系统时区在初始化后不再更改，若需要改变集群的时区，可以通过显式指定 time_zone 系统变量方式更改
```
tidb> set @@global.time_zone='UTC';
Query OK, 0 rows affected (0.00 sec)
```


## 乐观锁冲突检测
TiDB 在4.0.0版本以后，默认使用悲观锁保证事务，悲观锁的实现可以很好的保证事务执行的成功率；  
在事务冲突很少发生的情况下，乐观锁相比悲观锁拥有更好的性能，在4.0.0版本以前， TiDB 默认使用乐观锁保证事务；  
当出现事务冲突时，后发生的事务会默认重试，而在分布式数据库 TiDB 中，每一次重试都会去 PD Master 重新申请 TSO ，这样会导致执行结果的不一致；  

```shell
# 使用global variables 命令查看是否开启失败自动重试  
# 如果在乐观锁模式下，tidb_disable_txn_auto_retry 值为 0 表示当出现事务冲突时，直接向 TiDB 客户端返回错误
MySQL [(none)]> show global variables like '%tidb_disable_txn_auto_retry%';
+-----------------------------+-------+
| Variable_name               | Value |
+-----------------------------+-------+
| tidb_disable_txn_auto_retry | 1     |
+-----------------------------+-------+
1 row in set (0.57 sec)

# 在乐观锁模式下产生事务冲突时，最大重试次数，默认 10 次
MySQL [(none)]> show global variables like '%tidb_retry_limit%';
+------------------+-------+
| Variable_name    | Value |
+------------------+-------+
| tidb_retry_limit | 10    |
+------------------+-------+
1 row in set (0.55 sec)

# 如下为调整设置步骤
MySQL [(none)]> set @@global.tidb_disable_txn_auto_retry = 0;

MySQL [(none)]> set @@global.tidb_retry_limit = 10;
```



## TiKV垃圾回收GC时间
因为 TiKV 使用 MVCC 实现在并发条件下的事务控制,就一定需要 GC 历史数据空间回收机制，否则历史数据会无限占用硬盘空间。  
同样使用 MVCC 机制实现事务的两个数据库都有不同实现，Oracle 使用 undo 表空间来实现、PostgreSQL 使用 vacuum 机制实现。

 - GC Leader
 一个 TiDB 集群中会有一个 TiDB 实例被选举为 GC leader，GC 的运行由 GC leader 来控制，只有 GC Leader 会处理 GC 的工作，其他 TiDB Server 上的 GC Worker 处于限制状态。  
  - GC Worker 模块： GC Worker是 TiDB Server 上的一个模块，GC Leader 本质也是一个 worker；
  - 选举 GC Leader 方式：GC Worker 每分钟检查 Leader，如果没有或 Leader 失效，自己会升级为 GC Leader；   
  - Safepoint 安全点：每次 GC 时，首先计算 Safepoint 的时间戳，保证 Safepoint 之后快照全部拥有正确数据的前提下，删除Safepoint 之前的数据。

 - GC 三阶段
 Resolve Locks 清理历史锁：对所有 Region 扫描 Safepoint 之前的锁并清理；  
 Delete Ranges 回收废空间：快速地删除由于 DROP TABLE/DROP INDEX 等操作产生的整 Region 的废弃数据；  
 Do GC 历史数据回收：每个 TiKV 节点各自扫描该节点上的数据，并对每一个 key 删除其不再需要的旧版本(tableID_versionID_rowID);  
   - distributed 模式（默认），Do GC 阶段由 TiDB 上的 GC leader 向 PD 发送 Safepoint，每个 TiKV 节点各自获取该 Safepoint 并对所有当前节点上作为 leader 的 Region 进行 GC;
   - central 模式: Do GC 阶段由 GC leader 向所有的 Region 发送 GC 请求;   

```shell
MySQL [(none)]> select VARIABLE_NAME, VARIABLE_VALUE from mysql.tidb where variable_name like '%gc%'\G
*************************** 1. row ***************************
 VARIABLE_NAME: tikv_gc_leader_uuid                              # 当前的 GC Leader 的信息
VARIABLE_VALUE: 5dc2a727bd80009
*************************** 2. row ***************************
 VARIABLE_NAME: tikv_gc_leader_desc                              # 当前 GC Leader 的描述信息，包含host、 pid、start时间
VARIABLE_VALUE: host:tiup-tidb41, pid:4320, start at 2021-01-16 04:52:52.563165695 -0500 EST m=+48.242837499
*************************** 3. row ***************************
 VARIABLE_NAME: tikv_gc_leader_lease
VARIABLE_VALUE: 20210116-12:39:52 -0500                          # GC 执行到什么时间
*************************** 4. row ***************************
 VARIABLE_NAME: tikv_gc_enable                                   # 控制是否启用 GC
VARIABLE_VALUE: true
*************************** 5. row ***************************
 VARIABLE_NAME: tikv_gc_run_interval                             # 指定 GC 运行时间间隔
VARIABLE_VALUE: 10m0s
*************************** 6. row ***************************
 VARIABLE_NAME: tikv_gc_life_time                                # 每次 GC 时，保留数据的时限；每次 GC 时，将以当前时间减去该配置的值作为 Safepoint
VARIABLE_VALUE: 10m
*************************** 7. row ***************************
 VARIABLE_NAME: tikv_gc_last_run_time                            # 最近一次 GC 运行的时间（每轮 GC 开始时更新）
VARIABLE_VALUE: 20210116-12:34:52 -0500
*************************** 8. row ***************************
 VARIABLE_NAME: tikv_gc_safe_point                               # 当前的 Safepoint 
VARIABLE_VALUE: 20210116-12:24:52 -0500
*************************** 9. row ***************************
 VARIABLE_NAME: tikv_gc_auto_concurrency                         # 控制是否由 TiDB 自动决定同时进行 GC 的线程数
VARIABLE_VALUE: true
*************************** 10. row ***************************
 VARIABLE_NAME: tikv_gc_mode                                     # GC 模式：distributed（TiDB 3.0引入,默认）、central(TiDB 2.1 及更早版本采用此 GC 模式)
VARIABLE_VALUE: distributed                                      
10 rows in set (0.00 sec)
```



## 参考文章

[李坤、高振娇 - TiDB GC 之原理浅析:https://asktug.com/t/topic/67760](https://asktug.com/t/topic/67760)