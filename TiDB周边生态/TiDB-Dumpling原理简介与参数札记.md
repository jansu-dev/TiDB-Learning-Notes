# TiDB-Dumpling原理简介与参数札记


## summary
> [原理讲解](#原理讲解)
> [部署方式](#部署方式)
> [参数简介](#参数简介)


## 原理讲解





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



## 参考文章

[TiDB官网-工具下载：https://docs.pingcap.com/zh/tidb/stable/download-ecosystem-tools#dumpling](https://docs.pingcap.com/zh/tidb/stable/download-ecosystem-tools#dumpling)