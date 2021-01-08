# TiDB-集群部署前环境检测
时间：2021/01/07

> - [资源配置检测](#资源配置检测)
> - [应用适配检测](#应用适配检测)
>    - [联机业务适配检测](#联机业务适配检测)
>    - [批处理适配检测](#批处理适配检测)
> - [性能压力测试](#性能压力测试)
>    - [集群部署前项目检测](#集群部署前项目检测)
>    - [集群部署后项目检测](#集群部署后项目检测)
>    - [基准测试](#基准测试)
>    - [业务压测业务压测](#)
> - [备份恢复能力测试](#备份恢复能力测试)


## 资源配置检测
| 检查项 | 要求限制 | 备注 |
| --- | --- | --- |
| 服务器数量 | 6台或以上 |  |
| CPU | 40vCore以上 |  |
| 内存 | 128GB或以上 |  |
| NVMe SSD | TiKV单台4块或更多 |  |
| 网络带宽 | 万兆或以上 |  |
| 操作系统 | CentOS或RHEL 7.3+ |  |
| 亮点测试用例 |  |  |

## 应用适配检测


### 联机业务适配检测

* 悲观锁或乐观锁

* 隔离级别

* 唯一序列号生成方案

### 批处理适配检测

* 事务大小及并发

* 大事务的分页SQL改造


## 性能压力测试

### 集群部署前项目检测

* 操作系统环境检测
```
[root@tiup-tidb41 ~]# cat /etc/redhat-release 
CentOS Linux release 7.7.1908 (Core)

[root@tiup-tidb41 ~]# cat /etc/issue
\S
Kernel \r on an \m

[root@tiup-tidb41 ~]# uname -a
Linux tiup-tidb41 3.10.0-1062.el7.x86_64 #1 SMP Wed Aug 7 18:08:02 UTC 2019 x86_64 x86_64 x86_64 GNU/Linux

[root@tiup-tidb41 ~]# yum install redhat-lsb -y
Loaded plugins: fastestmirror
......
......
Complete!

[root@tiup-tidb41 ~]# lsb_release -a
LSB Version:	:core-4.1-amd64:core-4.1-noarch:cxx-4.1-amd64:cxx-4.1-noarch:desktop-4.1-amd64:desktop-4.1-noarch:languages-4.1-amd64:languages-4.1-noarch:printing-4.1-amd64:printing-4.1-noarch
Distributor ID:	CentOS
Description:	CentOS Linux release 7.7.1908 (Core)
Release:	7.7.1908
Codename:	Core
```

* 操作系统位数检测
```
[root@tiup-tidb41 ~]# arch
x86_64

[root@tiup-tidb41 ~]# uname -m
x86_64
```

* 物理机或虚拟机检测
```
[root@tiup-tidb41 ~]# dmidecode |grep "Product Name"
	Product Name: VMware Virtual Platform
	Product Name: 440BX Desktop Reference Platform

``` 

VMware Virtual Platform说明时虚拟机；

* CPU超线程检测
```
[root@tiup-tidb41 ~]# lscpu |grep ^CPU\(s\):
CPU(s):                4
```
大数据团队项目时一般会关闭超线程的使用，只能在BIOS中开启超线程。

* CPU核心数检测
```

```

* CPU时钟频率检测
```

```

* CPU性能模式检测
```

```

* NUMA检测
```

```

* 内存容量检测
```

```

* 时区检测
```

```

* 各服务器时间同步检测
```

```

* 集群网络延迟检测
```

```

* 集群网络贷款检测
```

```

* selinux检测
```

```

* 防火墙检测
```

```

* SWAP检测
```

```

* 磁盘挂载检测
```

```

* TiKV磁盘性能检测
```

```

* 标准大页检测
```

```

* 透明大页检测
```

```

### 集群部署后项目检测

* 集群版本选择
```

```

* 工具版本选择
```

```

* TiDB版本选择
```

```

* TiDB的NUMA绑核操作
```

```

* TiKV打Lable
```

```

* 负载均衡器检测
```

```

* 调整GC life time
```

```

* 开启大事务支持
```

```

* 全量analyze脚本
```

```

* 全量compat脚本

### 基准测试

* sysbench检测
```

```

* TPCC检测
```

```

* TPCH检测
```

```


### 业务压测

#### OLTP业务测试项

* 压测链路网络延迟
```

```

* 压测链路的网络带宽
```

```

* scatter region
```

```

* 热点打散参数
```

```

* jdbc 参数
```

```

* 网络带宽是否成为瓶颈
```

```

* SQL 中是否有用 or 连接条件（index merge）
```

```

* 联机应用与批处理应用连接不同TiDB节点
```

```

* 完善 SQL statement 监控
```

```

* 悲观锁的 pipline 模式
```

```

* 其他调优方法

#### OLAP业务测试项
* 存储引擎
```

```

* 计算引擎
```

```

## 备份恢复能力测试

* BR备份时双网卡绑定
```

```

* BR备份并发测试
```

```

* BR备份压缩算法
```

```

* BR恢复的单次读取文件数
```

```

* BR恢复的额外参数
```

```

* lighting 恢复时的 backend 选择
```

```

* lighting 恢复时额外参数
```

```




使用lsblk命令进行判断，参数-d表示显示设备名称，参数-o表示仅显示特定的列
ROTA是1的表示可以旋转，反之则不能旋转
nvmeSSD一般name以nvme开头



```
[root@tidb04-44 tidb-docker-compose]# lsblk -d -o name,rota
NAME ROTA
sda     1
sr0     1
```

检验网卡带宽
```
[root@tidb04-44 tidb-docker-compose]# ethtool ens33
Settings for ens33:
	Supported ports: [ TP ]
	Supported link modes:   10baseT/Half 10baseT/Full 
	                        100baseT/Half 100baseT/Full 
	                        1000baseT/Full 
	Supported pause frame use: No
	Supports auto-negotiation: Yes
	Supported FEC modes: Not reported
	Advertised link modes:  10baseT/Half 10baseT/Full 
	                        100baseT/Half 100baseT/Full 
	                        1000baseT/Full 
	Advertised pause frame use: No
	Advertised auto-negotiation: Yes
	Advertised FEC modes: Not reported
	Speed: 1000Mb/s
	Duplex: Full
	Port: Twisted Pair
	PHYAD: 0
	Transceiver: internal
	Auto-negotiation: on
	MDI-X: off (auto)
	Supports Wake-on: d
	Wake-on: d
	Current message level: 0x00000007 (7)
			       drv probe link
	Link detected: yes
```