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

VMware Virtual Platform说明时虚拟机；

```
[root@tiup-tidb41 ~]# dmidecode |grep "Product Name"
	Product Name: VMware Virtual Platform
	Product Name: 440BX Desktop Reference Platform

``` 



* CPU超线程检测

    - 理论支撑：
        - 多线程指在一个CPU核心上同时执行多个线程，也可以是多个任务，尽管在同一个核心内执行但彼此完全分离。

        - 超线程技术是一种硬件实现的特殊多线程，CPU在执行一条机器指令时，不会完全地利用所有的CPU资源，大量资源被闲置，超线程技术允许两个线程同时不冲突地使用CPU中的资源。超线程技术能有效提升CPU利用率，改善计算机的性能，提高系统可靠性。  

        - 如：一条整数运算指令只会用到整数运算单元，此时浮点运算单元就空闲了，若使用了超线程技术，且另一个线程刚好此时要执行一个浮点运算指令，CPU就允许属于两个不同线程的整数运算指令和浮点运算指令同时执行。  

        - 注意：此处的“同时”在微观上还是串行的，上下文切换代价很小所以近乎并行。

    - 验证修改
        - 在 Intel 官网查找其物理核心数，确认 CPU(s) 是否为物理核心数的 2 倍，如果是说明已经开启超线程
        - 注意：大数据团队项目时一般会关闭超线程的使用，只能在BIOS中开启超线程

```
[root@tiup-tidb41 ~]# lscpu |grep ^Socket\(s\):
Socket(s):             2

[root@tiup-tidb41 ~]# lscpu |grep ^CPU\(s\):
CPU(s):                4
```

* CPU核心数检测

需要确保客户环境的超线程核心数超过16个 vcore

```
[root@tiup-tidb41 ~]# lscpu |grep ^CPU\(s\):
CPU(s):                4
```

* CPU时钟频率检测

待解决：CPU时钟频率检测多少算低？
---

```
[root@tiup-tidb41 ~]# less /proc/cpuinfo |grep -E 'model name|completed ok'
model name	: Intel(R) Core(TM) i5-9400H CPU @ 2.50GHz
model name	: Intel(R) Core(TM) i5-9400H CPU @ 2.50GHz
model name	: Intel(R) Core(TM) i5-9400H CPU @ 2.50GHz
model name	: Intel(R) Core(TM) i5-9400H CPU @ 2.50GHz
```

* CPU性能模式检测

    - 命令输出应为 performance，否则需要调整 powersave 模式为 performance 模式

        如果遇到系统版本不支持CPU 性能模式修改的状况怎么办？
        ---
        
        ```
        [root@tiup-tidb41 ~]# cat /sys/devices/system/cpu/cpu0/        cpufreq/scaling_governor
				```

    - 持久生效需要在 BIOS 中修改，在 OS 中修改 CPU performance 模式命令如下  
    - 注意 OS 中修改会由于重启而失效，最好配置到 /etc/rc.local 中，防止高可用测试后重启服务器恢复为节能模式
    
       ```
        cpupower -c all frequency-set -g performance
       ```



* NUMA检测

NUMA: Initialized distance table 说明已开启  
No NUMA configuration found 说明支持但未开启  
其他输出需要确认服务器为几路 CPU，可能的原因是 CPU 只有一块   

```
[root@tiup-tidb41 ~]# dmesg |grep -i numa
[    0.000000] NUMA: Node 0 [mem 0x00000000-0x0009ffff] + [mem 0x00100000-0x7fffffff] -> [mem 0x00000000-0x7fffffff]
```

使用命令 numactl -H 确认
available: 2 nodes (0-1) 即为开启，两个 node  
available: 1 nodes (0) 代表未开启 NUMA，或 CPU 数量不够
```
[root@tiup-tidb41 ~]# yum install -y numactl
Loaded plugins: fastestmirror
......
......
Complete!

[root@tiup-tidb41 ~]# numactl -H
available: 1 nodes (0)
node 0 cpus: 0 1 2 3
node 0 size: 2047 MB
node 0 free: 912 MB
node distances:
node   0 
  0:  10 
```

* 内存容量检测

Total online memory: 2G 说明内存容量为2GB，部署要求32GB以上

```
[root@tiup-tidb41 ~]# lsmem
RANGE                                  SIZE  STATE REMOVABLE BLOCK
0x0000000000000000-0x0000000007ffffff  128M online        no     0
0x0000000008000000-0x0000000027ffffff  512M online       yes   1-4
0x0000000028000000-0x000000007fffffff  1.4G online        no  5-15

Memory block size:       128M
Total online memory:       2G
Total offline memory:      0B
```

* 时区检测

-0800表示西八区，是美国旧金山所在时区  
+0800表示东八区，是中国所在时区

```
[root@tiup-tidb41 ~]# timedatectl set-timezone Asia/Shanghai

[root@tiup-tidb41 ~]# date -R
Sat, 09 Jan 2021 01:00:18 +0800
```

* 各服务器时间同步检测
```

```

* 集群网络延迟检测

同机房一般意味着两机房距离在 50km 以内，任意两节点间的延迟应低于 0.1ms  

同城跨机房的任意两节点间网络延迟应低于 1ms

time=的值意味着两台物理机之间的时延，一般在0.5ms左右
```
[root@tiup-tidb41 ~]# ping 192.168.169.42
PING 192.168.169.42 (192.168.169.42) 56(84) bytes of data.
64 bytes from 192.168.169.42: icmp_seq=1 ttl=64 time=2.39 ms
64 bytes from 192.168.169.42: icmp_seq=2 ttl=64 time=0.589 ms
64 bytes from 192.168.169.42: icmp_seq=3 ttl=64 time=0.445 ms
^C
--- 192.168.169.42 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
rtt min/avg/max/mdev = 0.445/1.143/2.397/0.889 ms

```

* 集群网络贷款检测

发送端
nc -l -p 1234 < /dev/zero
接收端
nc 192.168.0.11 1234 > /dev/null
两端用 dstat 检查
```
[root@tiup-tidb41 ~]# yum install -y nc
Loaded plugins: fastestmirror
......
......
Complete!

[root@tiup-tidb41 ~]# yum install -y dstat
Loaded plugins: fastestmirror
......
......
Complete!



[root@tiup-tidb41 ~]# dstat
You did not select any stats, using -cdngy by default.
----total-cpu-usage---- -dsk/total- -net/total- ---paging-- ---system--
usr sys idl wai hiq siq| read  writ| recv  send|  in   out | int   csw 
  0   0 100   0   0   0|  25k   94k|   0     0 |   0     0 |  75    83 
  0   0 100   0   0   0|   0     0 |  66B  838B|   0     0 |  58    92 
  0   0 100   0   0   0|   0     0 |  66B  358B|   0     0 |  54    93 
  0   0 100   0   0   0|   0     0 |  66B  358B|   0     0 |  54    82 ^C

```

在两端监测网络流量
```
[root@tiup-tidb41 ~]# ifstat ens33 -p
#kernel
Interface        RX Pkts/Rate    TX Pkts/Rate    RX Data/Rate    TX Data/Rate  
                 RX Errs/Drop    TX Errs/Drop    RX Over/Rate    TX Coll/Rate  
ens33                  5 0             6 0           470 0           988 0      
                       0 0             0 0             0 0             0 0 
```

* selinux检测
  - 检查selinux配置文件，修改配置永久生效  
  - 注意此时的修改还没有生效，需要重启
```
[root@tiup-tidb41 ~]# cat /etc/selinux/config |grep SELINUX= |grep -v \#
SELINUX=enforcing

[root@tiup-tidb41 ~]# vi /etc/selinux/config
[root@tiup-tidb41 ~]# cat /etc/selinux/config |grep SELINUX= |grep -v \#
SELINUX=disabled
```

  - 如果不想重启，可以在修改完配置文件后，临时设置selinux
  - 注意这种情况下的设置是临时的，如果没有修改配置文件配置，重启后会是失效
```
[root@tiup-tidb41 ~]# getenforce
Enforcing

[root@tiup-tidb41 ~]# setenforce 0

[root@tiup-tidb41 ~]# getenforce
Permissive
```

* 防火墙检测

```
[root@tiup-tidb41 ~]# systemctl status firewalld.service
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Sat 2021-01-09 06:42:11 CST; 5h 25min left
     Docs: man:firewalld(1)
 Main PID: 788 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─788 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid

Jan 09 06:41:58 localhost.localdomain systemd[1]: Starting firewalld - dynamic firewall daemon...
Jan 09 06:42:11 localhost.localdomain systemd[1]: Started firewalld - dynamic firewall daemon.

[root@tiup-tidb41 ~]# systemctl stop firewalld.service

[root@tiup-tidb41 ~]# systemctl disable firewalld.service

Removed symlink /etc/systemd/system/multi-user.target.wants/firewalld.service.
Removed symlink /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service.
[root@tiup-tidb41 ~]# systemctl status firewalld.service
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: inactive (dead)
     Docs: man:firewalld(1)

Jan 09 06:41:58 localhost.localdomain systemd[1]: Starting firewalld - dynamic firewall daemon...
Jan 09 06:42:11 localhost.localdomain systemd[1]: Started firewalld - dynamic firewall daemon.
Jan 09 01:17:15 tiup-tidb41 systemd[1]: Stopping firewalld - dynamic firewall daemon...
Jan 09 01:17:16 tiup-tidb41 systemd[1]: Stopped firewalld - dynamic firewall daemon.
```

* SWAP检测

编辑 /etc/fstab 注释掉 swap 所在的行

```
[root@tiup-tidb41 ~]# cat /etc/fstab 

#
# /etc/fstab
# Created by anaconda on Fri Jan  8 09:28:47 2021
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
/dev/mapper/centos-root /                       xfs     defaults        0 0
UUID=74ed93c5-7bc4-49ba-9007-fdc990801fac /boot                   xfs     defaults        0 0
```

* 磁盘挂载检测
```

```

* TiKV磁盘性能检测

粘贴对比测试语句？
---


* 标准大页检测

检查 /etc/sysctl.conf 注释掉带有 vm.nr_hugepages 的行，重启 OS 后生效

 ```
 [root@tiup-tidb41 ~]# cat /etc/sysctl.conf 
 # sysctl settings are defined through files in
 # /usr/lib/sysctl.d/, /run/sysctl.d/, and /etc/sysctl.d/.
 #
 # Vendors settings live in /usr/lib/sysctl.d/.
 # To override a whole file, create a new file with the same in
 # /etc/sysctl.d/ and put new settings there. To override
 # only specific settings, add a file with a lexically later
 # name in /etc/sysctl.d/ and put new settings there.
 #
 # For more information, see sysctl.conf(5) and sysctl.d(5).
 ```

通过命令检查内存是否释放  

```
[root@tiup-tidb41 ~]# grepHuge /proc/meminfo
AnonHugePages:     12288 kB
HugePages_Total:       0
HugePages_Free:        0
HugePages_Rsvd:        0
HugePages_Surp:        0
Hugepagesize:       2048 kB
```
当不能重启时，将 vm.nr_hugepages 的值改小后执行 sysctl -p 观察内存是否释放  
```
123
```


* 透明大页检测

检查配置文件,出现always madvise [never]说明透明大页为关闭状态

```
[root@tiup-tidb41 ~]# cat /sys/kernel/mm/transparent_hugepage/enabled
[always] madvise never
```

否则执行如下操作，追加transparent_hugepage=never内容，并重启服务器后再次检查

```
[root@tiup-tidb41 ~]# vi /etc/default/grub

[root@tiup-tidb41 ~]# tail -2 /etc/default/grub
GRUB_CMDLINE_LINUX="crashkernel=auto spectre_v2=retpoline rd.lvm.lv=centos/root rhgb quiet transparent_hugepage=never"
GRUB_DISABLE_RECOVERY="true"

[root@tiup-tidb41 ~]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-1062.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-1062.el7.x86_64.img
Found linux image: /boot/vmlinuz-0-rescue-597411e2612e433b9bb8cb2980664fca
Found initrd image: /boot/initramfs-0-rescue-597411e2612e433b9bb8cb2980664fca.img
done

[root@tiup-tidb41 ~]# reboot

[root@tiup-tidb41 ~]# cat /sys/kernel/mm/transparent_hugepage/enabled
[always] madvise never

```

### 集群部署后项目检测

* 集群版本选择
如需使用 master 版本，需找研发确认 hash

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