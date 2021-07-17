





```log
[2021/06/15 22:26:33.176 +08:00] [INFO] [conn.go:800] ["command dispatched failed"] [conn=12438] [connInfo="id:12438, addr:9.1.200.60:56644 status:10, collation
:utf8_general_ci, user:uasuser"] [command=Query] [status="inTxn:0, autocommit:1"] [sql="load data local infile \"/data/shfile/zip/15000205_4100#20210520114016.DAT\" into table risk_factor FIELDS TERMINATED BY '||' LINES TERMINATED BY '\\n'\n(@`POLNO`,\n@`SALESMANNO`,

[txn_mode=PESSIMISTIC] [err="[kv:8022]Error: KV error safe to retry Txn(Mvcc(TxnLockNotFound { start_ts: T
imeStamp(425660812453478401), commit_ts: TimeStamp(425660819649331201), key: [116, 128, 0, 0, 0, 0, 0, 23, 63, 95, 105, 128, 0, 0, 0, 0, 0, 0, 1, 3, 128, 0, 0, 
0, 2, 69, 237, 58, 1, 57, 57, 0, 0, 0, 0, 0, 0, 249] })) {tableID=5951, indexID=1, indexValues={38137146, 99, }} [try again later]
```

```shell
[tidb@b102-policycenter-200-60 ~]$ tiup ctl:v4.0.13 pd tso 425660812453478401
Starting component `ctl`: /home/tidb/.tiup/components/ctl/v4.0.13/ctl pd tso 425660812453478401
system:  2021-06-15 22:25:37.35 +0800 CST
logic:  1
[tidb@b102-policycenter-200-60 ~]$ tiup ctl:v4.0.13 pd tso 425660819649331201
Starting component `ctl`: /home/tidb/.tiup/components/ctl/v4.0.13/ctl pd tso 425660819649331201
system:  2021-06-15 22:26:04.8 +0800 CST
logic:  1

```