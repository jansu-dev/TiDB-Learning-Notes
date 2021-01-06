# TiDB-单机多TiKV实例、多TiDB实例部署

## summary
> - [配置inventory的TiKV部分](#配置inventory的TiKV部分)  
> - [集群节点环境配置与参数限制](#集群节点环境配置与参数限制)
>   - [中控机操作部署机建用户](#中控机操作部署机建用户)
>   - [中控机操作部署机配置ntp服务](#中控机操作部署机配置ntp服务)
>   - [中控及操作部署机设置CPU模式](#中控及操作部署机设置CPU模式)
> - [ansible部署命令黄金五步骤走](#ansible部署命令黄金五步骤走)
>   - [执行local_prepare联网下载binary包](#执行local_prepare联网下载binary包)
>   - [初始化系统环境并修改内核参数](#初始化系统环境并修改内核参数)
>   - [部署TiDB集群软件](#部署TiDB集群软件)  
>   - [安装Dashboard依赖包](#安装Dashboard依赖包)
>   - [执行start启动TiDB集群](#执行start启动TiDB集群)
> - [pd-ctl命令行验证是否成功](#pd-ctl命令行验证是否成功)







## 配置inventory的TiKV部分

配置范例：
```
[tidb@tidb01-41 tidb-ansible]$ vi inventory.ini

[tidb_servers]
TiDB1-11 ansible_host=192.168.1.41 deploy_dir=/data1/deploy tikv_port=4000 tikv_status_port=10080
TiDB1-12 ansible_host=192.168.1.41 deploy_dir=/data2/deploy tikv_port=4001 tikv_status_port=10081
TiDB1-21 ansible_host=192.168.1.43 deploy_dir=/data1/deploy tikv_port=4000 tikv_status_port=10080
TiDB1-22 ansible_host=192.168.1.43 deploy_dir=/data2/deploy tikv_port=4001 tikv_status_port=10081

[pd_servers]
192.168.1.41
192.168.1.42
192.168.1.43

# 注意：要使用 TiKV 的 labels，必须同时配置 PD 的 location_labels 参数，否则 labels 设置不生效。

# 多实例场景需要额外配置 status 端口，示例如下：

[tikv_servers]
TiKV1-11 ansible_host=192.168.1.41 deploy_dir=/data1/deploy tikv_port=20171 tikv_status_port=20181 labels="host=tikv1"
TiKV1-12 ansible_host=192.168.1.41 deploy_dir=/data2/deploy tikv_port=20172 tikv_status_port=20182 labels="host=tikv1"
TiKV2-21 ansible_host=192.168.1.42 deploy_dir=/data1/deploy tikv_port=20171 tikv_status_port=20181 labels="host=tikv2"
TiKV2-22 ansible_host=192.168.1.42 deploy_dir=/data2/deploy tikv_port=20172 tikv_status_port=20182 labels="host=tikv2"
TiKV3-31 ansible_host=192.168.1.43 deploy_dir=/data1/deploy tikv_port=20171 tikv_status_port=20181 labels="host=tikv3"
TiKV3-32 ansible_host=192.168.1.43 deploy_dir=/data2/deploy tikv_port=20172 tikv_status_port=20182 labels="host=tikv3"


[monitoring_servers]
192.168.1.42

[grafana_servers]
192.168.1.42

[monitored_servers]
192.168.1.41
192.168.1.42
192.168.1.43



# 为使 TiKV 的 labels 设置生效，部署集群时必须设置 PD 的 location_labels 参数
[pd_servers:vars]
location_labels = ["host"]
```

labels参数作用：
 - labels 是 Region 调度的最小单元，每一个 raft group 中不同的 replica 不会在扩展过程中被迁移到同一个lable单元，避免这种情况下 server 宕机导致的单点问题（3副本，2副本落在同一个server）。  
 - raft group 的 multi-replica 主要解决的是数据的容灾问题，labels 参数可以有效防止随数据扩展，在Region 迁移过程中因散列计算 Region 迁移位置时，由于冲撞导致的同一个 server 存储同一个 Region group 的多个 replica 的情况。
- 可以给一个服务器打一个 labels、可以给一个服务器机柜打一个 labels，也可以是一个 IDC 打一个 labels。

## 集群节点环境配置与参数限制


#### block-cache-size下的capacity参数调整

多实例情况下，需要修改 tidb-ansible/conf/tikv.yml 中 block-cache-size 下面的 capacity 参数;
用以限制每个TiKV实例用于block-cache的内存使用限制。

官方推荐设置：capacity = MEM_TOTAL * 0.5 / TiKV 实例数量

本例：各节点内存3G，每个节点部署两台实例，因此 capacity = 3 * 0.5 / 2 = 0.75GB

```shell
[tidb@tidb01-41 ~]$ vi ~/tidb-ansible/conf/tikv.yml


storage:
  block-cache:
    capacity: "0.75GB"
```

#### readpool下coprocessor的并发度调整

官方推荐设置： 参数值 = ( CPU 核心数量 * 0.8 ) / TiKV 实例数量

本例：各节点部署两个实例，CPU 核心数量 8 个，参数值 = ( 8 * 0.8 ) / 2 = 3

```shell
# 使用 shell 命令查看逻辑核心数量
[tidb@tidb01-41 tidb-ansible]$ cat /proc/cpuinfo| grep "processor"| wc -l
8


[tidb@tidb01-41 ~]$ vi ~/tidb-ansible/conf/tikv.yml


readpool:
  coprocessor:
    # Notice: if CPU_NUM > 8, default thread pool size for coprocessors
    # will be set to CPU_NUM * 0.8.
    high-concurrency: 3
    normal-concurrency: 3
    low-concurrency: 3
```

#### raftstore下的capacity参数调整

如果多个 TiKV 实例部署在同一块物理磁盘上，需要修改 conf/tikv.yml 中的 capacity 参数，限制每个 TiKV 实例所能使用的磁盘容量，官方推荐配置：capacity = 磁盘总容量 / TiKV 实例数量。

本例：各节点限制使用磁盘容量为 5 GB ，capacity = 5GB

```
vi ~/tidb-ansible/conf/tikv.yml


raftstore:
  capacity = 5GB
```

## 中控机操作部署机建用户

执行以下命令，依据输入***部署目标机器***的 root 用户密码；
本例新增节点IP为192.168.1.44；



```
[tidb@tidb01-41 tidb-ansible]$ vi hosts.ini 
[tidb@tidb01-41 tidb-ansible]$ cat hosts.ini 
[servers]
192.168.1.44


[all:vars]
username = tidb
ntp_server = cn.pool.ntp.org



[tidb@tidb01-41 tidb-ansible]$ ansible-playbook -i hosts.ini create_users.yml -u root -k
SSH password: 

PLAY [all] ***************************************************************************************************************

......
......

Congrats! All goes well. :-)

```

验证互信时候成功
```
[tidb@tidb01-41 tidb-ansible]$ ansible -i inventory.ini all -m shell -a 'whoami'
192.168.1.43 | SUCCESS | rc=0 >>
tidb

192.168.1.42 | SUCCESS | rc=0 >>
tidb

TiDB1-21 | SUCCESS | rc=0 >>
tidb

TiDB1-22 | SUCCESS | rc=0 >>
tidb

TiDB1-12 | SUCCESS | rc=0 >>
tidb

192.168.1.41 | SUCCESS | rc=0 >>
tidb

TiDB1-11 | SUCCESS | rc=0 >>
tidb

TiKV3-31 | SUCCESS | rc=0 >>
tidb

TiKV3-32 | SUCCESS | rc=0 >>
tidb

TiKV2-21 | SUCCESS | rc=0 >>
tidb

TiKV2-22 | SUCCESS | rc=0 >>
tidb

TiKV1-11 | SUCCESS | rc=0 >>
tidb

TiKV1-12 | SUCCESS | rc=0 >>
tidb
```

验证sudo 免密码配置成功

```
[tidb@tidb01-41 tidb-ansible]$ ansible -i inventory.ini all -m shell -a 'whoami' -b
192.168.1.43 | SUCCESS | rc=0 >>
root

TiDB1-12 | SUCCESS | rc=0 >>
root

192.168.1.41 | SUCCESS | rc=0 >>
root

192.168.1.42 | SUCCESS | rc=0 >>
root

TiDB1-11 | SUCCESS | rc=0 >>
root

TiDB1-21 | SUCCESS | rc=0 >>
root

TiDB1-22 | SUCCESS | rc=0 >>
root

TiKV2-21 | SUCCESS | rc=0 >>
root

TiKV2-22 | SUCCESS | rc=0 >>
root

TiKV3-31 | SUCCESS | rc=0 >>
root

TiKV3-32 | SUCCESS | rc=0 >>
root

TiKV1-11 | SUCCESS | rc=0 >>
root

TiKV1-12 | SUCCESS | rc=0 >>
root
```


## 中控机操作部署机配置ntp服务

***注意：生产上应该指向自己的ntp服务器，本次测试采用了公网公用的ntp服务不稳定。***

```
[tidb@tidb01-41 tidb-ansible]$ ansible-playbook -i hosts.ini deploy_ntp.yml -u tidb -b

......
......

Congrats! All goes well. :-)

```




## 中控及操作部署机设置CPU模式


调整CPU模式，如果同本文出现一样的报错，说明此版本的操作系统不支持CPU模式修改，可直接跳过。

```shell
[tidb@tidb01-41 tidb-ansible]$ ansible -i hosts.ini all -m shell -a "cpupower frequency-set --governor performance" -u tidb -b

192.168.1.44 | FAILED | rc=237 >>
Setting cpu: 0
Error setting new values. Common errors:
- Do you have proper administration rights? (super-user?)
- Is the governor you requested available and modprobed?
- Trying to set an invalid policy?
- Trying to set a specific frequency, but userspace governor is not available,
   for example because of hardware which cannot be set to a specific frequency
   or because the userspace governor isn't loaded?non-zero return code

```



## ansible部署命令黄金五步骤走

#### 执行local_prepare联网下载binary包

执行 local_prepare.yml playbook，联网下载 TiDB binary 至中控机。

```shell
[tidb@tidb01-41 tidb-ansible]$ ansible-playbook local_prepare.yml

PLAY [do local preparation] ***************************************************************************

......
......

Congrats! All goes well. :-)
```

#### 初始化系统环境并修改内核参数

```
[tidb@tidb01-41 tidb-ansible]$ ansible-playbook bootstrap.yml

PLAY [initializing deployment target] *****************************************************************

......
......

Congrats! All goes well. :-)
```


#### 部署TiDB集群软件
```
[tidb@tidb01-41 tidb-ansible]$ ansible-playbook deploy.yml

PLAY [check config locally] ***************************************************************************

......
......

PLAY RECAP ********************************************************************************************
192.168.1.41               : ok=53   changed=4    unreachable=0    failed=0   
192.168.1.42               : ok=121  changed=16   unreachable=0    failed=0   
192.168.1.43               : ok=52   changed=4    unreachable=0    failed=0   
TiDB1-11                   : ok=26   changed=1    unreachable=0    failed=0   
TiDB1-12                   : ok=26   changed=2    unreachable=0    failed=0   
TiDB1-21                   : ok=26   changed=2    unreachable=0    failed=0   
TiDB1-22                   : ok=26   changed=1    unreachable=0    failed=0   
TiKV1-11                   : ok=28   changed=5    unreachable=0    failed=0   
TiKV1-12                   : ok=28   changed=4    unreachable=0    failed=0   
TiKV2-21                   : ok=28   changed=3    unreachable=0    failed=0   
TiKV2-22                   : ok=28   changed=3    unreachable=0    failed=0   
TiKV3-31                   : ok=28   changed=3    unreachable=0    failed=0   
TiKV3-32                   : ok=28   changed=3    unreachable=0    failed=0   
localhost                  : ok=7    changed=4    unreachable=0    failed=0   

Congrats! All goes well. :-)
```

#### 安装Dashboard依赖包
Grafana Dashboard 上的 Report 按钮可用来生成 PDF 文件，此功能依赖 fontconfig 包和英文字体。如
```
[root@tidb01-41 tmp]# sudo yum install fontconfig open-sans-fonts
```

#### 执行start启动TiDB集群
```
[tidb@tidb01-41 tidb-ansible]$ ansible-playbook start.yml

PLAY [check config locally] **********************************************************************************************

......
......

PLAY RECAP *******************************************************************************************************************************************************************************************************
192.168.1.41               : ok=9    changed=2    unreachable=0    failed=0   
192.168.1.42               : ok=34   changed=10   unreachable=0    failed=0   
192.168.1.43               : ok=12   changed=3    unreachable=0    failed=0   
TiDB1-11                   : ok=6    changed=1    unreachable=0    failed=0   
TiDB1-12                   : ok=6    changed=1    unreachable=0    failed=0   
TiDB2-21                   : ok=6    changed=1    unreachable=0    failed=0   
TiDB2-22                   : ok=6    changed=1    unreachable=0    failed=0   
TiKV1-11                   : ok=8    changed=1    unreachable=0    failed=0   
TiKV1-12                   : ok=8    changed=1    unreachable=0    failed=0   
TiKV2-21                   : ok=8    changed=1    unreachable=0    failed=0   
TiKV2-22                   : ok=8    changed=1    unreachable=0    failed=0   
TiKV3-31                   : ok=8    changed=1    unreachable=0    failed=0   
TiKV3-32                   : ok=8    changed=1    unreachable=0    failed=0   
localhost                  : ok=7    changed=4    unreachable=0    failed=0   

Congrats! All goes well. :-)
```




## 验证是否安装成功

 - MySQL客户端连接验证

  ```
[tidb@tidb01-41 tidb-ansible]$ mysql -uroot -P4000 -h192.168.1.43
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 18
Server version: 5.7.25-TiDB-v3.0.1 MySQL Community Server (Apache License 2.0)
MySQL [(none)]> exit
Bye

[tidb@tidb01-41 tidb-ansible]$ mysql -uroot -P4000 -h192.168.1.42
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 17
Server version: 5.7.25-TiDB-v3.0.1 MySQL Community Server (Apache License 2.0)
MySQL [(none)]> exit
Bye

[tidb@tidb01-41 tidb-ansible]$ mysql -uroot -P4001 -h192.168.1.43
ERROR 2003 (HY000): Can't connect to MySQL server on '192.168.1.43' (111)

[tidb@tidb01-41 tidb-ansible]$ mysql -uroot -P4001 -h192.168.1.42
ERROR 2003 (HY000): Can't connect to MySQL server on '192.168.1.42' (111)
  ```

 - grafana图形界面验证
![grafana节点校验](http://cdn.lifemini.cn/dbblog/20210106/9e1e0fde9ec446c7ae32df0a6f1f5338.png)



## 参考文章

[PingCAP官方文档-单机单 TiKV 实例集群拓扑](https://docs.pingcap.com/zh/tidb/stable/online-deployment-using-ansible#%E5%8D%95%E6%9C%BA%E5%A4%9A-tikv-%E5%AE%9E%E4%BE%8B%E9%9B%86%E7%BE%A4%E6%8B%93%E6%89%91)




