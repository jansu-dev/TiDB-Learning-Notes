# TiDB-BR工具原理简介与使用
时间：2021-01-13

> - [原理简介与异常处理](#原理简介与异常处理)
> - [下载使用](#下载使用)
> - [BR存储构建与使用](#BR存储构建与使用)
> - [备份实验](#备份实验)
>     - [备份恢复所有库](#备份恢复所有库)
>     - [备份恢复单个库](#备份恢复单个库)
>     - [备份恢复单个表](#备份恢复单个表)
> - [BR备份与恢复场景](#BR备份与恢复场景)

## 原理简介

* **BR的备份过程**

![image.png](http://cdn.lifemini.cn/dbblog/20201228/845fe9f3fd83439d99db72557df3285e.png)

1. BR的备份不是由BR这个工具操作的，而是由BR给每个TIKV leader发送一个备份信息，具体的备份由TiKV节点基于Regin实现备份操作；  
2. TiKV节点会扫描对应Regin的所有键值对，并收集到备份的内存的memtable或SST file中，此时的SST file文件是暂时存在文件系统中的；  
3. 上传SST File备份文件到终端存储时，如果数据还处于内存中时直接从内存上传到终端系统（如：S3、云文件系统等），如果已经落盘到文件系统的SSt file就将SST file上传到终端文件系统。  

* **BR的恢复过程**

![image.png](http://cdn.lifemini.cn/dbblog/20201228/ed3812a5aba94719afdac381e94b69a8.png)


1. 在BR的写入阶段，首先使用16线程并行的执行CREATE TABLE TABLE_NAME IF NOT EXIST命令；  
2. 停止PD Server的调度功能，防止PD Server将正在恢复的Regin调度到其他TiKV节点，以减小无谓的开销；  
3. TiKV计入“import mode”模式，通过停止write stall trigger和compaction trigger两个功能，停止SST file文件合并，增加读方法的方式实现更快的恢复；  
4. 因为在备份的时候，是基于一个Regin备份到一个SST文件实现的，因此最快的方式是将一个SST写入到一个Regin中。相应的优化操作为通过PD Server搜集所有当前数据库的所有SST files的边界,通知PD Server将每一个备份的SST file至少执行“Batch Split”操作打散为1个SST file的多个SST file。**注意**:这里分发到Regin Leader节点，因为TiKV进行数据写入的时候是需要同故宫Raft协议实现分布式一致性，所以应当分发至不同Regin Leader；    
5. 在还没有数据的时候执行一个scatter操作将打散的SST file（也就是Regin）均匀的分发到不同的Regin leader节点。因为每一个备份的SST file还是存在于原来的Store上面的，所以需要在打散之后由PD Server调度至不同TiKV节点，防止未做此操作后还需要进行的rebalance操作；  
6. 每个Regin并行的在每个TiKV节点执行restore。  


## 异常处理

异常处理备份期间的异常和 select * 一样，可分为两种可恢复和不可恢复，所有的异常都可以直接复用 TiDB 现有的机制。

可恢复异常一般包含：

RegionError，一般由 region split/merge，not leader 造成。
KeyLocked，一般由事务冲突造成。
Server is busy，一般由于 TiKV 太忙造成。
当发生这些异常时，备份的进度不会被打断。

除了以上的其他错误都是不可恢复异常，发生后，它们会打断备份的进度




## 下载使用
```
[tidb@tiup-tidb41 ~]$ tiup list --installed
Available components:
Name     Owner    Description
----     -----    -----------
......
......

[tidb@tiup-tidb41 ~]$ tiup install br

[tidb@tiup-tidb41 ~]$ tiup list --installed
Available components:
Name     Owner    Description
----     -----    -----------
br       pingcap  TiDB/TiKV cluster backup restore tool
......
......
```

## 备份实验



#### 全库备份
假数据准备
```
MySQL [jan]> drop database jan;
Query OK, 0 rows affected (4 min 32.04 sec)

MySQL [jan]> create table t (id int auto_increment primary key,name varchar(20));
ERROR 1046 (3D000): No database selected
MySQL [jan]> 
MySQL [jan]> 
MySQL [jan]> 
MySQL [jan]> 
MySQL [jan]> create database jan;
Query OK, 0 rows affected (1 min 31.06 sec)

MySQL [jan]> use jan;
Database changed
MySQL [jan]> create table t (id int auto_increment primary key,name varchar(20));
Query OK, 0 rows affected (1 min 31.07 sec)

MySQL [jan]> insert into t(name) values ('jan_1'),('jan_1'),('jan_2'),('jan_3'),('jan_4'),('jan_5'),('jan_6');
Query OK, 7 rows affected (0.08 sec)
Records: 7  Duplicates: 0  Warnings: 0
```

```
[tidb@tiup-tidb41 dump]$ tiup br backup full --pd 192.168.169.42:2379 --storage "local:///home/tidb/dump" --ratelimit 120 --log-file /home/tidb/dump/backup_test_20200113.log

Starting component `br`: /home/tidb/.tiup/components/br/v4.0.9/br backup full --pd 192.168.169.42:2379 --storage local:///home/tidb/dump --ratelimit 120 --log-file /home/tidb/dump/backup_test_20200113.log
Detail BR log in /home/tidb/dump/backup_test_20200113.log 
Full backup <--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------> 100.00%
Checksum <-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------> 100.00%
[2021/01/13 06:13:56.586 -05:00] [INFO] [collector.go:60] ["Full backup Success summary: total backup ranges: 1, total success: 1, total failed: 0, total take(Full backup time): 137.842139ms, total take(real time): 2.391735164s, total kv: 7, total size(Byte): 231, avg speed(Byte/s): 1675.83"] ["backup checksum"=4.227804ms] ["backup fast checksum"=227.427µs] ["backup total regions"=1] [BackupTS=422192463034187781] [Size=3547]

[tidb@tiup-tidb41 dump]$ pwd
/home/tidb/dump

[tidb@tiup-tidb41 dump]$ ll
total 20
-rw-r--r-- 1 tidb tidb   78 Jan 13 06:13 backup.lock
-rw-r--r-- 1 tidb tidb 1974 Jan 13 06:13 backupmeta
-rw-r--r-- 1 tidb tidb 8590 Jan 13 06:13 backup_test_20200113.log

[tidb@tiup-tidb42 dump]$ scp * tidb@192.168.169.41:/home/tidb/dump/
1_2_41_4151ddbaa5a571f9163cea2f452ff4b700964464f40b4f2e42a6a625516a7a50_1610536435186_write.sst                                                                                 100% 1573   223.7KB/s   00:00    
[tidb@tiup-tidb42 dump]$ scp * tidb@192.168.169.43:/home/tidb/dump/
1_2_41_4151ddbaa5a571f9163cea2f452ff4b700964464f40b4f2e42a6a625516a7a50_1610536435186_write.sst                                                                                 100% 1573   641.7KB/s   00:00    
[tidb@tiup-tidb42 dump]$ scp * tidb@192.168.169.44:/home/tidb/dump/
1_2_41_4151ddbaa5a571f9163cea2f452ff4b700964464f40b4f2e42a6a625516a7a50_1610536435186_write.sst                                                                                 100% 1573     1.1MB/s   00:00    


[tidb@tiup-tidb41 dump]$ scp backupmeta tidb@192.168.169.42:/home/tidb/dump/
backupmeta                                                                                                                                                                      100% 1974   876.6KB/s   00:00    
[tidb@tiup-tidb41 dump]$ scp backupmeta tidb@192.168.169.43:/home/tidb/dump/
backupmeta                                                                                                                                                                      100% 1974     1.5MB/s   00:00    
[tidb@tiup-tidb41 dump]$ scp backupmeta tidb@192.168.169.44:/home/tidb/dump/
backupmeta                                                                                                                                                                      100% 1974     1.1MB/s   00:00    
[tidb@tiup-tidb41 dump]$ 

```

破坏性删库
```
[tidb@tiup-tidb41 dump]$ mysql -uroot -P4000 -h127.0.0.1
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 25
Server version: 5.7.25-TiDB-v4.0.9 TiDB Server (Apache License 2.0) Community Edition, MySQL 5.7 compatible

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MySQL [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| INFORMATION_SCHEMA |
| METRICS_SCHEMA     |
| PERFORMANCE_SCHEMA |
| jan                |
| mysql              |
+--------------------+
5 rows in set (0.00 sec)

MySQL [(none)]> drop database jan;

MySQL [(none)]> admin show ddl jobs where state !='synced'\G
*************************** 1. row ***************************
      JOB_ID: 90
     DB_NAME: jan
  TABLE_NAME: 
    JOB_TYPE: drop schema
SCHEMA_STATE: none
   SCHEMA_ID: 46
    TABLE_ID: 0
   ROW_COUNT: 0
  START_TIME: 2021-01-13 04:15:22
    END_TIME: NULL
       STATE: done
1 row in set (0.01 sec)

```
[相关链接](https://github.com/tidb-incubator/tidb-in-action/blob/master/session1/chapter7/tidb-ddl-status.md)

```
[tidb@tiup-tidb41 dump]$ ll
total 844
-rw-r--r-- 1 tidb tidb     78 Jan 13 04:11 backup.lock
-rw-r--r-- 1 tidb tidb 824319 Jan 13 04:11 backupmeta
-rw-r--r-- 1 tidb tidb  28995 Jan 13 04:12 backup_test_20200113.log

[tidb@tiup-tidb42 dump]$ ll
total 107988
-rw-r--r-- 1 tidb tidb 24734912 Jan 13 04:11 1_2_35_272976c6cf256d05cbdf843d7857a520a0951c1b1fcd63722849f1999033749a_1610529077740_write.sst
-rw-r--r-- 1 tidb tidb    20569 Jan 13 04:11 1_3057_149_13c22adf454101e9f2bac0533151b8ebb935a90814e49926b466626c00dd2889_1610529076199_write.sst
-rw-r--r-- 1 tidb tidb    22897 Jan 13 04:11 1_3061_147_38e4059222579a22c8c937f6506dd8e2198a19c3d7fb4a245c0a4f804cd85adc_1610529076008_write.sst
-rw-r--r-- 1 tidb tidb     1560 Jan 13 04:11 1_3070_155_7477d6846cccd9f0c90d7349e94ba96ee85a084375d5af0e8aa6a494dec07303_1610529076008_write.sst
-rw-r--r-- 1 tidb tidb     1436 Jan 13 04:11 1_4005_32_365b5cb37ca9ad3087e9017c1c702f4cecab854f42a8e0b9631f71c97c60664f_1610529077714_write.sst
-rw-r--r-- 1 tidb tidb     1443 Jan 13 04:11 1_4005_32_88494a0648b69288e3801ce4327908e5b6d38a4a9e9c139c369d910b850b9fca_1610529077740_write.sst
-rw-r--r-- 1 tidb tidb 26373373 Jan 13 04:11 1_4009_33_7a5a42016e83a868289e8ed42ab09dcc363c888256a093ff00a257eac48efd11_1610529076237_write.sst
-rw-r--r-- 1 tidb tidb  6144937 Jan 13 04:11 1_4009_33_d2ca8661ae1d442d40624a054d8b96d4a7c3a908df07bd6c897f13dd53ee55cf_1610529076238_write.sst
-rw-r--r-- 1 tidb tidb 22764596 Jan 13 04:11 1_4013_34_d71f168d153c1af3b98295fd7cad21c8d32eea032bbfa71bf0db97ea57d0dfd9_1610529077740_write.sst
-rw-r--r-- 1 tidb tidb 24403792 Jan 13 04:11 1_4017_35_2bbcd667caad45265d1c33dd3f497ba21482fb0c8f16b7324696478751f5eed3_1610529076238_write.sst
-rw-r--r-- 1 tidb tidb  6089825 Jan 13 04:11 1_4017_35_8fb95df2b801941130265350028cfd0401ad472ba834e27d710167beadd8c45f_1610529076996_write.sst
[tidb@tiup-tidb43 dump]$ ll
total 0
[tidb@tiup-tidb44 dump]$ ll
total 0

[tidb@tiup-tidb42 dump]$ pwd
/home/tidb/dump

[tidb@tiup-tidb42 dump]$ scp * tidb@192.168.169.41:/home/tidb/dump/
[tidb@tiup-tidb42 dump]$ scp * tidb@192.168.169.43:/home/tidb/dump/
[tidb@tiup-tidb42 dump]$ scp * tidb@192.168.169.44:/home/tidb/dump/
[tidb@tiup-tidb41 dump]$ scp backup.lock tidb@192.168.169.44:/home/tidb/dump/
backup.lock                                                                                                                                                                     100%   78    13.5KB/s   00:00    
[tidb@tiup-tidb41 dump]$ scp backup.lock tidb@192.168.169.43:/home/tidb/dump/
backup.lock                                                                                                                                                                     100%   78    56.7KB/s   00:00    
[tidb@tiup-tidb41 dump]$ scp backup.lock tidb@192.168.169.42:/home/tidb/dump/
backup.lock                                                                                                                                                                     100%   78    39.4KB/s   00:00    
[tidb@tiup-tidb41 dump]$ scp backupmeta tidb@192.168.169.42:/home/tidb/dump/
backupmeta                                                                                                                                                                      100%  805KB  18.3MB/s   00:00    
[tidb@tiup-tidb41 dump]$ scp backupmeta tidb@192.168.169.43:/home/tidb/dump/
backupmeta                                                                                                                                                                      100%  805KB  16.6MB/s   00:00    
[tidb@tiup-tidb41 dump]$ scp backupmeta tidb@192.168.169.44:/home/tidb/dump/
backupmeta    
```


恢复集群数据
```
[tidb@tiup-tidb41 dump]$ tiup br restore full  --storage "local:///home/tidb/dump" --ratelimit 128 --log-file /home/tidb/dump/restore_full_20200113.log

Starting component `br`: /home/tidb/.tiup/components/br/v4.0.9/br restore full --storage local:///home/tidb/dump --ratelimit 128 --log-file /home/tidb/dump/restore_full_20200113.log
Detail BR log in /home/tidb/dump/restore_full_20200113.log 
Full restore <-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------> 100.00%
[2021/01/13 06:31:58.707 -05:00] [INFO] [collector.go:60] ["Full restore Success summary: total restore files: 2, total success: 2, total failed: 0, total take(Full restore time): 1m32.96573719s, total take(real time): 1m34.630538562s, total kv: 7, total size(Byte): 231, avg speed(Byte/s): 2.48"] ["split region"=151.347912ms] ["restore checksum"=1m32.605810906s] ["restore ranges"=1] [Size=3547]
```

验证数据
```
[tidb@tiup-tidb41 dump]$ mysql -uroot -P4000 -h127.0.0.1
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 5
Server version: 5.7.25-TiDB-v4.0.9 TiDB Server (Apache License 2.0) Community Edition, MySQL 5.7 compatible

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MySQL [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| INFORMATION_SCHEMA |
| METRICS_SCHEMA     |
| PERFORMANCE_SCHEMA |
| jan                |
| mysql              |
+--------------------+
5 rows in set (0.00 sec)

MySQL [jan]> select * from jan.t;
+----+-------+
| id | name  |
+----+-------+
|  1 | jan_1 |
|  2 | jan_1 |
|  3 | jan_2 |
|  4 | jan_3 |
|  5 | jan_4 |
|  6 | jan_5 |
|  7 | jan_6 |
+----+-------+
7 rows in set (0.01 sec)
```


#### 备份恢复单个数据库

```
[tidb@tiup-tidb41 db]$ tiup br backup db  --pd "192.168.169.42:2379" --db jan --storage "local:///home/tidb/dump/db" --ratelimit 120 --log-file /home/tidb/dump/db/log/backup_db_20200113.log
Starting component `br`: /home/tidb/.tiup/components/br/v4.0.9/br backup db --pd 192.168.169.42:2379 --db jan --storage local:///home/tidb/dump/db --ratelimit 120 --log-file /home/tidb/dump/db/log/backup_db_20200113.log
Detail BR log in /home/tidb/dump/db/log/backup_db_20200113.log 
Database backup <----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------> 100.00%
Checksum <-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------> 100.00%
[2021/01/13 07:43:31.355 -05:00] [INFO] [collector.go:60] ["Database backup Success summary: total backup ranges: 1, total success: 1, total failed: 0, total take(Database backup time): 30.014407ms, total take(real time): 1.559716893s, total kv: 7, total size(Byte): 231, avg speed(Byte/s): 7696.30"] ["backup fast checksum"=260.12µs] ["backup checksum"=29.76911ms] ["backup total regions"=1] [Size=3543] [BackupTS=422193872202366979]
```

破坏性删库
```
MySQL [(none)]> drop database jan;

MySQL [(none)]> admin show ddl jobs where state!='synced';
+--------+---------+------------+-------------+--------------+-----------+----------+-----------+---------------------+----------+---------+
| JOB_ID | DB_NAME | TABLE_NAME | JOB_TYPE    | SCHEMA_STATE | SCHEMA_ID | TABLE_ID | ROW_COUNT | START_TIME          | END_TIME | STATE   |
+--------+---------+------------+-------------+--------------+-----------+----------+-----------+---------------------+----------+---------+
|    151 | jan     |            | drop schema | write only   |       144 |        0 |         0 | 2021-01-13 07:44:45 | NULL     | running |
+--------+---------+------------+-------------+--------------+-----------+----------+-----------+---------------------+----------+---------+
1 row in set (0.04 sec)

MySQL [(none)]> drop database jan;

# 传输数据到各个服务器下
 

[tidb@tiup-tidb41 db]$ tiup br restore db --pd "192.168.169.42:2379" --db "jan" --storage "local:///home/tidb/dump/db" --log-file /home/tidb/dump/db/log/restore_db_tidb.log

Starting component `br`: /home/tidb/.tiup/components/br/v4.0.9/br restore db --pd 192.168.169.42:2379 --db jan --storage local:///home/tidb/dump/db --log-file /home/tidb/dump/db/log/restore_db_tidb.log
Detail BR log in /home/tidb/dump/db/log/restore_db_tidb.log 
Database restore <---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------> 100.00%
[2021/01/13 08:11:49.855 -05:00] [INFO] [collector.go:60] ["Database restore Success summary: total restore files: 2, total success: 2, total failed: 0, total take(Database restore time): 3m2.513794684s, total take(real time): 4m35.328344591s, total kv: 7, total size(Byte): 231, avg speed(Byte/s): 1.27"] ["split region"=189.436499ms] ["restore checksum"=3m2.370391626s] ["restore ranges"=1] [Size=3543]

MySQL [jan]> show databases;
+--------------------+
| Database           |
+--------------------+
| INFORMATION_SCHEMA |
| METRICS_SCHEMA     |
| PERFORMANCE_SCHEMA |
| jan                |
| mysql              |
+--------------------+
5 rows in set (0.00 sec)

MySQL [jan]> select * from jan.t;
+----+-------+
| id | name  |
+----+-------+
|  1 | jan_1 |
|  2 | jan_1 |
|  3 | jan_2 |
|  4 | jan_3 |
|  5 | jan_4 |
|  6 | jan_5 |
|  7 | jan_6 |
+----+-------+
7 rows in set (0.00 sec)
```

## 备份恢复单表
```
[tidb@tiup-tidb41 table]$ tiup br backup table --pd "192.168.169.42:2379" --db "jan" --table "t" --storage "local:///home/tidb/dump/table" --log-file /home/tidb/dump/table/log/restore_table_20200113.log

Starting component `br`: /home/tidb/.tiup/components/br/v4.0.9/br backup table --pd 192.168.169.42:2379 --db jan --table t --storage local:///home/tidb/dump/table --log-file /home/tidb/dump/table/log/restore_table_20200113.log
Detail BR log in /home/tidb/dump/table/log/restore_table_20200113.log 
Table backup <-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------> 100.00%
Checksum <-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------> 100.00%
[2021/01/13 08:15:59.994 -05:00] [INFO] [collector.go:60] ["Table backup Success summary: total backup ranges: 1, total success: 1, total failed: 0, total take(Table backup time): 260.979001ms, total take(real time): 1.877151292s, total kv: 7, total size(Byte): 231, avg speed(Byte/s): 885.13"] ["backup checksum"=35.259232ms] ["backup fast checksum"=306.388µs] ["backup total regions"=2] [BackupTS=422194382976843780] [Size=3545]
```

破坏性删表
```
MySQL [(none)]> use jan
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
MySQL [jan]> show tables;
+---------------+
| Tables_in_jan |
+---------------+
| t             |
+---------------+
1 row in set (0.00 sec)

MySQL [jan]> drop table t;
Query OK, 0 rows affected (4 min 32.45 sec)
```

恢复实验
```
[tidb@tiup-tidb41 log]$ tiup br restore table --pd "192.168.169.42:2379" --db "jan" --table "t" --storage "local:///home/tidb/dump/table" --log-file /home/tidb/dump/table/log/restore_table_20200113.log

Starting component `br`: /home/tidb/.tiup/components/br/v4.0.9/br restore table --pd 192.168.169.42:2379 --db jan --table t --storage local:///home/tidb/dump/table --log-file /home/tidb/dump/table/log/restore_table_20200113.log
Detail BR log in /home/tidb/dump/table/log/restore_table_20200113.log 
Table restore <------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------> 100.00%
[2021/01/13 08:27:15.556 -05:00] [INFO] [collector.go:60] ["Table restore Success summary: total restore files: 2, total success: 2, total failed: 0, total take(Table restore time): 3m2.607441703s, total take(real time): 3m7.902083693s, total kv: 7, total size(Byte): 231, avg speed(Byte/s): 1.27"] ["split region"=163.990339ms] ["restore checksum"=3m2.538855561s] ["restore ranges"=1] [Size=3545]


MySQL [jan]> use jan
Database changed
MySQL [jan]> select * from jan.t;
+----+-------+
| id | name  |
+----+-------+
|  1 | jan_1 |
|  2 | jan_1 |
|  3 | jan_2 |
|  4 | jan_3 |
|  5 | jan_4 |
|  6 | jan_5 |
|  7 | jan_6 |
+----+-------+
7 rows in set (0.01 sec)
```


## 参考文章

[pingcap Github-新版备份恢复设计方案:https://github.com/pingcap/br/blob/980627aa90e5d6f0349b423127e0221b4fa09ba0/docs/cn/2019-08-05-new-design-of-backup-restore.md](https://github.com/pingcap/br/blob/980627aa90e5d6f0349b423127e0221b4fa09ba0/docs/cn/2019-08-05-new-design-of-backup-restore.md)