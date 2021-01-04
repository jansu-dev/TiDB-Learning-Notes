# TiDB-Dumpling原理简介与参数札记


## summary
> [原理讲解](#原理讲解)  
> [部署方式](#部署方式)  
> [参数简介](#参数简介)  


## 原理讲解


![image.png](http://cdn.lifemini.cn/dbblog/20201228/f6e704ee71424ac8833765dc53c465aa.png)



## 部署方式

* **下载安装包**
下载链接https://download.pingcap.org/tidb-toolkit-**{version}**-linux-amd64.tar.gz中的 **{version}** 为 Dumpling 的版本号。  
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


* **解压并配置环境变量**
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
| --ca string              |      |  The path name to the certificate authority file for TLS connection |
| --case-sensitive         |      |   whether the filter should be case-sensitive |
| --cert string            |      |   The path name to the client certificate file for TLS connection |
| --consistency string     |      |   Consistency level during dumping: {auto|none|flush|lock|snapshot} (default "auto") |
| --csv-null-value string  |      |   The null value used when export to csv (default "\\N") |
| --database strings       |  -B, |   Databases to dump |
| --dump-empty-database    |      |   whether to dump empty database (default true) |
| --escape-backslash       |      |   use backslash to escape special characters (default true) |
| --filesize string        |  -F, |   The approximate size of output file |
| --filetype string        |      |   The type of export file (sql/csv) (default "sql") |
| --filter stringArray     |  -f, |   filter to select which tables to dump (default [*.*]) |
| --host string            |  -h, |   The host to connect to (default "127.0.0.1") |
| --key string             |      |   The path name to the client private key file for TLS connection |
| --logfile path           |  -L, |   Log file path, leave empty to write to console |
| --logfmt format          |      |   Log format: {text|json} (default "text") |
| --loglevel string        |      |   Log level: {debug|info|warn|error|dpanic|panic|fatal} (default "info") |
| --no-data                |  -d, |   Do not dump table data |
| --no-header              |      |   whether not to dump CSV table header |
| --no-schemas             |  -m, |   Do not dump table schemas with the data |
| --no-views               |  -W, |   Do not dump views (default true) |
| --output string          |  -o, |   Output directory (default "./export-2021-01-04T08:50:25-05:00") |
| --password string        |  -p, |   User password |
| --port int               |  -P, |   TCP/IP port to connect to (default 4000) |
| --rows uint              |  -r, |   Split table into chunks of this many rows, default unlimited |
| --snapshot string        |      |   Snapshot position (uint64 from pd timestamp for TiDB). Valid only when consistency=snapshot |
| --sql string             |  -S, |   Dump data with given sql. This argument doesn't support concurrent dump |
| --statement-size uint    |  -s, |   Attempted size of INSERT statement in bytes |
| --status-addr string     |      |   dumpling API server and pprof addr (default ":8281") |
| --tables-list strings    |  -T, |   Comma delimited table list to dump; must be qualified table names |
| --threads int            |  -t, |   Number of goroutines to use, default 4 (default 4) |
| --tidb-mem-quota-query uint|      |   The maximum memory limit for a single SQL statement, in bytes. Default: 32GB (default 34359738368) |
| --user string            |  -u, |   Username with privileges to run the dump (default "root") |
| --version                |  -V, |   Print Dumpling version |
| --where string           |      |   Dump only selected records |

## 操作案例

* **导出到 sql 文件**
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


* **导出到 csv 文件**
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



## 参考文章

[TiDB官网-工具下载：https://docs.pingcap.com/zh/tidb/stable/download-ecosystem-tools#dumpling](https://docs.pingcap.com/zh/tidb/stable/download-ecosystem-tools#dumpling)