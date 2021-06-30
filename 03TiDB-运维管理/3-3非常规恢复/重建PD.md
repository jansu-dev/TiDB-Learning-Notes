TiDB 重建PD
<!-- TOC -->

- [场景描述](#场景描述)
- [操作风险](#操作风险)
- [实验环境](#实验环境)
- [TiUP源数据备份](#tiup源数据备份)
- [实验](#实验)
    - [部署集群](#部署集群)
    - [重建PD](#重建pd)
- [总结](#总结)

<!-- /TOC -->


## 场景描述

1. 更换 IP：例如部署的时候使用了动态 IP，集群重启导致 IP 无法找回
2. 更换部署端口
3. 更换部署目录（例如部署时未选择容量较大的磁盘，浪费机器空间）

## 操作风险
因为 PD 换了 IP 或端口之后 TiDB 和 TiKV 会挂，所以上述场景都需停机。
并且涉及 PD 更换 IP /  端口需要销毁 PD 重建，属于高风险操作，
因此在 TiUP 中未直接支持


## 实验环境
为了变更 IP，我们需要有两个 IP 地址的集群，两个 IP 地址分别用 127.0.0.1 和一个内网地址，这里用 IDC 机器 172.16.5.140 来做，在该机器上部署一个 2 db, 3 pd, 3 kv 的单机集群。
步骤
准备 topo 文件
```topology.yml
global:
  user: test
  deploy_dir: /data

tidb_servers:
  - host: 127.0.0.1
    port: 4000
    status_port: 10080
  - host: 127.0.0.1
    port: 4001
    status_port: 10081

pd_servers:
  - host: 127.0.0.1
    port: 2379
    status_port: 2380
  - host: 127.0.0.1
    port: 2389
    status_port: 2390
  - host: 127.0.0.1
    port: 2399
    status_port: 2400

tikv_servers:
  - host: 127.0.0.1
    port: 20160
    status_port: 20180
  - host: 127.0.0.1
    port: 20161
    status_port: 20181
  - host: 127.0.0.1
    port: 20162
    status_port: 20182

monitoring_servers:
  - host: 127.0.0.1

grafana_servers:
  - host: 127.0.0.1

monitored:
    node_exporter_port: 9100
    blackbox_exporter_port: 9115
```

## TiUP源数据备份
```shell
~/.tiup/storage/cluster/clusters/<cluster-name> 目录
~/.tiup/storage/cluster/clusters/<cluster-name>/meta.yaml 中显示的所有数据目录(data_dir)
```

## 实验
背景
在某些特殊的情况下，用户可能想要：
更换 IP：例如部署的时候使用了动态 IP，集群重启导致 IP 无法找回
更换端口
更换目录：例如部署时未选择容量较大的磁盘，浪费机器空间
由于这三种 case 都需要停机（因为 PD 换了 IP 或端口之后 TiDB 和 TiKV 会挂)，并且涉及 PD 更换 IP /  端口需要销毁 PD 重建，属于高风险操作，因此在 TiUP 中未直接支持，仅对内提供此文档以备不时之需。

注意：线上环境操作，必须先备份数据，若操作过程导致数据丢失，则可能再也无法恢复集群，至少需要备份：
中控机的 ~/.tiup/storage/cluster/clusters/<cluster-name> 目录
~/.tiup/storage/cluster/clusters/<cluster-name>/meta.yaml 中显示的所有数据目录(data_dir)

### 部署集群
```
tiup cluster deploy test v4.0.0 ~/topology.yml
```
由于是单机部署，执行此命令前需要调整  /etc/ssh/sshd_config 中的 MaxSessions 和 MaxStartups 至一个较大的值，然后执行 systemctl reload sshd.service
启动集群并插入数据
启动集群的命令：
```
tiup cluster start test
```
插入数据是为了验证迁移之后是否会导致数据丢失，随意插入一些数据即可，可以用 tiup bench:
```
tiup bench tpcc --warehouses 4 --parts 4 prepare
```
它会向本机的 4000 端口插入数据。
修改 IP 地址
目前我们部署使用的是 127.0.0.1：
先停止集群：
```
tiup cluster stop test
```
然后修改 meta.yaml：
通过编辑 ~/.tiup/storage/cluster/clusters/test/meta.yaml 来修改它为内网地址 172.16.5.140:

### 重建PD
由于 PD 会将 IP 和端口信息持久化到 etcd 中，改不了，我们模拟极端情况非改不可，所以
参考 PD Recover 文档， 主动销毁 PD 重建：
首先到 tidb 的日志目录里找到 cluster id:
```
[root@localhost data]# cat /data/pd-*/log/pd.log | grep "init cluster id" | head -10
[2020/08/18 16:27:28.661 +08:00] [INFO] [server.go:336] ["init cluster id"] [cluster-id=6862237818241127771]
[2020/08/18 16:43:24.156 +08:00] [INFO] [server.go:336] ["init cluster id"] [cluster-id=6862237818241127771]
[2020/08/18 16:27:28.660 +08:00] [INFO] [server.go:336] ["init cluster id"] [cluster-id=6862237818241127771]
[2020/08/18 16:43:27.098 +08:00] [INFO] [server.go:336] ["init cluster id"] [cluster-id=6862237818241127771]
[2020/08/18 16:27:28.659 +08:00] [INFO] [server.go:336] ["init cluster id"] [cluster-id=6862237818241127771]
```
然后找到 allocates id：
```
[root@localhost data]# cat /data/pd-*/log/pd* | grep "allocates" | head -10
[2020/08/18 16:27:33.083 +08:00] [INFO] [id.go:110] ["idAllocator allocates a new id"] [alloc-id=1000]
```
将老的 PD 数据目录移走（可以删掉，但是安全起见用 mv)
```
cd /data/pd-2379
mkdir data-backup
mv data/* data-backup/

cd /data/pd-2389
mkdir data-backup
mv data/* data-backup/

cd /data/pd-2399
mkdir data-backup
mv data/* data-backup/
```
Reload PD：
```
tiup cluster reload test -R pd --force
```
执行 pd-recover:
···
tiup pd-recover -endpoints http://172.16.5.140:2379 -cluster-id 6862237818241127771 -alloc-id 1001
···
Reload 集群
```
tiup cluster reload test
```
然后验证一下数据是不是还正常：


修改端口
停止集群：
```
tiup cluster stop test
```
修改 meta.yaml：
修改端口和修改 IP 地址步骤基本相同，先修改 ~/.tiup/storage/cluster/clusters/test/meta.yaml，把所有的端口都改一遍（但是不改目录上的端口，目录下一节改）：

重建 PD:
参考 PD Recover 文档， 找到 cluster id 和 allocates id:
cluster id:
```
[root@localhost data]# cat /data/pd-*/log/pd.log | grep "init cluster id" | head -10
[2020/08/18 16:27:28.661 +08:00] [INFO] [server.go:336] ["init cluster id"] [cluster-id=6862237818241127771]
[2020/08/18 16:43:24.156 +08:00] [INFO] [server.go:336] ["init cluster id"] [cluster-id=6862237818241127771]
[2020/08/18 17:17:16.381 +08:00] [INFO] [server.go:336] ["init cluster id"] [cluster-id=6862250655043446671]
[2020/08/18 17:20:00.075 +08:00] [INFO] [server.go:336] ["init cluster id"] [cluster-id=6862237818241127771]
[2020/08/18 17:20:37.488 +08:00] [INFO] [server.go:336] ["init cluster id"] [cluster-id=6862237818241127771]
[2020/08/18 16:27:28.660 +08:00] [INFO] [server.go:336] ["init cluster id"] [cluster-id=6862237818241127771]
[2020/08/18 16:43:27.098 +08:00] [INFO] [server.go:336] ["init cluster id"] [cluster-id=6862237818241127771]
[2020/08/18 17:17:16.382 +08:00] [INFO] [server.go:336] ["init cluster id"] [cluster-id=6862250655043446671]
[2020/08/18 17:20:00.078 +08:00] [INFO] [server.go:336] ["init cluster id"] [cluster-id=6862237818241127771]
[2020/08/18 17:20:37.508 +08:00] [INFO] [server.go:336] ["init cluster id"] [cluster-id=6862237818241127771]
```
allocates id:
```
[root@localhost data]# cat /data/pd-*/log/pd* | grep "allocates" | head -10
[2020/08/18 16:27:33.083 +08:00] [INFO] [id.go:110] ["idAllocator allocates a new id"] [alloc-id=1000]
```
将老的 PD 数据目录移走（可以删掉，但是安全起见用 mv)
```
cd /data/pd-2379
mkdir data-backup2
mv data/* data-backup2/

cd /data/pd-2389
mkdir data-backup2
mv data/* data-backup2/

cd /data/pd-2399
mkdir data-backup2
mv data/* data-backup2/
```
执行 pd-recover:
···
tiup pd-recover -endpoints http://172.16.5.140:2699 -cluster-id 6862237818241127771 -alloc-id 1001    # 这里用 2699 是因为我们改了 pd 的端口
···
Reload 集群
```
tiup cluster reload test
```
然后验证一下数据是不是还正常：



修改目录
TiUP 的默认部署目录上会有端口号，在上面修改端口的时候没有去修改他（实际上不修改也没问题），但是为了让它看起来更加正确，还是把它更正过来（涉及目录移动的场景操作也一样）。
首先还是停止集群：
```
tiup cluster stop test
```
然后编辑  ~/.tiup/storage/cluster/clusters/test/meta.yaml:

编辑完之后需要把目录移动到正确的位置，比如上面需要：
```
mv /data/monitor-9100 /data/monitor-9200
```
为了防止疏忽漏掉 mv 目录的操作，推荐开两个窗口一个编辑 meta 一个同时 mv 目录。移动的时候注意文件权限。
删除 tikv 的数据目录中的 last_tikv.toml：
last_tikv.toml 中会记录 tikv 上一次的启动参数，tikv 启动后会检查哪些参数修改了，然后 tikv 是不允许修改数据目录的，所以要把这个文件删掉，“欺骗” tikv：
```
rm /data/tikv-*/data/last_tikv.toml
```
然后重新启动集群：
```
tiup cluster reload test -R pd --force
tiup cluster reload test
```
检查数据是否正确：


## 总结
在极端情况下修改  IP， 端口和目录是可行的
这三种操作互相独立，可单独执行
这三种操作均需要停机，并且要在修改 meta.yaml 之前停机（否则修改了端口之后 tiup 就没法停止之前的进程了）
这三种操作均有丢失数据的风险，用户线上操作建议在 DBA 指导下进行
