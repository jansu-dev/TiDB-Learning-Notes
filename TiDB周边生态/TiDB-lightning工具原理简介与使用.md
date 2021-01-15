# TiDB-lightning工具原理简介与使用
时间：2021-01-11

> - [lighting简介](lighting简介)
> - [下载部署](下载部署)
> - [TiDB-backend-CASE实验](#TiDB-backend-CASE实验)
> - [Importer-backend-CASE实验](#Importer-backend-CASE实验)
> - [Local-backend-CASE实验](#Local-backend-CASE实验)
>    - [local-backend注意事项](#local-backend注意事项)




## lighting简介

 - 使用场景  
    1. 大量新数据的快速导入  
    2. 全量备份数据的恢复  

 - 导入模式-[具体使用参考官网介绍](https://docs.pingcap.com/zh/tidb/stable/tidb-lightning-backends)
    1. Importer-backend（默认）
    2. Local-backend  
    3. TiDB-backend
    
 - 三种方式特点  

| 后端 |	Local-backend |	Importer-backend |	TiDB-backend |
| --- | --- | --- | --- |
| 速度 |	快 (~500 GB/小时) |	快 (~400 GB/小时) |	慢 (~50 GB/小时) |
| 资源使用率 |	高 |	高 |	低 |
| 占用网络带宽 |	高 |	中 |	低 |
| 导入时是否满足 ACID |	否 |	否 |	是 |
| 目标表 |	必须为空 |	必须为空 |	可以不为空 |
| 额外组件 |	无 |	tikv-importer |	无 |
| 支持 TiDB 集群版本 |	>= v4.0.0 |	全部 |	全部 |

## 下载部署

 - [TiDB-官方下载地址：https://docs.pingcap.com/zh/tidb/stable/download-ecosystem-tools#tidb-lightning](https://docs.pingcap.com/zh/tidb/stable/download-ecosystem-tools#tidb-lightning)

 - wget下载
   ```
   [tidb@tiup-tidb41 ~]$ wget https://download.pingcap.org/   tidb-toolkit-v4.0.9-linux-amd64.tar.gz
   ```


## TiDB-backend-CASE实验
```
MySQL [jan]> select * from t;
+----+-------+
| id | name  |
+----+-------+
|  1 | jan_1 |
|  2 | jan_1 |
|  3 | jan_2 |
|  4 | jan_3 |
|  5 | jan_4 |
|  6 | jan_5 |
|  7 | jan_7 |
+----+-------+

MySQL [jan]> drop table t;

[tidb@tiup-tidb41 backend]$ vi lightning.toml 

[tidb@tiup-tidb41 backend]$ cat lightning.toml 
[lightning]
level = "info"
file = "tidb-jan-lightning.log"
[tikv-importer]
backend = "tidb"
sorted-kv-dir = "/home/tidb/lightning/backend/sort_dir"
[mydumper]
data-source-dir = "/home/tidb/dumpling_dir"
[tidb]
host = "192.168.169.41"
port = 4000
user = "root"
password = ""
status-port = 10080
pd-addr = "192.168.169.42:2379"



[tidb@tiup-tidb41 backend]$ ll
total 32
-rwx------ 1 tidb tidb    70 Jan 15 03:00 lightning.sh
-rw-rw-r-- 1 tidb tidb   503 Jan 15 03:13 lightning.toml
-rw-rw-r-- 1 tidb tidb    82 Jan 15 03:18 nohup.out
drwxrwxr-x 2 tidb tidb     6 Jan 15 03:03 sort_dir
-rw-r--r-- 1 tidb tidb 19393 Jan 15 03:21 tidb-jan-lightning.log

MySQL [jan]> select * from t;
+----+-------+
| id | name  |
+----+-------+
|  1 | jan_1 |
|  2 | jan_1 |
|  3 | jan_2 |
|  4 | jan_3 |
|  5 | jan_4 |
|  6 | jan_5 |
|  7 | jan_7 |
+----+-------+
```

## Importer-backend-CASE实验
 - 下载并配置importer；  
 - 编写tikv-importer.toml任务文件；  
 - 启动 TiDB importer 任务并导入；
```
[tidb@tiup-tidb41 importer]$ tiup install tikv-importer

[tidb@tiup-tidb41 importer]$ tiup list --installed |grep importer
tikv-importer   pingcap 

[tidb@tiup-tidb41 importer]$ cat tikv-importer.toml 
log-file = "tikv-importer.log"
log-level = "info"
status-server-address = "0.0.0.0:8286"
[server]
addr = "0.0.0.0:8287"
grpc-concurrency = 16
[metric]
job = "tikv-importer"
interval = "15s"
address = ""
[rocksdb]
max-background-jobs = 32
[rocksdb.defaultcf]
write-buffer-size = "1GB"
max-write-buffer-number = 8
compression-per-level = ["lz4", "no", "no", "no", "no", "no", "lz4"]
[rocksdb.writecf]
compression-per-level = ["lz4", "no", "no", "no", "no", "no", "lz4"]
[import]
import-dir = "/data/tidb-data/tikv-20160/import"
num-threads = 16
num-import-jobs = 24
max-prepare-duration = "5m"
region-split-size = "512MB"
stream-channel-window = 128
max-open-engines = 8
upload-speed-limit = "512MB"
min-available-ratio = 0.05

[tidb@tiup-tidb41 importer]$ tiup tikv-importer -C tikv-importer.toml 

# 或者后台运行
nohup /root/tidb-toolkit-v4.0.2-linux-amd64/bin/tikv-importer -C tikv-importer.toml > nohup.out &
```
 - 编写lightning.toml任务文件
 - 创建 TiDB importer 任务并导入
```
[tidb@tiup-tidb41 importer]$ cat lightning.toml
[lightning]
level = "info"
file = "tidb-jan-lightning.log"
[tikv-importer]
backend = "importer"
addr = "192.168.169.41:8287"
[mydumper]
data-source-dir = "/home/tidb/dumpling_dir"
[tidb]
host = "192.168.169.41"
port = 4000
user = "root"
password = ""
status-port = 10080
pd-addr = "192.168.169.42:2379"
[checkpoint]
enable = true
schema = "tidb_lightning_checkpoint"
driver = "file"
dsn = "/home/tidb/lightning/importer/tidb_lightning_checkpoint.pb"
keep-after-success = false

[tidb@tiup-tidb41 importer]$ cat lightning.sh
#!/bin/bash
nohup tidb-lightning -config lightning.toml > nohup.out &


[tidb@tiup-tidb41 importer]$ ./lightning.sh 
[tidb@tiup-tidb41 importer]$ nohup: redirecting stderr to stdout
```

## Local-backend-CASE实验


 - 创建测试数据表；
 - 破坏性实验删除 jan.t 表；
 - local backend 模式导入 jan.t表数据；
```shell 
MySQL [jan]> select * from t;
+----+-------+
| id | name  |
+----+-------+
|  1 | jan_1 |
|  2 | jan_1 |
|  3 | jan_2 |
|  4 | jan_3 |
|  5 | jan_4 |
|  6 | jan_5 |
|  7 | jan_7 |
+----+-------+

MySQL [jan]> drop table t;
```
 - 编写lightning.toml启动文件
   [lightning.toml官网详细参数说明](https://docs.pingcap.com/zh/tidb/stable/tidb-lightning-configuration)
```
[tidb@tiup-tidb41 lighting]$ vi lightning.toml 

[tidb@tiup-tidb41 lighting]$ cat lightning.toml 
[lightning]
# 转换数据的并发数，默认为逻辑 CPU 数量，不需要配置。
# 混合部署的情况下可以配置为逻辑 CPU 的 75% 大小。
# region-concurrency =
# 日志
level = "info"
file = "tidb-jan-lightning.log"

[tikv-importer]
# backend 设置为 local 模式
backend = "local"
# 设置本地临时存储路径
sorted-kv-dir = "/home/tidb/lighting/sort_dir"

[mydumper]
# Mydumper 源数据目录。
data-source-dir = "/home/tidb/dumpling_dir"

[tidb]
# 目标集群的信息。tidb-server 的监听地址，填一个即可。
host = "192.168.169.41"
port = 4000
user = "root"
password = ""
# 表架构信息在从 TiDB 的“状态端口”获取。
status-port = 10080
# pd-server 的地址，填一个即可
pd-addr = "192.168.169.42:2379"
```
 - 创建启动脚本，防止signal信号关闭nohup
```
[tidb@tiup-tidb41 lighting]$ vi lightning.sh 

[tidb@tiup-tidb41 lighting]$ cat lightning.sh 
#!/bin/bash
nohup tidb-lightning -config lightning.toml > nohup.out &
```
 - 启动lightning使用local backend导入
```
[tidb@tiup-tidb41 lightning]$ ll
total 8
-rwx------ 1 tidb tidb  70 Jan 15 02:13 lightning.sh
-rw-rw-r-- 1 tidb tidb 774 Jan 15 02:29 lightning.toml
drwxrwxr-x 2 tidb tidb   6 Jan 15 02:28 sort_dir

[tidb@tiup-tidb41 lightning]$ ./lightning.sh 

[tidb@tiup-tidb41 lightning]$ nohup: redirecting stderr to stdout

# 若导入成功，日志的最后一行会显示 tidb lightning exit

[tidb@tiup-tidb41 lightning]$ tail -1 tidb-jan-lightning.log 
[2021/01/15 02:33:06.038 -05:00] [INFO] [main.go:95] ["tidb lightning exit"]


MySQL [jan]> select * from t;
+----+-------+
| id | name  |
+----+-------+
|  1 | jan_1 |
|  2 | jan_1 |
|  3 | jan_2 |
|  4 | jan_3 |
|  5 | jan_4 |
|  6 | jan_5 |
|  7 | jan_7 |
+----+-------+
```

#### local-backend注意事项
1. 空间要求新导入数据的目标 TiKV 集群的总存储空间必须大于 数据源大小 × 副本数量 × 2，如：默认 3 副本，总存储空间需为数据源大小的 6 倍以上。
2. tidb-lightning 是 CPU 密集型程序，混合部署时需要限制 tidb-lightning 的 CPU 实际占用核数，以免影响其他程序的正常运行，官方建议：混合部署机器 75% CPU 资源配给 tidb-lightning，如：机器为 32 核，region-concurrency 设为 “24”。
3. TiDB Lightning 运行后，TiDB 集群将无法正常对外提供服务，若 tidb-lightning 崩溃，集群会留在“导入模式”，会产生大量未压缩的文件，消耗 CPU 导致延迟，需用 tidb-lightning-ctl 手动将集群转回“普通模式”
```
bin/tidb-lightning-ctl --switch-mode=normal
```