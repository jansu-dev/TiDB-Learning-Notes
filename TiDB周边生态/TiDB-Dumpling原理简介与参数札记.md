# TiDB-Dumpling原理简介与参数札记


## summary
> - [原理讲解](#原理讲解)  
> - [部署方式](#部署方式)  
>   - [下载安装包](#下载安装包)
>   - [解压并配置环境变量](#解压并配置环境变量)
> - [参数简介](#参数简介)  
> - [注意事项](#注意事项)
> - [操作案例](#操作案例)
>   - [导出到csv文件](#导出到csv文件)
>   - [rows参数case精讲](#rows参数case精讲)
>   - [filesize参数case精讲](#filesize参数case精讲)


## 原理讲解


![image.png](http://cdn.lifemini.cn/dbblog/20201228/f6e704ee71424ac8833765dc53c465aa.png)



## 部署方式

#### 下载安装包
下载链接https://download.pingcap.org/tidb-toolkit-{version}-linux-amd64.tar.gz中的 **{version}** 为 Dumpling 的版本号。  
本例，以v4.0.2 版本为范例下载链接如下。
```shell
[tidb@tidb01-41 soft]$ wget https://download.pingcap.org/tidb-toolkit-v4.0.2-linux-amd64.tar.gz

--2021-01-04 08:34:25--  https://download.pingcap.org/tidb-toolkit-v4.0.2-linux-amd64.tar.gz
Resolving download.pingcap.org (download.pingcap.org)... 111.7.105.238, 111.63.182.240, 120.201.132.238, ...
Connecting to download.pingcap.org (download.pingcap.org)|111.7.105.238|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 142758194 (136M) [application/x-compressed]
Saving to: ‘tidb-toolkit-v4.0.2-linux-amd64.tar.gz’

100%[========================================================================================================================================================================>] 142,758,194 4.52MB/s   in 26s    

2021-01-04 08:34:52 (5.21 MB/s) - ‘tidb-toolkit-v4.0.2-linux-amd64.tar.gz’ saved [142758194/142758194]


[tidb@tidb01-41 soft]$ ll
total 139420
drwxrwxr-x 18 tidb tidb      4096 Dec 27 03:29 tidb-ansible
-rw-rw-r--  1 tidb tidb 142758194 Jul  1  2020 tidb-toolkit-v4.0.2-linux-amd64.tar.gz
```


#### 解压并配置环境变量
```shell
[tidb@tidb01-41 soft]$ ll
total 139420
drwxrwxr-x 18 tidb tidb      4096 Dec 27 03:29 tidb-ansible
-rw-rw-r--  1 tidb tidb 142758194 Jul  1  2020 tidb-toolkit-v4.0.2-linux-amd64.tar.gz

# 解压下载好的压缩包

[tidb@tidb01-41 soft]$ tar -xivf tidb-toolkit-v4.0.2-linux-amd64.tar.gz 
tidb-toolkit-v4.0.2-linux-amd64/
tidb-toolkit-v4.0.2-linux-amd64/bin/
tidb-toolkit-v4.0.2-linux-amd64/bin/pd-tso-bench
tidb-toolkit-v4.0.2-linux-amd64/bin/tikv-importer
tidb-toolkit-v4.0.2-linux-amd64/bin/tidb-lightning-ctl
tidb-toolkit-v4.0.2-linux-amd64/bin/br
tidb-toolkit-v4.0.2-linux-amd64/bin/sync_diff_inspector
tidb-toolkit-v4.0.2-linux-amd64/bin/mydumper
tidb-toolkit-v4.0.2-linux-amd64/bin/dumpling
tidb-toolkit-v4.0.2-linux-amd64/bin/tidb-lightning


# 修改用户环境变量配置文件
# 在结尾追加如下两行内容

[tidb@tidb01-41 soft]$ vi ~/.bash_profile 

[tidb@tidb01-41 soft]$ tail -2 ~/.bash_profile
PATH=/home/tidb/soft/tidb-toolkit-v4.0.2-linux-amd64/bin:$PATH
export PATH



# 使环境变量更改生效

[tidb@tidb01-41 soft]$ source ~/.bash_profile
[tidb@tidb01-41 soft]$ dumpling --help
```


## 参数简介

| 参数名 | 参数简写 | 参数意义 |  
| --- | --- | --- |
| --ca string              |      |   TLS ca根证书连接路径 |
| --case-sensitive         |      |   是否区分大小写 |
| --cert string            |      |   客户端TLS证书连接路径 |
| --consistency string     |      |   flush: dump 前用 FTWRL、snapshot: 通过TSO来指、dump某个快照时间点的TiDB数据、lock:对需要dump的所有表执行lock tables read命令、none:不加锁dump无法保证一致性、auto:MySQL默认用flush, TiDB 默认用 snapshot (默认："auto") |
| --csv-null-value string  |      |   csv 文件空值的表示 (默认："\\N") |
| --database strings       |  -B |   导出数据库 |
| --dump-empty-database    |      |   导出数据库元数据信息 (默认:true) |
| --escape-backslash       |      |   使用反斜线导出特殊字符 (默认:true) |
| --filesize string        |  -F |   导出文件的最大大小 |
| --filetype string        |      |   导出文件的类型(sql/csv) (默认:"sql") |
| --filter stringArray     |  -f |   过滤出需要导出的表名 (默认全部导出:[*.*]) |
| --host string            |  -h |   连接host (default "127.0.0.1") |
| --key string             |      |   客户端TLS私钥连接路径 |
| --logfile path           |  -L |   日志文件路径, leave empty to write to console |
| --logfmt format          |      |   日志格式: {text/json} (默认 "text") |
| --loglevel string        |      |   日志级别: {debug/info/warn/error/dpanic/panic/fatal} (默认:"info") |
| --no-data                |  -d |   不导出数据 |
| --no-header              |      |   不导出CSV表头信息 |
| --no-schemas             |  -m |   导出的表数据不含有模式信息 |
| --no-views               |  -W |   不导出视图，默认为true |
| --output string          |  -o |   导出文件位置路径，默认为："./export-2021-01-04T08:50:25-05:00" |
| --password string        |  -p |   用户密码 |
| --port int               |  -P |   连接端口，默认端口号：4000 |
| --rows uint              |  -r |   将表切分为n行的chunk,默认:unlimited |
| --snapshot string        |      |   快照位置 (来之pd server的uint64格式的时间戳)。 仅当快照一致性时有效(consistency=snapshot) |
| --sql string             |  -S |   导出sql语句内容的数据，这个参数不支持并发导出 |
| --statement-size uint    |  -s |   控制 INSERT SQL 语句的大小，单位 bytes |
| --status-addr string     |      |   Dumpling 的服务地址，包含了 Prometheus 拉取 metrics 信息及 pprof 调试的地址 |
| --tables-list strings    |  -T |   导出指定数据表，表明必须加双引号 |
| --threads int            |  -t |   goroutines携程（并行导出）使用的数量, 默认：4个 (default 4) |
| --tidb-mem-quota-query uint|      |   单条SQL导出最大内存使用限制, 以bytes为单位。 默认: 32GB (default 34359738368) |
| --user string            |  -u |   连接用户名 (默认："root") |
| --version                |  -V |   输出dumpling工具版本 |
| --where string           |      |   仅导出谓词过滤部分包含的数据 |


## 注意事项

1. 支持全新的table-filter，筛选数据更加方面
2. 可以通过参数配置TiDB单条SQL内存限制
3. TiDB V4.0.0以上版本已经支持自动调整TiDB GC时间的问题了
4. 使用隐藏列_tidb_rowid优化了单表内数据的并发导出性能
5. 针对TiDB可以设置tidb_snapshot的值指定备份数据的时间点，从而保证备份的一致性，而不是通过FLUSH TBLES WITH READ LOCK来保证一致性
6. 如果新建一个用户导出数据需要拥有select、reload、lock table、replication client权限，使用root用户来导出可以忽略上述问题
7. 版本支持方面：dumpling工具有go语言开发，支持MySQL5.7、8.0版本，支持MariaDB 10.3和10.4版本、TiDB 2.1及以上版本。


## 操作案例

#### 导出到 sql 文件
```shell

# 执行dumpling导出命令

[tidb@tidb01-41 soft]$ dumpling \
  -u root \
  -P 4000 \
  -h 192.168.1.41 \
  -o /home/tidb/dumpdir/sqlexp \
  --sql 'select * from `jan`.`sbtest1` where id < 100'

Release version: v4.0.2
Git commit hash: ff92fcf2fa8fc77127df21820280f6b2088b8309
Git branch:      heads/v4.0.2
Build timestamp: 2020-07-01 09:42:00Z
Go version:      go version go1.13 linux/amd64

[2021/01/04 09:11:00.450 -05:00] [INFO] [config.go:139] ["detect server type"] [type=TiDB]
[2021/01/04 09:11:00.451 -05:00] [INFO] [config.go:157] ["detect server version"] [version=3.0.1]
[2021/01/04 09:11:00.451 -05:00] [WARN] [dump.go:95] ["If the amount of data to dump is large, criteria: (data more than 60GB or dumped time more than 10 minutes)\nyou'd better adjust the tikv_gc_life_time to avoid export failure due to TiDB GC during the dump process.\nBefore dumping: run sql `update mysql.tidb set VARIABLE_VALUE = '720h' where VARIABLE_NAME = 'tikv_gc_life_time';` in tidb.\nAfter dumping: run sql `update mysql.tidb set VARIABLE_VALUE = '10m' where VARIABLE_NAME = 'tikv_gc_life_time';` in tidb.\n"]
[2021/01/04 09:11:00.580 -05:00] [INFO] [main.go:195] ["dump data successfully, dumpling will exit now"]


# 进入 SQL 文件导出目录，查看导出的文件

[tidb@tidb01-41 soft]$ cd ../dumpdir/sqlexp
[tidb@tidb01-41 dumpdir]$ pwd
/home/tidb/dumpdir
[tidb@tidb01-41 sqlexp]$ ll
total 24
-rwxr-xr-x 1 tidb tidb   140 Jan  4 09:26 metadata
-rwxr-xr-x 1 tidb tidb 19368 Jan  4 09:26 result.0.sql


# 查看dumpling导出的元数据信息

[tidb@tidb01-41 sqlexp]$ cat metadata 
Started dump at: 2021-01-04 09:26:42
SHOW MASTER STATUS:
		Log: tidb-binlog        #  binlog日志名称
		Pos: 421991652309860365 #  master binary log 的位置
Finished dump at: 2021-01-04 09:26:42   # 导出的起始时间


# 查看result.0.csv文件的前5行

[tidb@tidb01-41 sqlexp]$ head -5 result.0.sql

/*!40101 SET NAMES binary*/;
INSERT INTO `` (`id`,`k`,`c`,`pad`) VALUES
(1,2494,'31451373586-15688153734-79729593694-96509299839-83724898275-86711833539-78981337422-35049690573-51724173961-87474696253','98996621624-36689827414-04092488557-09587706818-65008859162'),
(2,2489,'21472970079-70972780322-70018558993-71769650003-09270326047-32417012031-10768856803-14235120402-93989080412-18690312264','04776826683-45880822084-77922711547-29057964468-76514263618'),
(3,2495,'49376827441-24903985029-56844662308-79012577859-40518387141-60588419212-24399130405-42612257832-29494881732-71506024440','26843035807-96849339132-53943793991-69741192222-48634174017'),
[tidb@tidb01-41 sqlexp]$ vi result.0.sql 

[tidb@tidb01-41 sqlexp]$ cat ./result.0.sql |wc -l
101
```
可以看到导出的result文件中为101行，证明--sql参数也适用于sql文件的导出。

#### 导出到csv文件
```shell

# 执行dumpling导出命令

[tidb@tidb01-41 soft]$ dumpling \
  -u root \
  -P 4000 \
  -h 192.168.1.41 \
  -o /home/tidb/dumpdir \
  --filetype csv \
  --sql 'select * from `jan`.`sbtest1` where id < 100'

Release version: v4.0.2
Git commit hash: ff92fcf2fa8fc77127df21820280f6b2088b8309
Git branch:      heads/v4.0.2
Build timestamp: 2020-07-01 09:42:00Z
Go version:      go version go1.13 linux/amd64

[2021/01/04 09:11:00.450 -05:00] [INFO] [config.go:139] ["detect server type"] [type=TiDB]
[2021/01/04 09:11:00.451 -05:00] [INFO] [config.go:157] ["detect server version"] [version=3.0.1]
[2021/01/04 09:11:00.451 -05:00] [WARN] [dump.go:95] ["If the amount of data to dump is large, criteria: (data more than 60GB or dumped time more than 10 minutes)\nyou'd better adjust the tikv_gc_life_time to avoid export failure due to TiDB GC during the dump process.\nBefore dumping: run sql `update mysql.tidb set VARIABLE_VALUE = '720h' where VARIABLE_NAME = 'tikv_gc_life_time';` in tidb.\nAfter dumping: run sql `update mysql.tidb set VARIABLE_VALUE = '10m' where VARIABLE_NAME = 'tikv_gc_life_time';` in tidb.\n"]
[2021/01/04 09:11:00.580 -05:00] [INFO] [main.go:195] ["dump data successfully, dumpling will exit now"]


# 进入 SQL 文件导出目录，查看导出的文件

[tidb@tidb01-41 soft]$ cd ../dumpdir/
[tidb@tidb01-41 dumpdir]$ pwd
/home/tidb/dumpdir
[tidb@tidb01-41 dumpdir]$ ll
total 24
-rwxr-xr-x 1 tidb tidb   140 Jan  4 09:11 metadata
-rwxr-xr-x 1 tidb tidb 19018 Jan  4 09:11 result.0.csv


# 查看dumpling导出的元数据信息

[tidb@tidb01-41 dumpdir]$ cat metadata 
Started dump at: 2021-01-04 09:11:00
SHOW MASTER STATUS:
		Log: tidb-binlog        #  binlog日志名称
		Pos: 421991405435486213 #  master binary log 的位置
Finished dump at: 2021-01-04 09:11:00   # 导出的起始时间


# 查看result.0.csv文件的前5行

[tidb@tidb01-41 dumpdir]$ head -5 result.0.csv 
"id","k","c","pad"
1,2494,"31451373586-15688153734-79729593694-96509299839-83724898275-86711833539-78981337422-35049690573-51724173961-87474696253","98996621624-36689827414-04092488557-09587706818-65008859162"
2,2489,"21472970079-70972780322-70018558993-71769650003-09270326047-32417012031-10768856803-14235120402-93989080412-18690312264","04776826683-45880822084-77922711547-29057964468-76514263618"
3,2495,"49376827441-24903985029-56844662308-79012577859-40518387141-60588419212-24399130405-42612257832-29494881732-71506024440","26843035807-96849339132-53943793991-69741192222-48634174017"
4,2594,"85762858421-36258200885-10758669419-44272723583-12529521893-95630803635-53907705724-07005352902-43001596772-53048338959","37979424284-37912826784-31868864947-42903702727-96097885121"

```

#### rows参数case精讲

#### filesize参数case精讲



## 参考文章

[TiDB官网-工具下载：https://docs.pingcap.com/zh/tidb/stable/download-ecosystem-tools#dumpling](https://docs.pingcap.com/zh/tidb/stable/download-ecosystem-tools#dumpling)