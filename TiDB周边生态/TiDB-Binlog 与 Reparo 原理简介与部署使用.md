# TiDB-Binlog 与 Reparo 原理简介与部署使用


> - [Binlog原理简介](#Binlog原理简介)
> - [下载部署](#下载部署)
> - [配置pump与drainer](#配置pump与drainer)
> - [Binlog启动与验证](#Binlog启动与验证)   
> - [checkpoint一致性检查](#checkpoint一致性检查)   
> - [Binlog-Relaylog启动与验证](#Binlog-Relaylog启动与验证)  
> - [BR配合TiDB-Binlog实现增量备份](#BR配合TiDB-Binlog实现增量备份)  
>    - [异常情况下修改Pump/Drainer状态](#异常情况下修改Pump/Drainer状态)   
> - [binlogctl工具的下载与使用](#binlogctl工具的下载与使用)   
>    - [工具的下载部署](#工具的下载部署)   
>    - [工具的使用](#工具的使用)   
> - [BR配合TiDB-Binlog实现增量备份](#BR配合TiDB-Binlog实现增量备份)   
>    - [环境与数据准备](#环境与数据准备)   
>    - [BR全量备份](#BR全量备份)   
>    - [破坏性删库](#破坏性删库)   
>    - [BR全量恢复](#BR全量恢复)  
>    - [Reparo基于时间点增量恢复](#Reparo基于时间点增量恢复)  
>    - [验证基于时间点恢复正确性](#验证基于时间点恢复正确性)   
> - [参考文章](#参考文章)   






## Binlog原理简介

![TiDB Binlog 整体架构](https://download.pingcap.com/images/docs-cn/tidb-binlog-cluster-architecture.png)

 - TiDB Binlog 支持以下功能场景   
    - 数据同步：同步 TiDB 集群数据到其他数据库   
    - 实时备份和恢复：备份 TiDB 集群数据，同时可以用于 TiDB 集群故障时恢复   

 - Pump: 用于实时记录 TiDB 产生的 Binlog，并将 Binlog 按照事务的提交时间进行排序，再提供给 Drainer 进行消费     
 - Drainer: 从各个 Pump 中收集 Binlog 进行归并，再将 Binlog 转化成 SQL 或者指定格式的数据，最终同步到下游   

## 下载部署
```
[tidb@tiup-tidb41 binlogctl]$ tiup install 组件名称

[tidb@tiup-tidb41 binlogctl]$ tiup list --installed
Available components:
Name            Owner    Description
----            -----    -----------
......
......
drainer         pingcap  The drainer componet of TiDB binlog service
pump            pingcap  The pump componet of TiDB binlog service
......
......
```

## 配置pump与drainer
```shell

vim binglog-scale-out.yaml

pump_servers:
  - host: 192.168.169.41
    ssh_port: 22
    port: 8250
    deploy_dir: "/data/tidb-deploy/pump-8250"
    data_dir: "/data/tidb-data/pump-8250"
    log_dir: "/data/tidb-deploy/pump-8250/log"
    numa_node: "0"
    # The following configs are used to overwrite the `server_configs.drainer` values.
    config:
      gc: 7
  - host: 192.168.169.42
    ssh_port: 22
    port: 8250
    deploy_dir: "/data/tidb-deploy/pump-8250"
    data_dir: "/data/tidb-data/pump-8250"
    log_dir: "/data/tidb-deploy/pump-8250/log"
    numa_node: "0"
  - host: 192.168.169.43
    ssh_port: 22
    port: 8250
    deploy_dir: "/data/tidb-deploy/pump-8250"
    data_dir: "/data/tidb-data/pump-8250"
    log_dir: "/data/tidb-deploy/pump-8250/log"
    numa_node: "0"

drainer_servers:
  - host: 192.168.169.44
    port: 8249
    data_dir: "/data/tidb-data/drainer-8249"
    # If drainer doesn't have a checkpoint, use initial commitTS as the initial checkpoint.
    # Will get a latest timestamp from pd if commit_ts is set to -1 (the default value).
    commit_ts: -1
    deploy_dir: "/data/tidb-deploy/drainer-8249"
    log_dir: "/data/tidb-deploy/drainer-8249/log"
    numa_node: "0"
#     # The following configs are used to overwrite the `server_configs.drainer` values.
    config:
      syncer.db-type: "mysql"
      syncer.to.host: "192.168.169.45"
      syncer.to.user: "root"
      syncer.to.password: "123123"
      syncer.to.port: 3306

[tidb@tiup-tidb41 pump]$ tiup cluster scale-out tidb-test binglog-scale-out.yaml --wait-timeout 10000000
Starting component `cluster`: /home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster scale-out tidb-test binglog-scale-out.yaml --wait-timeout 10000000
Please confirm your topology:
Cluster type:    tidb
......
......
+ [ Serial ] - UpdateTopology: cluster=tidb-test
Scaled cluster `tidb-test` out successfully
```


## Binlog启动与验证

```shell
MySQL [(none)]> show variables like "log_bin";
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| log_bin       | 0     |
+---------------+-------+


MySQL [(none)]> show pump status;
+---------------------+---------------------+--------+--------------------+---------------------+
| NodeID              | Address             | State  | Max_Commit_Ts      | Update_Time         |
+---------------------+---------------------+--------+--------------------+---------------------+
| 192.168.169.41:8250 | 192.168.169.41:8250 | online | 422310029132038145 | 2021-01-18 10:48:33 |
| 192.168.169.42:8250 | 192.168.169.42:8250 | online | 422310029105561601 | 2021-01-18 10:48:33 |
| 192.168.169.43:8250 | 192.168.169.43:8250 | online | 422310028725452801 | 2021-01-18 10:48:33 |
+---------------------+---------------------+--------+--------------------+---------------------+


MySQL [(none)]> show drainer status;
+---------------------+---------------------+--------+--------------------+---------------------+
| NodeID              | Address             | State  | Max_Commit_Ts      | Update_Time         |
+---------------------+---------------------+--------+--------------------+---------------------+
| 192.168.169.44:8249 | 192.168.169.44:8249 | online | 422310030704640001 | 2021-01-18 10:48:44 |
+---------------------+---------------------+--------+--------------------+---------------------+

[tidb@tiup-tidb41 ~]$ tiup cluster edit-config tidb-test
......
......
server_configs:
  tidb:
    binlog.enable: true
    binlog.ignore-error: true
......
......


[tidb@tiup-tidb41 ~]$ tiup cluster reload tidb-test -R tidb
Starting component `cluster`: /home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster reload tidb-test -R tidb
......
......
Reloaded cluster `tidb-test` successfully


MySQL [(none)]> show variables like "log_bin";
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| log_bin       | 1     |
+---------------+-------+



MySQL [(none)]> show pump status;
+---------------------+---------------------+--------+--------------------+---------------------+
| NodeID              | Address             | State  | Max_Commit_Ts      | Update_Time         |
+---------------------+---------------------+--------+--------------------+---------------------+
| 192.168.169.41:8250 | 192.168.169.41:8250 | online | 422310865001250817 | 2021-01-18 11:41:42 |
| 192.168.169.42:8250 | 192.168.169.42:8250 | online | 422310864476962817 | 2021-01-18 11:41:42 |
| 192.168.169.43:8250 | 192.168.169.43:8250 | online | 422310864752214017 | 2021-01-18 11:41:42 |
+---------------------+---------------------+--------+--------------------+---------------------+


MySQL [(none)]> show drainer status;
+---------------------+---------------------+--------+--------------------+---------------------+
| NodeID              | Address             | State  | Max_Commit_Ts      | Update_Time         |
+---------------------+---------------------+--------+--------------------+---------------------+
| 192.168.169.44:8249 | 192.168.169.44:8249 | online | 422310865787682817 | 2021-01-18 11:41:48 |
+---------------------+---------------------+--------+--------------------+---------------------+

# 上游 TiDB 端检查
MySQL [(none)]> create database test 234;

MySQL [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
......
......
| test234            |
......
......
+--------------------+

MySQL [test234]> insert into t values(1,'t_1');

MySQL [test234]> select * from t;
+----+------+
| id | name |
+----+------+
|  1 | t_1  |
+----+------+

# 下游 MySQL 端检查
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
......
......
| test234            |
......
......
+--------------------+


mysql> select * from test234.t;
+----+------+
| id | name |
+----+------+
|  1 | t_1  |
+----+------+
```

## checkpoint一致性检查
```
mysql> select  * from tidb_binlog.checkpoint;
+---------------------+----------------------------------------------------------------+
| clusterID           | checkPoint                                                     |
+---------------------+----------------------------------------------------------------+
| 6915787285265719754 | {"consistent":false,"commitTS":422311266750300163,"ts-map":{}} |
+---------------------+----------------------------------------------------------------+

```

 - tidb_binlog.checkpoint 的存储位置
  - tidb-binlog 的 pump，drianer 各个组件状态均为启动状态才会有 tidb_binlog.checkpoint
  - mysql/tidb 那么 tidb_binlog.checkpoint 表保存在被同步的目标下游 mysql/tidb 中
  - 如果是 file 那么该信息保存在本地文件系统中



## Binlog-Relaylog启动与验证

```shell

[tidb@tiup-tidb41 ~]$ tiup cluster edit-config tidb-test
Starting component `cluster`: /home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster edit-config tidb-test

[tidb@tiup-tidb41 ~]$ tiup cluster edit-config tidb-test
......
......
drainer_servers:
......
......
    syncer.relay.log-dir: /data/tidb-data/drainer-8249/relay_log
    syncer.relay.max-file-size: 10485760
......
......

Please check change highlight above, do you want to apply the change? [y/N]: y
Applying changes...
Applied successfully, please use `tiup cluster reload tidb-test [-N <nodes>] [-R <roles>]` to reload config.


# Drainer 端验证
[tidb@tiup-tidb41 bin]$ tiup cluster reload tidb-test -R drainer
Starting component `cluster`: /home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster reload tidb-test -R tidb
......
......
Reloaded cluster `tidb-test` successfully

[root@tiup-tidb44 relay_log]# pwd
/data/tidb-data/drainer-8249/relay_log
[root@tiup-tidb44 relay_log]# ll
total 0
-rw------- 1 tidb tidb 0 Jan 18 12:57 binlog-0000000000000000-20210118125724

```

#### 异常情况下修改Pump/Drainer状态
```
MySQL [test234]> change pump to node_state ='paused' for node_id '192.168.169.41:8250';

MySQL [test234]> change pump to node_state ='online' for node_id '192.168.169.41:8250';
```
 - Pump/Drainer 中状态的定义：
    - online：正常运行中
    - pausing：暂停中
    - paused：已暂停
    - closing：下线中
    - offline：已下线
 - 注意：只有在异常状态下，该命令才有作用，因为当 Pump/Drainer 存在异常时，状态信息存在于 PD 中，该命令用于修改 PD 中信息。

## binlogctl工具的下载与使用  

#### 工具的下载部署
```
wget https://download.pingcap.org/tidb-{version}-linux-amd64.tar.gz 

wget https://download.pingcap.org/tidb-{version}-linux-amd64.sha256

sha256sum -c tidb-{version}-linux-amd64.sha256

[tidb@tiup-tidb41 binlogctl]$ sha256sum -c tidb-v4.0.9-linux-amd64.sha256
tidb-v4.0.9-linux-amd64.tar.gz: OK

[tidb@tiup-tidb41 binlogctl]$ tar -xvf tidb-v4.0.9-linux-amd64.tar.gz 
```


#### 工具的使用

 - 查询所有的 Pump/Drainer 的状态
```shell
[tidb@tiup-tidb41 bin]$ ./binlogctl -pd-urls=http://192.168.169.41:2379 -cmd pumps
[2021/01/18 12:40:40.644 -05:00] [INFO] [nodes.go:53] ["query node"] [type=pump] [node="{NodeID: 192.168.169.43:8250, Addr: 192.168.169.43:8250, State: online, MaxCommitTS: 422311792296591361, UpdateTime: 2021-01-18 12:40:38 -0500 EST}"]
[2021/01/18 12:40:40.644 -05:00] [INFO] [nodes.go:53] ["query node"] [type=pump] [node="{NodeID: 192.168.169.41:8250, Addr: 192.168.169.41:8250, State: online, MaxCommitTS: 422311791614754817, UpdateTime: 2021-01-18 12:40:38 -0500 EST}"]
[2021/01/18 12:40:40.645 -05:00] [INFO] [nodes.go:53] ["query node"] [type=pump] [node="{NodeID: 192.168.169.42:8250, Addr: 192.168.169.42:8250, State: online, MaxCommitTS: 422311791929851907, UpdateTime: 2021-01-18 12:40:38 -0500 EST}"]


[tidb@tiup-tidb41 bin]$ ./binlogctl -pd-urls=http://192.168.169.41:2379 -cmd drainers
[2021/01/18 12:41:07.968 -05:00] [INFO] [nodes.go:53] ["query node"] [type=drainer] [node="{NodeID: 192.168.169.44:8249, Addr: 192.168.169.44:8249, State: online, MaxCommitTS: 422311798693167108, UpdateTime: 2021-01-18 12:41:06 -0500 EST}"]
```
 - 暂停/下线 Pump/Drainer  

| 命令 | 涵义 | 范例 |
| --- | --- | --- |
| pause-pump	| 暂停 	| Pump	 bin/binlogctl -pd-urls=http://127.0.0.1:2379 -cmd pause-pump -node-id ip-127-0-0-1:8250 |
| pause-drainer		| 暂停 	| Drainer	 bin/binlogctl -pd-urls=http://127.0.0.1:2379 -cmd pause-drainer -node-id ip-127-0-0-1:8249 |
| offline-pump		| 下线 	| Pump  bin/binlogctl -pd-urls=http://127.0.0.1:2379 -cmd offline-pump -node-id ip-127-0-0-1:8250 |
| offline-drainer		| 下线 	| Drainer  bin/binlogctl -pd-urls=http://127.0.0.1:2379 -cmd offline-drainer -node-id ip-127-0-0-1:8249 |

```
[tidb@tiup-tidb41 bin]$ binlogctl -pd-urls=http://127.0.0.1:2379 -cmd pause-pump -node-id 192.168.169.41:8250
[2021/01/18 12:44:33.347 -05:00] [INFO] [nodes.go:123] ["Apply action on node success"] [action=pause] [NodeID=192.168.169.41:8250]

[tidb@tiup-tidb41 bin]$ ./binlogctl -pd-urls=http://192.168.169.41:2379 -cmd pumps 
[2021/01/18 12:44:39.997 -05:00] [INFO] [nodes.go:53] ["query node"] [type=pump] [node="{NodeID: 192.168.169.41:8250, Addr: 192.168.169.41:8250, State: paused, MaxCommitTS: 422311853021986817, UpdateTime: 2021-01-18 12:44:32 -0500 EST}"]
......
......

MySQL [test234]> show pump status;
+---------------------+---------------------+--------+--------------------+---------------------+
| NodeID              | Address             | State  | Max_Commit_Ts      | Update_Time         |
+---------------------+---------------------+--------+--------------------+---------------------+
| 192.168.169.41:8250 | 192.168.169.41:8250 | paused | 422311853021986817 | 2021-01-18 12:44:32 |
| 192.168.169.42:8250 | 192.168.169.42:8250 | online | 422311857281826817 | 2021-01-18 12:44:48 |
| 192.168.169.43:8250 | 192.168.169.43:8250 | online | 422311856862658561 | 2021-01-18 12:44:48 |
+---------------------+---------------------+--------+--------------------+---------------------+
```

其他命令同理;

 - 异常情况下修改 Pump/Drainer 的状态

```shell
[tidb@tiup-tidb41 bin]$ ./binlogctl -pd-urls=http://192.168.169.41:2379 -cmd update-pump -node-id 192.168.169.41:8250 -state online

[tidb@tiup-tidb41 bin]$ ./binlogctl -pd-urls=http://192.168.169.41:2379 -cmd pumps
[2021/01/18 12:48:42.249 -05:00] [INFO] [nodes.go:53] ["query node"] [type=pump] [node="{NodeID: 192.168.169.41:8250, Addr: 192.168.169.41:8250, State: online, MaxCommitTS: 422311853021986817, UpdateTime: 2021-01-18 12:44:32 -0500 EST}"]
```


## BR配合TiDB-Binlog实现增量备份

#### 环境与数据准备
```
[tidb@tiup-tidb41 reparo]$ cp ~/binlogctl/tidb-v4.0.9-linux-amd64/bin/reparo ./

[tidb@tiup-tidb41 reparo]$ ll
total 51180
-rwxr-xr-x 1 tidb tidb 52407079 Jan 18 13:06 reparo



MySQL [(none)]> create database full_backup_point_recover_1;

MySQL [(none)]> create database full_backup_point_recover_2;

MySQL [(none)]> use full_backup_point_recover_1;

MySQL [full_backup_point_recover_1]> create table jan_test_1(id int auto_increment primary key, name varchar(20));

MySQL [full_backup_point_recover_1]> use full_backup_point_recover_2;

MySQL [full_backup_point_recover_2]> create table jan_test_2(id int auto_increment primary key, name varchar(20));

MySQL [full_backup_point_recover_2]> insert into full_backup_point_recover_1.jan_test_1(name) values ('jan_test_1'),('jan_test_2'),('jan_test_3');

MySQL [full_backup_point_recover_2]> insert into full_backup_point_recover_2.jan_test_2(name) values ('jan_test_1');

MySQL [full_backup_point_recover_2]> select * from full_backup_point_recover_1.jan_test_1;
+----+------------+
| id | name       |
+----+------------+
|  1 | jan_test_1 |
|  2 | jan_test_2 |
|  3 | jan_test_3 |
+----+------------+

MySQL [full_backup_point_recover_2]> select * from full_backup_point_recover_2.jan_test_2;
+----+------------+
| id | name       |
+----+------------+
|  1 | jan_test_1 |
+----+------------+

MySQL [full_backup_point_recover_2]> select now();
+---------------------+
| now()               |
+---------------------+
| 2021-01-18 13:32:26 |
+---------------------+

```

#### BR全量备份
```
[tidb@tiup-tidb41 ~]$ tiup br backup full --pd 192.168.169.42:2379 --storage "local:///home/tidb/reparo/full_backup" --ratelimit 120 --log-file /home/tidb/reparo/full_backup/log/full_backup_20200119.log

Starting component `br`: /home/tidb/.tiup/components/br/v4.0.9/br backup full --pd 192.168.169.42:2379 --storage local:///home/tidb/reparo/full_backup --ratelimit 120 --log-file /home/tidb/reparo/full_backup/log/full_backup_20200119.log
Detail BR log in /home/tidb/reparo/full_backup/log/full_backup_20200119.log 
Full backup <---------------------------------------------------------------------------------------------------------------------------------------> 100.00%
Checksum <------------------------------------------------------------------------------------------------------------------------------------------> 100.00%
[2021/01/18 13:39:52.129 -05:00] [INFO] [collector.go:60] ["Full backup Success summary: total backup ranges: 28, total success: 28, total failed: 0, total take(Full backup time): 11.599128783s, total take(real time): 15.218534235s, total kv: 841399, total size(MB): 173.31, avg speed(MB/s): 14.94"] ["backup fast checksum"=40.578617ms] ["backup checksum"=563.344738ms] ["backup total regions"=28] [BackupTS=422312719696527362] [Size=83443904]


MySQL [(none)]> select now();
+---------------------+
| now()               |
+---------------------+
| 2021-01-18 13:40:20 |
+---------------------+
```
### 破坏性删库
```

MySQL [full_backup_point_recover_2]> delete from full_backup_point_recover_1.jan_test_1 where id = 1;

MySQL [(none)]> select now();
+---------------------+
| now()               |
+---------------------+
| 2021-01-18 13:40:42 |
+---------------------+


MySQL [(none)]> select * from full_backup_point_recover_1.jan_test_1;
+----+------------+
| id | name       |
+----+------------+
|  2 | jan_test_2 |
|  3 | jan_test_3 |
+----+------------+

MySQL [(none)]> drop database full_backup_point_recover_1;


MySQL [(none)]> drop database full_backup_point_recover_2;

MySQL [(none)]> select now();
+---------------------+
| now()               |
+---------------------+
| 2021-01-18 13:50:21 |
+---------------------+

```

#### BR全量恢复
```
[tidb@tiup-tidb41 full_backup]$ tiup br restore full  --storage "local:///home/tidb/reparo/full_backup" --ratelimit 128 --log-file /home/tidb/reparo/full_backup/log/full_restore_20200119.log

Starting component `br`: /home/tidb/.tiup/components/br/v4.0.9/br restore full --storage local:///home/tidb/reparo/full_backup --ratelimit 128 --log-file /home/tidb/reparo/full_backup/log/full_restore_20200119.log
Detail BR log in /home/tidb/reparo/full_backup/log/full_restore_20200119.log 


Full restore <-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------> 100.00%
[2021/01/18 14:36:46.599 -05:00] [INFO] [collector.go:60] ["Full restore Success summary: total restore files: 23, total success: 23, total failed: 0, total take(Full restore time): 40m38.372489542s, total take(real time): 42m7.069324518s, total kv: 841399, total size(MB): 173.31, avg speed(MB/s): 0.07"] ["restore checksum"=40m33.969324142s] ["split region"=2.778469128s] ["restore ranges"=21] [Size=83443904]

MySQL [full_backup_point_recover_1]> select * from full_backup_point_recover_1.jan_test_1;
+----+------------+
| id | name       |
+----+------------+
|  1 | jan_test_1 |
|  2 | jan_test_2 |
|  3 | jan_test_3 |
+----+------------+


MySQL [full_backup_point_recover_1]> select * from full_backup_point_recover_2.jan_test_2;
+----+------------+
| id | name       |
+----+------------+
|  1 | jan_test_1 |
+----+------------+
```

#### Reparo基于时间点增量恢复

增量部分从 2021-01-18 13:32:26 开始恢复，恢复至 2021-01-18 13:40:42 时间点;

```shell
vim reparo.toml
# Drainer 输出的 protobuf 格式 binlog 文件的存储路径。
data-dir = "/data/tidb-data/drainer-8249/relay_log"
# 日志输出信息等级设置：debug, info, warn, error, fatal (默认值：info)。
log-level = "info"
# 使用 start-datetime 和 stop-datetime 来选择恢复指定时间范围内的 binlog，格式为 “2006-01-02 15:04:05”。
start-datetime = "2021-01-18 13:32:26"
stop-datetime = "2021-01-18 13:40:42"
# 下游服务类型。 取值为 print, mysql（默认值：print）。当值为 print 时，只做解析打印到标准输出，不执行 SQL；  
# 如果为 mysql，则需要在 [dest-db] 中配置 host、port、user、password 等信息。
dest-type = "mysql"
# 输出到下游数据库一个事务的 SQL 语句数量（默认 20）。
txn-batch = 20
# 同步下游的并发数，该值设置越高同步的吞吐性能越好（默认 16）。
worker-count = 16
# 安全模式配置。取值为 true 或 false（默认值：false）。当值为 true 时，Reparo 会将 update 语句拆分为 delete + replace 语句。
safe-mode = false
# replicate-do-db 和 replicate-do-table 用于指定恢复的库和表，replicate-do-db 的优先级高于 replicate-do-table。支持使用正则表达式来配置，需要以 '~' 开始声明使用正则表达式。
# 注：replicate-do-db 和 replicate-do-table 使用方式与 Drainer 的使用方式一致。
# replicate-do-db = ["~^b.*","s1"]
# [[replicate-do-table]]
# db-name ="test"
# tbl-name = "log"
# [[replicate-do-table]]
# db-name ="test"
# tbl-name = "~^a.*"

# 如果 dest-type 设置为 mysql, 需要配置 dest-db
[dest-db]
host = "192.168.169.41"
port = 4000
user = "root"
password = ""
```



#### 验证基于时间点恢复正确性
```
select * from full_backup_point_recover_1.jan_test_1;
select * from full_backup_point_recover_2.jan_test_2;
```









## 参考文章

[PingCap-Binlog 集群部署:https://docs.pingcap.com/zh/tidb/stable/deploy-tidb-binlog#tidb-binlog-%E9%9B%86%E7%BE%A4%E9%83%A8%E7%BD%B2](https://docs.pingcap.com/zh/tidb/stable/deploy-tidb-binlog#tidb-binlog-%E9%9B%86%E7%BE%A4%E9%83%A8%E7%BD%B2)

[TiIP 扩展方式集成 Pump、Drainer : https://asktug.com/t/topic/33884](https://asktug.com/t/topic/33884)


[AskTUG-部署Drainer出现异常错误:https://asktug.com/t/topic/37569](https://asktug.com/t/topic/37569)

[AskTUG-tidb_binlog.checkpoint表不存在:https://asktug.com/t/topic/33675](https://asktug.com/t/topic/33675)