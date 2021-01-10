# TiDB-TiUP工具集群滚动升级

> [获取升级版本镜像包](#获取升级版本镜像包)  
> [升级前环境检查](#升级前环境检查)  
> [将集群升级到指定版本](#将集群升级到指定版本)  
> [TiUP工具滚动升级](#TiUP工具滚动升级)  
> [验证集群升级](#验证集群升级)  
> [常见问题解决方案](#常见问题解决方案)



## 获取升级版本镜像包

方式一：[**TiDB社区版获取方式：https://pingcap.com/download-cn/community/**](https://pingcap.com/download-cn/community/)

方式二：联网TiUP服务器打包scp
```
[tidb@tiup-tidb44 ~]$ tiup mirror clone tidb-community-server-v4.0.9-linux-amd64 v4.0.9 --os=linux --arch=amd64
Start to clone mirror, targetDir is tidb-community-server-v4.0.9-linux-amd64, selectedVersions are [v4.0.9]
If this does not meet expectations, please abort this process, read `tiup mirror clone --help` and run again
Arch [amd64]
OS [linux]
download https://tiup-mirrors.pingcap.com/alertmanager-v0.17.0-linux-amd64.tar.gz 22.54 MiB / 22.54 MiB 100.00% 5.48 MiB p/s                                                                                                
......
......                                          
download https://tiup-mirrors.pingcap.com/tiup-linux-amd64.tar.gz 8.49 MiB / 8.49 MiB 100.00% 12.42 MiB p/s 

[tidb@tiup-tidb44 ~]$ scp tidb-community-server-v4.0.9-linux-amd64.tar.gz 192.168.169.41:/home/tidb/
tidb@192.168.169.41's password: 
tidb-community-server-v4.0.9-linux-amd64.tar.gz                                                                                                                                 100% 1498MB  82.2MB/s   00:18    


[tidb@tiup-tidb41 ~]$ tar -zxvf tidb-community-server-v4.0.9-linux-amd64.tar.gz 
tidb-community-server-v4.0.9-linux-amd64/
......
......
tidb-community-server-v4.0.9-linux-amd64/local_install.sh

[tidb@tiup-tidb41 ~]$ ll
total 3101252
drwxr-xr-x. 3 tidb tidb       4096 Jan  9 01:40 tidb-community-server-v4.0.2-linux-amd64
-rw-rw-r--. 1 tidb tidb 1604720640 Jan  9 00:30 tidb-community-server-v4.0.2-linux-amd64.tar.gz
drwxr-xr-x. 3 tidb tidb       4096 Jan  9 02:44 tidb-community-server-v4.0.9-linux-amd64
-rw-rw-r--. 1 tidb tidb 1570949987 Jan  9 02:48 tidb-community-server-v4.0.9-linux-amd64.tar.gz

[tidb@tiup-tidb41 ~]$ cd tidb-community-server-v4.0.9-linux-amd64

[tidb@tiup-tidb41 tidb-community-server-v4.0.9-linux-amd64]$ ./local_install.sh 
Set mirror to /home/tidb/tidb-community-server-v4.0.9-linux-amd64 success
Detected shell: bash
Shell profile:  /home/tidb/.bash_profile
Installed path: /home/tidb/.tiup/bin/tiup
===============================================
1. source /home/tidb/.bash_profile
2. Have a try:   tiup playground
===============================================

[tidb@tiup-tidb41 tidb-community-server-v4.0.9-linux-amd64]$ source /home/tidb/.bash_profile


```

## 升级前环境检查

 - 注意：在升级的过程中不要执行 DDL 请求，否则可能会出现行为未定义的问题

```
MySQL [INFORMATION_SCHEMA]> select * from INFORMATION_SCHEMA.processlist;
+----+------+----------------+--------------------+---------+------+-------+----------------------------------------------+------+----------+
| ID | USER | HOST           | DB                 | COMMAND | TIME | STATE | INFO                                         | MEM  | TxnStart |
+----+------+----------------+--------------------+---------+------+-------+----------------------------------------------+------+----------+
|  2 | root | 192.168.169.41 | INFORMATION_SCHEMA | Query   |    0 | 2     | select * from INFORMATION_SCHEMA.processlist |    0 |          |
+----+------+----------------+--------------------+---------+------+-------+----------------------------------------------+------+----------+
1 row in set (0.00 sec)

```


## 将集群升级到指定版本

升级前版本查看

```
[tidb@tiup-tidb41 ~]$ tiup cluster display tidb-test 
Starting component `cluster`: /home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster display tidb-test
Cluster type:       tidb
Cluster name:       tidb-test
Cluster version:    v4.0.2
SSH type:           builtin
Dashboard URL:      http://192.168.169.42:2379/dashboard

......
......
```

## TiUP工具滚动升级

```
[tidb@tiup-tidb41 tidb-community-server-v4.0.9-linux-amd64]$ tiup cluster upgrade tidb-test v4.0.9
Starting component `cluster`: /home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster upgrade tidb-test v4.0.9
This operation will upgrade tidb v4.0.2 cluster tidb-test to v4.0.9.
Do you want to continue? [y/N]: y

Upgrading cluster...
+ [ Serial ] - SSHKeySet: privateKey=/home/tidb/.tiup/storage/cluster/clusters/tidb-test/ssh/id_rsa, publicKey=/home/tidb/.tiup/storage/cluster/clusters/tidb-test/ssh/id_rsa.pub
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.42
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.41

......
......

Upgraded cluster `tidb-test` successfully
```

## 验证集群升级

观察到Cluster version已经变更为了v4.0.9

```
[tidb@tiup-tidb41 tidb-community-server-v4.0.9-linux-amd64]$ tiup cluster display tidb-test
Starting component `cluster`: /home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster display tidb-test
Cluster type:       tidb
Cluster name:       tidb-test
Cluster version:    v4.0.9
SSH type:           builtin
Dashboard URL:      http://192.168.169.42:2379/dashboard
ID                    Role          Host            Ports                            OS/Arch       Status   Data Dir                                 Deploy Dir
--                    ----          ----            -----                            -------       ------   --------                                 ----------
192.168.169.42:9093   alertmanager  192.168.169.42  9093/9094                        linux/x86_64  Up       /data/tidb-data/alertmanager-9093        /data/tidb-deploy/alertmanager-9093
192.168.169.41:8300   cdc           192.168.169.41  8300                             linux/x86_64  Up       -                                        /data/tidb-deploy/cdc-8300
192.168.169.42:8300   cdc           192.168.169.42  8300                             linux/x86_64  Up       -                                        /data/tidb-deploy/cdc-8300
192.168.169.43:8300   cdc           192.168.169.43  8300                             linux/x86_64  Up       -                                        /data/tidb-deploy/cdc-8300
192.168.169.42:3000   grafana       192.168.169.42  3000                             linux/x86_64  Up       -                                        /data/tidb-deploy/grafana-3000
192.168.169.41:2379   pd            192.168.169.41  2379/2380                        linux/x86_64  Up       /data/tidb-data/pd-2379                  /data/tidb-deploy/pd-2379
192.168.169.42:2379   pd            192.168.169.42  2379/2380                        linux/x86_64  Up|L|UI  /data/tidb-data/pd-2379                  /data/tidb-deploy/pd-2379
192.168.169.43:2379   pd            192.168.169.43  2379/2380                        linux/x86_64  Up       /data/tidb-data/pd-2379                  /data/tidb-deploy/pd-2379
192.168.169.42:9090   prometheus    192.168.169.42  9090                             linux/x86_64  Up       /data/tidb-data/prometheus-9090          /data/tidb-deploy/prometheus-9090
192.168.169.41:4000   tidb          192.168.169.41  4000/10080                       linux/x86_64  Up       -                                        /data/tidb-deploy/tidb-4000
192.168.169.42:4000   tidb          192.168.169.42  4000/10080                       linux/x86_64  Up       -                                        /data/tidb-deploy/tidb-4000
192.168.169.43:4000   tidb          192.168.169.43  4000/10080                       linux/x86_64  Up       -                                        /data/tidb-deploy/tidb-4000
192.168.169.44:9000   tiflash       192.168.169.44  9000/8123/3930/20170/20292/8234  linux/x86_64  Up       /data/tiflash1/data,/data/tiflash2/data  /data/tidb-deploy/tiflash-9000
192.168.169.41:20160  tikv          192.168.169.41  20160/20180                      linux/x86_64  Up       /data/tidb-data/tikv-20160               /data/tidb-deploy/tikv-20160
192.168.169.42:20160  tikv          192.168.169.42  20160/20180                      linux/x86_64  Up       /data/tidb-data/tikv-20160               /data/tidb-deploy/tikv-20160
192.168.169.43:20160  tikv          192.168.169.43  20160/20180                      linux/x86_64  Up       /data/tidb-data/tikv-20160               /data/tidb-deploy/tikv-20160
Total nodes: 16
```

## 常见问题解决方案

 - v4.0.9版本升级时出现Run Command Timeout错误解决
```
[tidb@tiup-tidb41 tidb-community-server-v4.0.9-linux-amd64]$ tiup cluster upgrade tidb-test v4.0.9
Starting component `cluster`: /home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster upgrade tidb-test v4.0.9
This operation will upgrade tidb v4.0.2 cluster tidb-test to v4.0.9.
Do you want to continue? [y/N]: y
Upgrading cluster...
......
......
+ [ Serial ] - InitConfig: cluster=tidb-test, user=tidb, host=192.168.169.42, path=/home/tidb/.tiup/storage/cluster/clusters/tidb-test/config-cache/tikv-20160.service, deploy_dir=/data/tidb-deploy/tikv-20160, data_dir=[/data/tidb-data/tikv-20160], log_dir=/data/tidb-deploy/tikv-20160/log, cache_dir=/home/tidb/.tiup/storage/cluster/clusters/tidb-test/config-cache

Error: stderr: Run Command Timeout!
: executor.ssh.execute_timedout: Execute command over SSH timedout for 'tidb@192.168.169.44:22' {ssh_stderr: Run Command Timeout!
, ssh_stdout: , ssh_command: export LANG=C; PATH=$PATH:/usr/bin:/usr/sbin tar --no-same-owner -zxf /data/tidb-deploy/tiflash-9000/bin/tiflash-v4.0.9-linux-amd64.tar.gz -C /data/tidb-deploy/tiflash-9000/bin && rm /data/tidb-deploy/tiflash-9000/bin/tiflash-v4.0.9-linux-amd64.tar.gz}

Verbose debug logs has been written to /home/tidb/.tiup/logs/tiup-cluster-debug-2021-01-10-01-04-18.log.
Error: run `/home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster` (wd:/home/tidb/.tiup/data/SLfUqGv) failed: exit status 1
```
通过指定wait-timeout参数增大SSH Command的执行时间
```
[tidb@tiup-tidb41 tidb-community-server-v4.0.9-linux-amd64]$ tiup cluster upgrade tidb-test v4.0.9 --ssh-timeout 100000000 --wait-timeout 100000000
Starting component `cluster`: /home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster upgrade tidb-test v4.0.9 --wait-timeout 100000000
This operation will upgrade tidb v4.0.2 cluster tidb-test to v4.0.9.
Do you want to continue? [y/N]: y
Upgrading cluster...
+ [ Serial ] - SSHKeySet: privateKey=/home/tidb/.tiup/storage/cluster/clusters/tidb-test/ssh/id_rsa, publicKey=/home/tidb/.tiup/storage/cluster/clusters/tidb-test/ssh/id_rsa.pub
......
......
Upgraded custer `tidb-test` successfully



[tidb@tiup-tidb41 tidb-community-server-v4.0.9-linux-amd64]$ tiup cluster display tidb-test
Starting component `cluster`: /home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster display tidb-test
Cluster type:       tidb
Cluster name:       tidb-test
Cluster version:    v4.0.9
SSH type:           builtin
Dashboard URL:      http://192.168.169.41:2379/dashboard
......
......
```