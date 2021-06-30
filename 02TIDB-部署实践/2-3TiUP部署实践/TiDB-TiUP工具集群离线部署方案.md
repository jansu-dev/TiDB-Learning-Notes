# TiDB-TiUP工具集群离线部署方案
时间：2020-12-25

> - [下载TiUP离线组件](#下载TiUP离线组件)  
> - [TiKV数据盘挂载](#下载TiUP离线组件)  
> - [配置topology配置文件](#配置topology配置文件)  
> - [部署TiDB集群](#部署TiDB集群)  
> - [检查集群状态](#检查集群状态)  
> - [TiUP卸载集群](#TiUP卸载集群)  
> - [常见错误解决](#常见错误解决)  

> **IP规划**

| IP地址 | Role信息 | 备注 |
|-|-|-|
| 192.168.169.41 | pd+tikv+tidb+cdc | 部署TiUP主机 |
| 192.168.169.42 | pd+tikv+tidb+cdc+prometheus+grafana+alertmanager |  |
| 192.168.169.43 | pd+tikv+tidb+cdc |  |
| 192.168.169.44 | tiflash |  |



## 下载TiUP离线组件

```
[root@tiup-tidb41 ~]# useradd tidb

[root@tiup-tidb41 ~]# passwd tidb

[root@tidb-tidb41 ~]# visudo

[root@tidb-tidb41 ~]# tail -1 /etc/sudoers
tidb ALL=(ALL) NOPASSWD: ALL

[root@tiup-tidb41 ~]# su - tidb

[tidb@tiup-tidb44 ~]$ curl --proto '=https' --tlsv1.2 -sSf https://tiup-mirrors.pingcap.com/install.sh | sh
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
 23 8697k   23 2015k    0     0   303k      0  0:00:28  0:00:06  0:00:22  417k
```

```shell
# ${version} 替换为需要下载的版本名称，如：v4.0.2、v5.0.0-rc等
[tidb@tiup-tidb44 ~]$ tiup mirror clone tidb-community-server-${version}-linux-amd64 ${version} --os=linux --arch=amd64

Start to clone mirror, targetDir is tidb-community-server-v4.0.2-linux-amd64, selectedVersions are []
If this does not meet expectations, please abort this process, read `tiup mirror clone --help` and run again
Arch [amd64]
OS [linux]
......
......
download https://tiup-mirrors.pingcap.com/tiup-linux-amd64.tar.gz 8.49 MiB / 8.49 MiB 100.00% 806.71 KiB p/s

[tidb@tiup-tidb44 ~]$ ll
total 0
drwxr-xr-x. 3 tidb tidb 172 Jan  9 11:40 tidb-community-server-v4.0.2-linux-amd64

[tidb@tiup-tidb44 ~]$ cd tidb-community-server-v4.0.2-linux-amd64/

[tidb@tiup-tidb44 tidb-community-server-v4.0.2-linux-amd64]$ ll

[tidb@tiup-tidb44 tidb-community-server-v4.0.2-linux-amd64]$ ./local_install.sh 

[tidb@tiup-tidb44 ~]$ tar -cvf tidb-community-server-v4.0.2-linux-amd64.tar.gz tidb-community-server-v4.0.2-linux-amd64

[tidb@tiup-tidb44 ~]$ ll -lrth
total 1.5G
drwxr-xr-x. 3 tidb tidb 4.0K Jan  9 00:26 tidb-community-server-v4.0.2-linux-amd64
-rw-rw-r--. 1 tidb tidb 1.5G Jan  9 00:28 tidb-community-server-v4.0.2-linux-amd64.tar.gz

[tidb@tiup-tidb44 ~]$ scp tidb-community-server-v4.0.2-linux-amd64.tar.gz 192.168.169.41:/home/tidb/
Warning: Permanently added '192.168.169.41' (ECDSA) to the list of known hosts.
tidb@192.168.169.41's password: 
tidb-community-server-v4.0.2-linux-amd64.tar.gz                                                                                                                                  56%  869MB 129.1MB/s   00:05 ETA

[tidb@tiup-tidb41 ~]$ tar -xvf tidb-community-server-v4.0.2-linux-amd64.tar.gz 
tidb-community-server-v4.0.2-linux-amd64/
......
......
tidb-community-server-v4.0.2-linux-amd64/local_install.sh

[tidb@tiup-tidb41 ~]$ ll -lrth
total 1.5G
drwxr-xr-x. 3 tidb tidb 4.0K Jan  9 00:26 tidb-community-server-v4.0.2-linux-amd64
-rw-rw-r--. 1 tidb tidb 1.5G Jan  9 00:30 tidb-community-server-v4.0.2-linux-amd64.tar.gz
```

安装组件
```
[tidb@tiup-tidb41 ~]$ cd tidb-community-server-v4.0.2-linux-amd64

[tidb@tiup-tidb41 tidb-community-server-v4.0.2-linux-amd64]$ ll |grep install
-rwxr-xr-x. 1 tidb tidb      2086 Jan  9 00:26 local_install.sh

[tidb@tiup-tidb41 tidb-community-server-v4.0.2-linux-amd64]$ sh local_install.sh 
Set mirror to /home/tidb/tidb-community-server-v4.0.2-linux-amd64 success
Detected shell: bash
Shell profile:  /home/tidb/.bash_profile
/home/tidb/.bash_profile has been modified to to add tiup to PATH
open a new terminal or source /home/tidb/.bash_profile to use it
Installed path: /home/tidb/.tiup/bin/tiup
===============================================
1. source /home/tidb/.bash_profile
2. Have a try:   tiup playground
===============================================

[tidb@tiup-tidb41 tidb-community-server-v4.0.2-linux-amd64]$ source /home/tidb/.bash_profile
```

## TiKV数据盘挂载

修改HHD的磁盘
```
[root@tiup-tidb41 ~]# fdisk -l

Disk /dev/sda: 107.4 GB, 107374182400 bytes, 209715200 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x000a1f1f

   Device Boot      Start         End      Blocks   Id  System
/dev/sda1   *        2048      391167      194560   83  Linux
/dev/sda2          391168   199628799    99618816   8e  Linux LVM

Disk /dev/sdb: 107.4 GB, 107374182400 bytes, 209715200 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/mapper/centos-root: 102.0 GB, 102001278976 bytes, 199221248 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes

[root@tiup-tidb41 ~]# parted -s -a optimal /dev/sdb mklabel gpt -- mkpart primary ext4 1 -1
[root@tiup-tidb41 ~]# ll /dev/sd*
brw-rw----. 1 root disk 8,  0 Jan  8 23:29 /dev/sda
brw-rw----. 1 root disk 8,  1 Jan  8 23:29 /dev/sda1
brw-rw----. 1 root disk 8,  2 Jan  8 23:29 /dev/sda2
brw-rw----. 1 root disk 8, 16 Jan  8 23:46 /dev/sdb
brw-rw----. 1 root disk 8, 17 Jan  8 23:46 /dev/sdb1

[root@tiup-tidb41 ~]# mkfs.ext4 /dev/sdb1 
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
6553600 inodes, 26213888 blocks
1310694 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=2174746624
800 block groups
32768 blocks per group, 32768 fragments per group
8192 inodes per group
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208, 
	4096000, 7962624, 11239424, 20480000, 23887872

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (32768 blocks): done
Writing superblocks and filesystem accounting information: done   

[root@tiup-tidb41 ~]# lsblk -f
NAME            FSTYPE      LABEL UUID                                   MOUNTPOINT
sda                                                                      
├─sda1          xfs               f5186353-9452-4395-9549-0e0f05401910   /boot
└─sda2          LVM2_member       QjWT3C-PmGV-bIBK-kjxs-zGGE-xnLB-Kqyewx 
  └─centos-root xfs               1c8f5bee-8e88-44d7-99c0-c5d8b1d621bb   /
sdb                                                                      
└─sdb1          ext4              003d05ff-6e97-49ec-abf4-b86be07754b8   
sr0                                                                      

[root@tiup-tidb41 ~]# vi /etc/fstab 

[root@tiup-tidb41 ~]# tail -1 /etc/fstab 
UUID=003d05ff-6e97-49ec-abf4-b86be07754b8 /data ext4    defaults,nodelalloc,noatime       0 2

[root@tiup-tidb41 ~]# mkdir /data

[root@tiup-tidb41 ~]# mount -a

[root@tiup-tidb41 ~]# mount -t ext4
/dev/sdb1 on /data type ext4 (rw,noatime,seclabel,nodelalloc,data=ordered)

```

## 配置topology配置文件
```
[tidb@tiup-tidb41 tidb-community-server-v4.0.2-linux-amd64]$ vi topology.yaml

[tidb@tiup-tidb41 tidb-community-server-v4.0.2-linux-amd64]$ cat topology.yaml
# # Global variables are applied to all deployments and used as the default value of
# # the deployments if a specific deployment value is missing.
global:
  user: "tidb"
  ssh_port: 22
  deploy_dir: "/data/tidb-deploy"
  data_dir: "/data/tidb-data"

server_configs:
  pd:
    replication.enable-placement-rules: true

pd_servers:
  - host: 192.168.169.41
  - host: 192.168.169.42
  - host: 192.168.169.43
tidb_servers:
  - host: 192.168.169.41
  - host: 192.168.169.42
  - host: 192.168.169.43
tikv_servers:
  - host: 192.168.169.41
  - host: 192.168.169.42
  - host: 192.168.169.43
tiflash_servers:
  - host: 192.168.169.43
    data_dir: /data/tiflash1/data,/data/tiflash2/data
cdc_servers:
  - host: 192.168.169.41
  - host: 192.168.169.42
  - host: 192.168.169.43
monitoring_servers:
  - host: 192.168.169.42
grafana_servers:
  - host: 192.168.169.42
alertmanager_servers:
  - host: 192.168.169.42
```


## 部署TiDB集群
```
[tidb@tiup-tidb41 tidb-community-server-v4.0.2-linux-amd64]$ pwd
/home/tidb/tidb-community-server-v4.0.2-linux-amd64

[tidb@tiup-tidb41 tidb-community-server-v4.0.2-linux-amd64]$ export TIUP_MIRRORS=/home/tidb/tidb-community-server-v4.0.2-linux-amd64

[tidb@tiup-tidb41 tidb-community-server-v4.0.2-linux-amd64]$ tiup cluster deploy tidb-test v4.0.2 topology.yaml --user root -p 
Starting component `cluster`: /home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster deploy tidb-test v4.0.2 topology.yaml --user root -p
Please confirm your topology:
Cluster type:    tidb
Cluster name:    tidb-test
Cluster version: v4.0.2
Type          Host            Ports                            OS/Arch       Directories
----          ----            -----                            -------       -----------
pd            192.168.169.41  2379/2380                        linux/x86_64  /data/tidb-deploy/pd-2379,/data/tidb-data/pd-2379
pd            192.168.169.42  2379/2380                        linux/x86_64  /data/tidb-deploy/pd-2379,/data/tidb-data/pd-2379
pd            192.168.169.43  2379/2380                        linux/x86_64  /data/tidb-deploy/pd-2379,/data/tidb-data/pd-2379
tikv          192.168.169.41  20160/20180                      linux/x86_64  /data/tidb-deploy/tikv-20160,/data/tidb-data/tikv-20160
tikv          192.168.169.42  20160/20180                      linux/x86_64  /data/tidb-deploy/tikv-20160,/data/tidb-data/tikv-20160
tikv          192.168.169.43  20160/20180                      linux/x86_64  /data/tidb-deploy/tikv-20160,/data/tidb-data/tikv-20160
tidb          192.168.169.41  4000/10080                       linux/x86_64  /data/tidb-deploy/tidb-4000
tidb          192.168.169.42  4000/10080                       linux/x86_64  /data/tidb-deploy/tidb-4000
tidb          192.168.169.43  4000/10080                       linux/x86_64  /data/tidb-deploy/tidb-4000
tiflash       192.168.169.43  9000/8123/3930/20170/20292/8234  linux/x86_64  /data/tidb-deploy/tiflash-9000,/data/tiflash1/data,/data/tiflash2/data
cdc           192.168.169.41  8300                             linux/x86_64  /data/tidb-deploy/cdc-8300
cdc           192.168.169.42  8300                             linux/x86_64  /data/tidb-deploy/cdc-8300
cdc           192.168.169.43  8300                             linux/x86_64  /data/tidb-deploy/cdc-8300
prometheus    192.168.169.42  9090                             linux/x86_64  /data/tidb-deploy/prometheus-9090,/data/tidb-data/prometheus-9090
grafana       192.168.169.42  3000                             linux/x86_64  /data/tidb-deploy/grafana-3000
alertmanager  192.168.169.42  9093/9094                        linux/x86_64  /data/tidb-deploy/alertmanager-9093,/data/tidb-data/alertmanager-9093
Attention:
    1. If the topology is not what you expected, check your yaml file.
    2. Please confirm there is no port/directory conflicts in same host.
Do you want to continue? [y/N]:  y
Input SSH password: 
+ Generate SSH keys ... Done
+ Download TiDB components
  - Download pd:v4.0.2 (linux/amd64) ... Done
  - Download tikv:v4.0.2 (linux/amd64) ... Done
  - Download tidb:v4.0.2 (linux/amd64) ... Done
  - Download tiflash:v4.0.2 (linux/amd64) ... Done
  - Download cdc:v4.0.2 (linux/amd64) ... Done
  - Download prometheus:v4.0.2 (linux/amd64) ... Done
  - Download grafana:v4.0.2 (linux/amd64) ... Done
  - Download alertmanager:v0.17.0 (linux/amd64) ... Done
  - Download node_exporter:v0.17.0 (linux/amd64) ... Done
  - Download blackbox_exporter:v0.12.0 (linux/amd64) ... Done
+ Initialize target host environments
  - Prepare 192.168.169.41:22 ... Done
  - Prepare 192.168.169.42:22 ... Done
  - Prepare 192.168.169.43:22 ... Done
+ Copy files
  - Copy pd -> 192.168.169.41 ... Done
  - Copy pd -> 192.168.169.42 ... Done
  - Copy pd -> 192.168.169.43 ... Done
  - Copy tikv -> 192.168.169.41 ... Done
  - Copy tikv -> 192.168.169.42 ... Done
  - Copy tikv -> 192.168.169.43 ... Done
  - Copy tidb -> 192.168.169.41 ... Done
  - Copy tidb -> 192.168.169.42 ... Done
  - Copy tidb -> 192.168.169.43 ... Done
  - Copy tiflash -> 192.168.169.43 ... Done
  - Copy cdc -> 192.168.169.41 ... Done
  - Copy cdc -> 192.168.169.42 ... Done
  - Copy cdc -> 192.168.169.43 ... Done
  - Copy prometheus -> 192.168.169.42 ... Done
  - Copy grafana -> 192.168.169.42 ... Done
  - Copy alertmanager -> 192.168.169.42 ... Done
  - Copy node_exporter -> 192.168.169.41 ... Done
  - Copy node_exporter -> 192.168.169.42 ... Done
  - Copy node_exporter -> 192.168.169.43 ... Done
  - Copy blackbox_exporter -> 192.168.169.42 ... Done
  - Copy blackbox_exporter -> 192.168.169.43 ... Done
  - Copy blackbox_exporter -> 192.168.169.41 ... Done
+ Check status
Enabling component pd
	Enabling instance pd 192.168.169.43:2379
	Enabling instance pd 192.168.169.41:2379
	Enabling instance pd 192.168.169.42:2379
	Enable pd 192.168.169.42:2379 success
	Enable pd 192.168.169.43:2379 success
	Enable pd 192.168.169.41:2379 success
Enabling component node_exporter
Enabling component blackbox_exporter
Enabling component node_exporter
Enabling component blackbox_exporter
Enabling component node_exporter
Enabling component blackbox_exporter
Enabling component tikv
	Enabling instance tikv 192.168.169.43:20160
	Enabling instance tikv 192.168.169.41:20160
	Enabling instance tikv 192.168.169.42:20160
	Enable tikv 192.168.169.42:20160 success
	Enable tikv 192.168.169.43:20160 success
	Enable tikv 192.168.169.41:20160 success
Enabling component tidb
	Enabling instance tidb 192.168.169.43:4000
	Enabling instance tidb 192.168.169.41:4000
	Enabling instance tidb 192.168.169.42:4000
	Enable tidb 192.168.169.43:4000 success
	Enable tidb 192.168.169.42:4000 success
	Enable tidb 192.168.169.41:4000 success
Enabling component tiflash
	Enabling instance tiflash 192.168.169.43:9000
	Enable tiflash 192.168.169.43:9000 success
Enabling component cdc
	Enabling instance cdc 192.168.169.43:8300
	Enabling instance cdc 192.168.169.41:8300
	Enabling instance cdc 192.168.169.42:8300
	Enable cdc 192.168.169.43:8300 success
	Enable cdc 192.168.169.42:8300 success
	Enable cdc 192.168.169.41:8300 success
Enabling component prometheus
	Enabling instance prometheus 192.168.169.42:9090
	Enable prometheus 192.168.169.42:9090 success
Enabling component grafana
	Enabling instance grafana 192.168.169.42:3000
	Enable grafana 192.168.169.42:3000 success
Enabling component alertmanager
	Enabling instance alertmanager 192.168.169.42:9093
	Enable alertmanager 192.168.169.42:9093 success
Cluster `tidb-test` deployed successfully, you can start it with command: `tiup cluster start tidb-test`
```

## 启动TiDB集群
```
[tidb@tiup-tidb41 tidb-community-server-v4.0.2-linux-amd64]$ tiup cluster start tidb-test
Starting component `cluster`: /home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster start tidb-test
Starting cluster tidb-test...
+ [ Serial ] - SSHKeySet: privateKey=/home/tidb/.tiup/storage/cluster/clusters/tidb-test/ssh/id_rsa, publicKey=/home/tidb/.tiup/storage/cluster/clusters/tidb-test/ssh/id_rsa.pub
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.42
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.41
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.42
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.43
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.41
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.42
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.43
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.41
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.42
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.41
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.42
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.43
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.43
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.43
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.42
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.42
+ [ Serial ] - StartCluster
Starting component pd
	Starting instance pd 192.168.169.43:2379
	Starting instance pd 192.168.169.42:2379
	Starting instance pd 192.168.169.41:2379
	Start pd 192.168.169.43:2379 success
	Start pd 192.168.169.42:2379 success
	Start pd 192.168.169.41:2379 success
Starting component node_exporter
	Starting instance 192.168.169.41
	Start 192.168.169.41 success
Starting component blackbox_exporter
	Starting instance 192.168.169.41
	Start 192.168.169.41 success
Starting component node_exporter
	Starting instance 192.168.169.42
	Start 192.168.169.42 success
Starting component blackbox_exporter
	Starting instance 192.168.169.42
	Start 192.168.169.42 success
Starting component node_exporter
	Starting instance 192.168.169.43
	Start 192.168.169.43 success
Starting component blackbox_exporter
	Starting instance 192.168.169.43
	Start 192.168.169.43 success
Starting component tikv
	Starting instance tikv 192.168.169.43:20160
	Starting instance tikv 192.168.169.41:20160
	Starting instance tikv 192.168.169.42:20160
	Start tikv 192.168.169.41:20160 success
	Start tikv 192.168.169.43:20160 success
	Start tikv 192.168.169.42:20160 success
Starting component tidb
	Starting instance tidb 192.168.169.43:4000
	Starting instance tidb 192.168.169.42:4000
	Starting instance tidb 192.168.169.41:4000
	Start tidb 192.168.169.41:4000 success
	Start tidb 192.168.169.42:4000 success
	Start tidb 192.168.169.43:4000 success
Starting component tiflash
	Starting instance tiflash 192.168.169.43:9000
	Start tiflash 192.168.169.43:9000 success
Starting component cdc
	Starting instance cdc 192.168.169.43:8300
	Starting instance cdc 192.168.169.41:8300
	Starting instance cdc 192.168.169.42:8300
	Start cdc 192.168.169.42:8300 success
	Start cdc 192.168.169.41:8300 success
	Start cdc 192.168.169.43:8300 success
Starting component prometheus
	Starting instance prometheus 192.168.169.42:9090
	Start prometheus 192.168.169.42:9090 success
Starting component grafana
	Starting instance grafana 192.168.169.42:3000
	Start grafana 192.168.169.42:3000 success
Starting component alertmanager
	Starting instance alertmanager 192.168.169.42:9093
	Start alertmanager 192.168.169.42:9093 success
+ [ Serial ] - UpdateTopology: cluster=tidb-test
Started cluster `tidb-test` successfully
```

## 检查集群状态
```
[tidb@tiup-tidb41 ~]$ tiup cluster display tidb-test
Starting component `cluster`: /home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster display tidb-test
Cluster type:       tidb
Cluster name:       tidb-test
Cluster version:    v4.0.2
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

## TiUP卸载集群
```
[tidb@tiup-tidb41 tidb-community-server-v4.0.2-linux-amd64]$ tiup cluster clean tidb-test --all
Starting component `cluster`: /home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster clean tidb-test --all
This operation will stop tidb v4.0.2 cluster tidb-test and clean its' data and log.
Nodes will be ignored: []
Roles will be ignored: []
Files to be deleted are: 
192.168.169.42:
 /tidb-deploy/cdc-8300/log/*.log
 /tidb-deploy/tidb-4000/log/*.log
 /tidb-deploy/tikv-20160/log/*.log
 /tidb-deploy/alertmanager-9093/log/*.log
 /tidb-data/alertmanager-9093/*
 /tidb-data/prometheus-9090/*
 /tidb-deploy/pd-2379/log/*.log
 /tidb-data/pd-2379/*
 /tidb-deploy/grafana-3000/log/*.log
 /tidb-deploy/prometheus-9090/log/*.log
 /tidb-data/tikv-20160/*
192.168.169.41:
 /tidb-deploy/pd-2379/log/*.log
 /tidb-data/pd-2379/*
 /tidb-deploy/cdc-8300/log/*.log
 /tidb-deploy/tidb-4000/log/*.log
 /tidb-deploy/tikv-20160/log/*.log
 /tidb-data/tikv-20160/*
192.168.169.43:
 /tidb-deploy/tiflash-9000/log/*.log
 /data/tiflash/data/*
 /tidb-deploy/tidb-4000/log/*.log
 /tidb-deploy/tikv-20160/log/*.log
 /tidb-data/tikv-20160/*
 /tidb-deploy/pd-2379/log/*.log
 /tidb-data/pd-2379/*
 /tidb-deploy/cdc-8300/log/*.log
Do you want to continue? [y/N]: y
Cleanup cluster...
+ [ Serial ] - SSHKeySet: privateKey=/home/tidb/.tiup/storage/cluster/clusters/tidb-test/ssh/id_rsa, publicKey=/home/tidb/.tiup/storage/cluster/clusters/tidb-test/ssh/id_rsa.pub
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.42
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.41
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.42
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.43
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.41
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.42
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.43
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.42
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.42
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.41
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.43
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.43
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.41
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.42
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.43
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.42
+ [ Serial ] - StopCluster
Stopping component alertmanager
	Stopping instance 192.168.169.42
	Stop alertmanager 192.168.169.42:9093 success
Stopping component grafana
	Stopping instance 192.168.169.42
	Stop grafana 192.168.169.42:3000 success
Stopping component prometheus
	Stopping instance 192.168.169.42
	Stop prometheus 192.168.169.42:9090 success
Stopping component cdc
	Stopping instance 192.168.169.43
	Stopping instance 192.168.169.42
	Stopping instance 192.168.169.41
	Stop cdc 192.168.169.42:8300 success
	Stop cdc 192.168.169.41:8300 success
	Stop cdc 192.168.169.43:8300 success
Stopping component tiflash
	Stopping instance 192.168.169.43
	Stop tiflash 192.168.169.43:9000 success
Stopping component tidb
	Stopping instance 192.168.169.43
	Stopping instance 192.168.169.42
	Stopping instance 192.168.169.41
	Stop tidb 192.168.169.42:4000 success
	Stop tidb 192.168.169.41:4000 success
	Stop tidb 192.168.169.43:4000 success
Stopping component tikv
	Stopping instance 192.168.169.43
	Stopping instance 192.168.169.41
	Stopping instance 192.168.169.42
	Stop tikv 192.168.169.42:20160 success
	Stop tikv 192.168.169.43:20160 success
	Stop tikv 192.168.169.41:20160 success
Stopping component pd
	Stopping instance 192.168.169.43
	Stopping instance 192.168.169.41
	Stopping instance 192.168.169.42
	Stop pd 192.168.169.41:2379 success
	Stop pd 192.168.169.43:2379 success
	Stop pd 192.168.169.42:2379 success
Stopping component node_exporter
Stopping component blackbox_exporter
Stopping component node_exporter
Stopping component blackbox_exporter
Stopping component node_exporter
Stopping component blackbox_exporter
+ [ Serial ] - CleanupCluster
Cleanup instance 192.168.169.43
Cleanup 192.168.169.43 success
Cleanup instance 192.168.169.42
Cleanup 192.168.169.42 success
Cleanup instance 192.168.169.41
Cleanup 192.168.169.41 success
Cleanup cluster `tidb-test` successfully
```



```
[tidb@tiup-tidb41 tidb-community-server-v4.0.2-linux-amd64]$ tiup install tiflash:v4.0.2
component tiflash version v4.0.2 is already installed
[tidb@tiup-tidb41 tidb-community-server-v4.0.2-linux-amd64]$ tiup clean tiflash:v4.0.2
[tidb@tiup-tidb41 tidb-community-server-v4.0.2-linux-amd64]$ tiup uninstall tiflash:v4.0.2
Uninstalled component `tiflash:v4.0.2` successfully!
[tidb@tiup-tidb41 tidb-community-server-v4.0.2-linux-amd64]$ tiup clean tiflash:v4.0.2
[tidb@tiup-tidb41 tidb-community-server-v4.0.2-linux-amd64]$ tiup install tiflash:v4.0.2
```



## 常见错误解决

最开始安装过一次，以为tiflash必须要配置两个才能来起来，所以想尝试重新部署一次  

但是正常 tiup clean --all 删除所有组件之后，修改topology.yaml的tiflash配置重新部署，出现如下报错  

解决方案为，进入/home/tidb/.tiup/storage/cluster/clusters目录下删除tidb-test的文件   

本人猜测可能是clean的时候没有将这部分文件一起删除导致的

```shell
[tidb@tiup-tidb41 ~]$ export TIUP_MIRRORS=/home/tidb/tidb-community-server-v4.0.2-linux-amd64

[tidb@tiup-tidb41 ~]$ tiup cluster deploy tidb-test v4.0.2 topology.yaml --user root -p 
Starting component `cluster`: /home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster deploy tidb-test v4.0.2 topology.yaml --user root -p

Error: Cluster name 'tidb-test' is duplicated (deploy.name_dup)

Please specify another cluster name
Error: run `/home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster` (wd:/home/tidb/.tiup/data/SLZjdQu) failed: exit status 1




# 解决方式

[tidb@tiup-tidb41 clusters]$ pwd
/home/tidb/.tiup/storage/cluster/clusters

[tidb@tiup-tidb41 clusters]$ rm -rf tidb-test/
```