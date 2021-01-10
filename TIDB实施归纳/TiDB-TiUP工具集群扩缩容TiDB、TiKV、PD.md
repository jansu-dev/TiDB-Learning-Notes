# TiDB-TiUP工具集群扩缩容TiDB、TiKV、PD

> - [扩容TiDB、TiKV、PD节点](#扩容TiDB、TiKV、PD节点)  
>     - [编写scale-out文件](#编写scale-out文件)  
>     - [执行scale-out扩容操作](#执行scale-out扩容操作)  
>     - [display验证扩容操作](#display验证扩容操作)  
> - [缩容TiDB、TiKV、PD节点](#缩容TiDB、TiKV、PD节点)  
>     - [缩容TiDB节点](#缩容TiDB节点)  
>     - [缩容TiKV节点](#缩容TiKV节点)  
>     - [缩容PD节点](#缩容PD节点)  



## 扩容TiDB、TiKV、PD节点
#### 编写scale-out文件
```
[tidb@tiup-tidb41 tidb-community-server-v4.0.9-linux-amd64]$ cat scale-out.yaml  

[tidb@tiup-tidb41 tidb-community-server-v4.0.9-linux-amd64]$ vi scale-out.yaml 
tidb_servers:
  - host: 192.168.169.44
    ssh_port: 22
    port: 4000
    status_port: 10080
    deploy_dir: /data/tidb-deploy/install/tidb-4000
    log_dir: /data/tidb-deploy/install/log/tidb-4000

tikv_servers:
  - host: 192.168.169.44
    ssh_port: 22
    port: 20160
    status_port: 20180
    deploy_dir: /data/tidb-deploy/install/deploy/tikv-20160
    data_dir: /data/tidb-data/install/data/tikv-20160
    log_dir: /data/tidb-deploy/install/log/tikv-20160


pd_servers:
  - host: 192.168.169.44
    ssh_port: 22
    name: pd-192.168.169.44-2379
    client_port: 2379
    peer_port: 2380
    deploy_dir: /data/tidb-deploy/install/deploy/pd-2379
    data_dir: /data/tidb-data/install/data/pd-2379
    log_dir: /data/tidb-deploy/install/log/pd-2379
```


#### 执行scale-out扩容操作
```
[tidb@tiup-tidb41 tidb-community-server-v4.0.9-linux-amd64]$ tiup cluster scale-out tidb-test scale-out.yaml
Starting component `cluster`: /home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster scale-out tidb-test scale-out.yaml
Please confirm your topology:
Cluster type:    tidb
Cluster name:    tidb-test
Cluster version: v4.0.9
Type  Host            Ports        OS/Arch       Directories
----  ----            -----        -------       -----------
pd    192.168.169.44  2379/2380    linux/x86_64  /data/tidb-deploy/install/deploy/pd-2379,/data/tidb-data/install/data/pd-2379
tikv  192.168.169.44  20160/20180  linux/x86_64  /data/tidb-deploy/install/deploy/tikv-20160,/data/tidb-data/install/data/tikv-20160
tidb  192.168.169.44  4000/10080   linux/x86_64  /data/tidb-deploy/install/tidb-4000
Attention:
    1. If the topology is not what you expected, check your yaml file.
    2. Please confirm there is no port/directory conflicts in same host.
Do you want to continue? [y/N]:  y
Input SSH password: 
+ [ Serial ] - SSHKeySet: privateKey=/home/tidb/.tiup/storage/cluster/clusters/tidb-test/ssh/id_rsa, publicKey=/home/tidb/.tiup/storage/cluster/clusters/tidb-test/ssh/id_rsa.pub
......
......
Scaled cluster `tidb-test` out successfully
```

#### display验证扩容操作
```
[tidb@tiup-tidb41 tidb-community-server-v4.0.2-linux-amd64]$ tiup cluster display tidb-test
Starting component `cluster`: /home/tidb/.tiup/components/cluster/v1.3.1/
......
......
tikv-20160               /data/tidb-deploy/tikv-20160
192.168.169.44:20160  tikv          192.168.169.44  20160/20180                      linux/x86_64  Up      /data/tidb-data/install/data/tikv-20160  /data/tidb-deploy/install/deploy/tikv-20160
Total nodes: 19
```


## 缩容TiDB、TiKV、PD节点

#### 缩容TiKV节点

 - 通过node参数指定要缩容的TiKV节点
```
[tidb@tiup-tidb41 tidb-community-server-v4.0.2-linux-amd64]$ tiup cluster scale-in tidb-test --node 192.168.169.44:20160

Starting component `cluster`: /home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster scale-in tidb-test --node 192.168.169.44:20160
This operation will delete the 192.168.169.44:20160 nodes in `tidb-test` and all their data.
Do you want to continue? [y/N]: y
Scale-in nodes...
+ [ Serial ] - SSHKeySet: privateKey=/home/tidb/.tiup/storage/cluster/

......
......

Scaled cluster `tidb-test` in successfully
```
 - 通过display参数验证缩容的TiKV节点
```
[tidb@tiup-tidb41 tidb-community-server-v4.0.2-linux-amd64]$ tiup cluster display tidb-test
......
......
There are some nodes can be pruned: 
	Nodes: [192.168.169.44:20160]
	You can destroy them with the command: `tiup cluster prune tidb-test`
```
 - 通过prune将offline的TiKV节点prune至Tombstone状态
```
[tidb@tiup-tidb41 tidb-community-server-v4.0.2-linux-amd64]$ tiup cluster prune tidb-test
Starting component `cluster`: /home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster prune tidb-test
+ [ Serial ] - SSHKeySet: privateKey=/home/tidb/.tiup/storage/cluster/clusters/tidb-test/ssh/id_rsa, publicKey=/home/tidb/.tiup/storage/cluster/clusters/tidb-test/ssh/id_rsa.pub
......
......
Will destroy these nodes: [192.168.169.44:20160]
Do you confirm this action? [y/N]: y
Start destroy Tombstone nodes: [192.168.169.44:20160] ...
......
......
  - Regenerate config tikv -> 192.168.169.43:20160 ... Done
  - Regenerate config tikv -> 192.168.169.44:20160 ... Error
  - Regenerate config tidb -> 192.168.169.41:4000 ... Done
......
......
Destroy success
```

## display验证TiKV节点缩容
```
[tidb@tiup-tidb41 tidb-community-server-v4.0.2-linux-amd64]$ tiup cluster display tidb-test
Starting component `cluster`: /home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster display tidb-test
Cluster type:       tidb
Cluster name:       tidb-test
Cluster version:    v4.0.2
SSH type:           builtin
Dashboard URL:      http://192.168.169.41:2379/dashboard
ID                    Role          Host            Ports                            OS/Arch       Status  Data Dir                                 Deploy Dir
--                    ----          ----            -----                            -------       ------  --------                                 ----------
192.168.169.42:9093   alertmanager  192.168.169.42  9093/9094                        linux/x86_64  Up      /data/tidb-data/alertmanager-9093        /data/tidb-deploy/alertmanager-9093
192.168.169.41:8300   cdc           192.168.169.41  8300                             linux/x86_64  Up      -                                        /data/tidb-deploy/cdc-8300
192.168.169.42:8300   cdc           192.168.169.42  8300                             linux/x86_64  Up      -                                        /data/tidb-deploy/cdc-8300
192.168.169.43:8300   cdc           192.168.169.43  8300                             linux/x86_64  Up      -                                        /data/tidb-deploy/cdc-8300
192.168.169.42:3000   grafana       192.168.169.42  3000                             linux/x86_64  Up      -                                        /data/tidb-deploy/grafana-3000
192.168.169.41:2379   pd            192.168.169.41  2379/2380                        linux/x86_64  Up|UI   /data/tidb-data/pd-2379                  /data/tidb-deploy/pd-2379
192.168.169.42:2379   pd            192.168.169.42  2379/2380                        linux/x86_64  Up      /data/tidb-data/pd-2379                  /data/tidb-deploy/pd-2379
192.168.169.43:2379   pd            192.168.169.43  2379/2380                        linux/x86_64  Up      /data/tidb-data/pd-2379                  /data/tidb-deploy/pd-2379
192.168.169.44:2379   pd            192.168.169.44  2379/2380                        linux/x86_64  Up|L    /data/tidb-data/install/data/pd-2379     /data/tidb-deploy/install/deploy/pd-2379
192.168.169.42:9090   prometheus    192.168.169.42  9090                             linux/x86_64  Up      /data/tidb-data/prometheus-9090          /data/tidb-deploy/prometheus-9090
192.168.169.41:4000   tidb          192.168.169.41  4000/10080                       linux/x86_64  Up      -                                        /data/tidb-deploy/tidb-4000
192.168.169.42:4000   tidb          192.168.169.42  4000/10080                       linux/x86_64  Up      -                                        /data/tidb-deploy/tidb-4000
192.168.169.43:4000   tidb          192.168.169.43  4000/10080                       linux/x86_64  Up      -                                        /data/tidb-deploy/tidb-4000
192.168.169.44:4000   tidb          192.168.169.44  4000/10080                       linux/x86_64  Up      -                                        /data/tidb-deploy/install/tidb-4000
192.168.169.44:9000   tiflash       192.168.169.44  9000/8123/3930/20170/20292/8234  linux/x86_64  Up      /data/tiflash1/data,/data/tiflash2/data  /data/tidb-deploy/tiflash-9000
192.168.169.41:20160  tikv          192.168.169.41  20160/20180                      linux/x86_64  Up      /data/tidb-data/tikv-20160               /data/tidb-deploy/tikv-20160
192.168.169.42:20160  tikv          192.168.169.42  20160/20180                      linux/x86_64  Up      /data/tidb-data/tikv-20160               /data/tidb-deploy/tikv-20160
192.168.169.43:20160  tikv          192.168.169.43  20160/20180                      linux/x86_64  Up      /data/tidb-data/tikv-20160               /data/tidb-deploy/tikv-20160
```

#### 缩容TiDB节点
 - 开始缩容TiDB节点
```
[tidb@tiup-tidb41 tidb-community-server-v4.0.2-linux-amd64]$ tiup cluster scale-in tidb-test --node 192.168.169.44:4000
Starting component `cluster`: /home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster scale-in tidb-test --node 192.168.169.44:4000
This operation will delete the 192.168.169.44:4000 nodes in `tidb-test` and all their data.
Do you want to continue? [y/N]: y
......
......
Scaled cluster `tidb-test` in successfully
```


 - 验证缩容TiDB节点
```
[tidb@tiup-tidb41 tidb-community-server-v4.0.2-linux-amd64]$ tiup cluster display tidb-test
Starting component `cluster`: /home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster display tidb-test
Cluster type:       tidb
Cluster name:       tidb-test
Cluster version:    v4.0.2
SSH type:           builtin
Dashboard URL:      http://192.168.169.41:2379/dashboard
ID                    Role          Host            Ports                            OS/Arch       Status  Data Dir                                 Deploy Dir
--                    ----          ----            -----                            -------       ------  --------                                 ----------
192.168.169.42:9093   alertmanager  192.168.169.42  9093/9094                        linux/x86_64  Up      /data/tidb-data/alertmanager-9093        /data/tidb-deploy/alertmanager-9093
192.168.169.41:8300   cdc           192.168.169.41  8300                             linux/x86_64  Up      -                                        /data/tidb-deploy/cdc-8300
192.168.169.42:8300   cdc           192.168.169.42  8300                             linux/x86_64  Up      -                                        /data/tidb-deploy/cdc-8300
192.168.169.43:8300   cdc           192.168.169.43  8300                             linux/x86_64  Up      -                                        /data/tidb-deploy/cdc-8300
192.168.169.42:3000   grafana       192.168.169.42  3000                             linux/x86_64  Up      -                                        /data/tidb-deploy/grafana-3000
192.168.169.41:2379   pd            192.168.169.41  2379/2380                        linux/x86_64  Up|UI   /data/tidb-data/pd-2379                  /data/tidb-deploy/pd-2379
192.168.169.42:2379   pd            192.168.169.42  2379/2380                        linux/x86_64  Up      /data/tidb-data/pd-2379                  /data/tidb-deploy/pd-2379
192.168.169.43:2379   pd            192.168.169.43  2379/2380                        linux/x86_64  Up      /data/tidb-data/pd-2379                  /data/tidb-deploy/pd-2379
192.168.169.44:2379   pd            192.168.169.44  2379/2380                        linux/x86_64  Up|L    /data/tidb-data/install/data/pd-2379     /data/tidb-deploy/install/deploy/pd-2379
192.168.169.42:9090   prometheus    192.168.169.42  9090                             linux/x86_64  Up      /data/tidb-data/prometheus-9090          /data/tidb-deploy/prometheus-9090
192.168.169.41:4000   tidb          192.168.169.41  4000/10080                       linux/x86_64  Up      -                                        /data/tidb-deploy/tidb-4000
192.168.169.42:4000   tidb          192.168.169.42  4000/10080                       linux/x86_64  Up      -                                        /data/tidb-deploy/tidb-4000
192.168.169.43:4000   tidb          192.168.169.43  4000/10080                       linux/x86_64  Up      -                                        /data/tidb-deploy/tidb-4000
192.168.169.44:9000   tiflash       192.168.169.44  9000/8123/3930/20170/20292/8234  linux/x86_64  Up      /data/tiflash1/data,/data/tiflash2/data  /data/tidb-deploy/tiflash-9000
192.168.169.41:20160  tikv          192.168.169.41  20160/20180                      linux/x86_64  Up      /data/tidb-data/tikv-20160               /data/tidb-deploy/tikv-20160
192.168.169.42:20160  tikv          192.168.169.42  20160/20180                      linux/x86_64  Up      /data/tidb-data/tikv-20160               /data/tidb-deploy/tikv-20160
192.168.169.43:20160  tikv          192.168.169.43  20160/20180                      linux/x86_64  Up      /data/tidb-data/tikv-20160               /data/tidb-deploy/tikv-20160
Total nodes: 17
```

## 缩容PD节点

 - 开始缩容PD节点
```
[tidb@tiup-tidb41 tidb-community-server-v4.0.2-linux-amd64]$ tiup cluster scale-in tidb-test --node 192.168.169.44:2379
Starting component `cluster`: /home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster scale-in tidb-test --node 192.168.169.44:2379
This operation will delete the 192.168.169.44:2379 nodes in `tidb-test` and all their data.
Do you want to continue? [y/N]: y
Scale-in nodes...
......
......
Scaled cluster `tidb-test` in successfully
```
 - 验证PD节点缩容
```
[tidb@tiup-tidb41 tidb-community-server-v4.0.2-linux-amd64]$ tiup cluster display tidb-test
Starting component `cluster`: /home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster display tidb-test
Cluster type:       tidb
Cluster name:       tidb-test
Cluster version:    v4.0.2
SSH type:           builtin
Dashboard URL:      http://192.168.169.41:2379/dashboard
ID                    Role          Host            Ports                            OS/Arch       Status   Data Dir                                 Deploy Dir
--                    ----          ----            -----                            -------       ------   --------                                 ----------
192.168.169.42:9093   alertmanager  192.168.169.42  9093/9094                        linux/x86_64  Up       /data/tidb-data/alertmanager-9093        /data/tidb-deploy/alertmanager-9093
192.168.169.41:8300   cdc           192.168.169.41  8300                             linux/x86_64  Up       -                                        /data/tidb-deploy/cdc-8300
192.168.169.42:8300   cdc           192.168.169.42  8300                             linux/x86_64  Up       -                                        /data/tidb-deploy/cdc-8300
192.168.169.43:8300   cdc           192.168.169.43  8300                             linux/x86_64  Up       -                                        /data/tidb-deploy/cdc-8300
192.168.169.42:3000   grafana       192.168.169.42  3000                             linux/x86_64  Up       -                                        /data/tidb-deploy/grafana-3000
192.168.169.41:2379   pd            192.168.169.41  2379/2380                        linux/x86_64  Up|L|UI  /data/tidb-data/pd-2379                  /data/tidb-deploy/pd-2379
192.168.169.42:2379   pd            192.168.169.42  2379/2380                        linux/x86_64  Up       /data/tidb-data/pd-2379                  /data/tidb-deploy/pd-2379
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