# TiDB-Ansible部署工具简介与TiDB集群部署
时间：2020-12-21


### TiDB-Ansible解决的问题
tidb的二进制部署时，某些环境下节点会超过100+；
单节点依次部署是非常麻烦，因此tidbAnsible统一部署及管理非常必要；


TiDB-Ansible的操作时幂等的，在操作过程中遇到报错，修复后即可继续安装。安装时注意，TiDB及TiDB-Ansible版本要对应；

### TiDB-Ansible目录结构

| 主要部分 | 说明 |
|---|---|
| yml文件 | 存放playbook剧本 |
| conf目录 | 配置文件 |
| group_vars目录| 端口配置等 |
| inventory.ini文件 | 主要的配置文件，指定操作主机 |
| resource和download目录 | binary包 |
| scripts目录 | 监控相关json文件，初始化之后生成运维脚本 |
| roles目录 | 角色相关目录和自定义变量 |


### TiDB-Ansible命令简介
| 功能 | 命令 | 备注 |
|---|---|---|
| 环境初始化 | ansible-playbook bootstrap.yml | 在服务器创建相应目录并检测环境信息 |
| 部署集群 | ansible-playbook deploy.yml | 正式开始部署，包含配置文件，启动脚本，binary包的分发等 |
| 更新集群 | ansible-playbook rolling_update.yml | 每个组件一步一步升级操作（pd->tikv->tidb） |
| 关闭集群 | ansible-playbook stop.yml |  |
| 启动集群 | ansible-playbook start.yml |  |

常用参数 
-l:指定host或者别名
--tags：指定task(tidb、tikv等组件)
-f:调整并发


### TiDB-Ansible在线部署TiDB集群

可供离线部署步骤参考使用；

#### 环境与IP规划

> **环境说明**

服务器环境	CentOS Linux release 7.9.2009 (Core)  
数据库版本	5.7.25-TiDB-v3.0.0  
文档参考地址     [**TiDB官网：https://docs.pingcap.com/zh/tidb/stable/production-deployment-using-tiup**](https://docs.pingcap.com/zh/tidb/stable/production-deployment-using-tiup)  

> **IP规划**

| IP地址 | Role信息 | 备注 |
|-|-|-|
| 192.168.1.41 | pd+tikv+tidb-ansible+monitor | 部署主机 |
| 192.168.1.42 | pd+tikv+tidb |  |
| 192.168.1.43 | pd+tikv+tidb |  |
| 192.168.1.44 | pd+tikv+tidb | 用于增删节点 |



> **核心部署步骤**

* 中控机安装依赖
  * 中控机安装git pip curl sshpass
  * 中控机安装Ansible(2.5+)及其依赖
* 中控机部署配置
  * 中控机创建tidb用户并配置互信
  * 中控机下载TiDB-Ansible(TiDB用户下)
  * 中控机配置NTP、CPUfrep、ext4
* 正式开始部署
  * 编辑inventory.ini
  * bootstrap.yml初始化环境
  * deploy.yml部署任务
  * start.yml启动集群
* 测试集群部署






#### 中控机配置依赖

> **中控机安装系统依赖包**

注意事项：
1. 在可联网的下载机上下载系统依赖离线安装包，然后上传至中控机。
2. 该离线包仅支持 CentOS 7 系统，包含安装git pip curl sshpass。
3. pip请确认版本 >= 8.1.2，否则会有兼容问题。

```
tar -xzvf ansible-system-rpms.el7.tar.gz &&
cd ansible-system-rpms.el7 &&
chmod u+x install_ansible_system_rpms.sh &&
./install_ansible_system_rpms.sh

ansible-system-rpms.el7/
ansible-system-rpms.el7/sed-4.2.2-5.el7.x86_64.rpm
......
......
Installed:
  python-backports.x86_64 0:1.0-8.el7        python-backports-ssl_match_hostname.noarch 0:3.4.0.2-4.el7        python-setuptools.noarch 0:0.9.8-7.el7       
  python2-pip.noarch 0:8.1.2-5.el7           sshpass.x86_64 0:1.06-2.el7                                      

Complete!




pip -V

pip 8.1.2 from /usr/lib/python2.7/site-packages (python 2.7)
```

> **中控机tidb 用户生成 ssh key**

创建 tidb 用户并修改密码
```
useradd -m -d /home/tidb tidb

passwd tidb
```

配置 tidb 用户 sudo 免密码；
<span style='color:red'>将 tidb ALL=(ALL) NOPASSWD: ALL 添加到文件末尾即可</span>

```
visudo
tidb ALL=(ALL) NOPASSWD: ALL
```


tidb 用户下生成 SSH key,直接回车即可;
执行成功后:
SSH 私钥文件为 /home/tidb/.ssh/id_rsa;
SSH 公钥文件为 /home/tidb/.ssh/id_rsa.pub。

```
su - tidb


ssh-keygen -t rsa
Generating public/private rsa key pair.
Enter file in which to save the key (/home/tidb/.ssh/id_rsa):
Created directory '/home/tidb/.ssh'.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:


Your identification has been saved in /home/tidb/.ssh/id_rsa.
Your public key has been saved in /home/tidb/.ssh/id_rsa.pub.
The key fingerprint is:


SHA256:eIBykszR1KyECA/h0d7PRKz4fhAeli7IrVphhte7/So tidb@172.16.10.49
The key's randomart image is:
+---[RSA 2048]----+
|=+o+.o.          |
|o=o+o.oo         |
| .O.=.=          |
| . B.B +         |
|o B * B S        |
| * + * +         |
|  o + .          |
| o  E+ .         |
|o   ..+o.        |
+----[SHA256]-----+
```


> **中控机器上下载 TiDB Ansible**


注意事项：
1. 在TiDB用户下操作；
2. 使用以下命令从 TiDB Ansible 项目上下载相应 TAG 版本的tidb-ansible，$tag 替换为选定的 TAG 版本的值，例如 v3.0.0；
3. 使用外部下载机下载相应版本TiDB Ansible后，用sftp等软件将安装包上传；
4. 将tidb-ansible上传到/home/tidb 目录下，权限为 tidb 用户，否则可能会遇到权限问题；
5. 目前，TiDB Ansible release-4.0 版本兼容 Ansible 2.5 ~ 2.7.11 


```
git clone -b $tag https://github.com/pingcap/tidb-ansible.git


scp tidb-ansible tidb@中控机IP:/home/tidb/
```


Ansible 及相关依赖的版本信息记录在 tidb-ansible/requirements.txt 文件中。

```
cd /home/tidb/tidb-ansible && \
sudo pip install -r ./requirements.txt
```

查看 Ansible 的版本
```
ansible --version

ansible 2.7.11
```


> **中控机上配置部署机器 SSH 互信及 sudo 规则**

注意事项：
1.以 tidb 用户登录中控机，然后执行以下步骤：
2.将你的部署目标机器 IP 添加到 hosts.ini 文件的 [servers] 区块下。
3.<span style='color:red'>cn.pool.ntp.org是网络上找的中国公用ntp服务不稳定，仅限测试机使用，生产服务器请使用自己的ntp服务。--[**国内常用NTP服务器地址及IP网址参考链接**](https://www.cnblogs.com/croso/p/6670039.html)</span>

```
cd /home/tidb/tidb-ansible && \
vi hosts.ini


[servers]
192.168.1.41
192.168.1.42
192.168.1.43

[all:vars]
username = tidb
ntp_server = cn.pool.ntp.org
```
执行以下命令并按提示输入部署目标机器的 root 用户密码后，将在部署目标机器上创建 tidb 用户，并配置 sudo 规则，配置中控机与部署目标机器之间的 SSH 互信。
```
ansible-playbook -i hosts.ini create_users.yml -u root -k
```

> **在部署目标机器上安装 NTP 服务**

注意事项：   
1. 以 tidb 用户登录中控机，执行以下命令；  
2. 该步骤将在部署目标机器上使用系统自带软件源联网安装并启动 NTP 服务;  
3. 服务使用安装包默认的 NTP server 列表，见配置文件 /etc/ntp.conf 中 server 参数，如果使用默认的 NTP server，你的机器需要连接外网。   
4. 为让 NTP 尽快开始同步，启动 NTP 服务前，系统会执行 ntpdate 命令，与用户在 hosts.ini 文件中指定的 ntp_server 同步日期与时间。    
5. 默认的服务器为 pool.ntp.org，也可替换为你的 NTP server。     
6. <span style='color:red'>注意：如果你的部署目标机器时间、时区设置一致，已开启 NTP 服务且在正常同步时间，此步骤可忽略。可参考如何检测 NTP 服务是否正常。</span>    

```
cd /home/tidb/tidb-ansible && \
ansible-playbook -i hosts.ini deploy_ntp.yml -u tidb -b
```


> **在部署目标机器上配置 CPUfreq 调节器模式**

注意事项：
1. 如果支持设置 performance 和 powersave 模式，为发挥CPU最大性能，推荐设置CPUfreq调节器模式置为 performance 模式；
2. 本例中系统返回 Not Available，表示当前系统不支持配置 CPUfreq，跳过该步骤即可；


查看系统支持的调节器模式
```
cpupower frequency-info --governors


analyzing CPU 0:
  available cpufreq governors: performance powersave
```


<p style='color:red'>
或者
</p>


```
cpupower frequency-info --governors


analyzing CPU 0:
  available cpufreq governors: Not Available
```

查看系统当前的 CPUfreq 调节器模式，如下面代码所示，当前配置是 powersave 模式。
```
cpupower frequency-info --policy
analyzing CPU 0:
  current policy: frequency should be within 1.20 GHz and 3.20 GHz.
                  The governor "powersave" may decide which speed to use
                  within this range.
```


修改调节器模式

可以使用 cpupower frequency-set --governor 命令单机修改；

```
cpupower frequency-set --governor performance
```

也可以使用以下命令在部署目标机器上批量设置<span style='color:red'>  （推荐使用）</span>；
```
ansible -i hosts.ini all -m shell -a "cpupower frequency-set --governor performance" -u tidb -b
```


> **在部署目标机器上添加数据盘 ext4 文件系统挂载参数**


1. 使用 root 用户登录目标机器;
2. 将部署目标机器数据盘格式化成 ext4 文件系统;
3. 挂载时添加 nodelalloc 和 noatime 挂载参数;
4. nodelalloc 是必选参数，否则 Ansible 安装时检测无法通过,noatime 是可选建议参数;
5. 如果数据盘已经格式化成ext4并挂载，可先执行 umount,编辑 /etc/fstab 文件，添加挂载参数后重新挂载。
6. 使用 lsblk 命令查看分区的设备号：对于 nvme 磁盘（固态硬盘），生成的分区设备号一般为 nvme0n1p1；对于普通磁盘（例如 /dev/sdb），生成的的分区设备号一般为 sdb1。


<span style='color:red'>
以 /dev/nvme0n1 数据盘为例，具体操作步骤如下：
</span>

查看数据盘;
```
fdisk -l
Disk /dev/nvme0n1: 1000 GB
```

创建分区表;
```
parted -s -a optimal /dev/nvme0n1 mklabel gpt -- mkpart primary ext4 1 -1
```



格式化文件系统。
```
mkfs.ext4 /dev/nvme0n1p1
```
查看数据盘分区 UUID。
本例中 nvme0n1p1 的 UUID 为 c51eb23b-195c-4061-92a9-3fad812cc12f。
```
lsblk -f
NAME    FSTYPE LABEL UUID                                 MOUNTPOINT
sda
├─sda1  ext4         237b634b-a565-477b-8371-6dff0c41f5ab /boot
├─sda2  swap         f414c5c0-f823-4bb1-8fdf-e531173a72ed
└─sda3  ext4         547909c1-398d-4696-94c6-03e43e317b60 /
sr0
nvme0n1
└─nvme0n1p1 ext4         c51eb23b-195c-4061-92a9-3fad812cc12f
```

编辑 /etc/fstab 文件，添加 nodelalloc 挂载参数。
```
vi /etc/fstab
UUID=c51eb23b-195c-4061-92a9-3fad812cc12f /data1 ext4 defaults,nodelalloc,noatime 0 2
```
挂载数据盘。
```
mkdir /data1 && \
mount -a
```

执行以下命令，如果文件系统为 ext4，并且挂载参数中包含 nodelalloc，则表示已生效。
```
mount -t ext4
/dev/nvme0n1p1 on /data1 type ext4 (rw,noatime,nodelalloc,data=ordered)
```



#### 正式开始部署

> **编辑 inventory.ini 文件分配机器资源**


注意事项：

1. 以 tidb 用户登录中控机，编辑 /home/tidb/tidb-ansible/inventory.ini 文件为 TiDB 集群分配机器资源。   
2. 一个标准的 TiDB 集群需要 6 台机器：2 个 TiDB 实例，3 个 PD 实例，3 个 TiKV 实例,至少需部署 3 个 TiKV 实例。    
3. 不推荐将 TiKV 实例与 TiDB 或 PD 实例混合部署在同一台机器上<span style="color:red">----本例测试机采用这种部署方案！！！</span>   
4. 将第一台 TiDB 机器同时用作监控机。    
5. 请使用内网 IP 来部署集群，如果部署目标机器 SSH 端口非默认的 22 端口，需添加 ansible_port 变量，如 TiDB1 ansible_host=172.16.10.1 ansible_port=5555。
6. 如果是 ARM 架构的机器，需要将 cpu_architecture 改为 arm64。   
7. 默认情况下，建议在每个 TiKV 节点上仅部署一个 TiKV 实例，以提高性能。但是，如果你的 TiKV 部署机器的 CPU 和内存配置是部署建议的两倍或以上，并且一个节点拥有两块 SSD 硬盘或者单块 SSD 硬盘的容量大于 2 TB，则可以考虑部署两实例，但不建议部署两个以上实例。   

执行以下命令，如果所有 server 均返回 tidb，表示 SSH 互信配置成功：
```
ansible -i inventory.ini all -m shell -a 'whoami'
```

执行以下命令，如果所有 server 均返回 root，表示 tidb 用户 sudo 免密码配置成功。
```
ansible -i inventory.ini all -m shell -a 'whoami' -b
```


> **部署 TiDB 集群**

1. ansible-playbook 执行 Playbook 时，默认并发为 5;  
2. 部署目标机器较多时，可添加 -f 参数指定并发数，例如 ansible-playbook deploy.yml -f 10。  
3. 默认使用tidb 用户作为服务运行用户,需在tidb-ansible/inventory.ini 文件中，确认 ansible_user = tidb。  
4. 不要将 ansible_user 设置为 root 用户，因为 tidb-ansible 限制了服务以普通用户运行。  
  
```
Connection
ssh via normal user
ansible_user = tidb
```

执行 local_prepare.yml playbook，联网下载 TiDB binary 至中控机。
```
ansible-playbook local_prepare.yml
```



<span style='color:red'>如果采用实验环境很难满足TiDB的硬件要求（节点CPU核心数最低8核，内存最低16000MB），可以采用如下关闭自检的方式搭建，生产环境不要使用！</span>

```
- name: check system
  hosts: all
  any_errors_fatal: true
  roles:
    - check_system_static
    #- { role: check_system_optional, when: not dev_mode|default(false) }

- name: tikv_servers machine benchmark
  hosts: tikv_servers
  gather_facts: false
  roles:
    #- { role: machine_benchmark, when: not dev_mode|default(false) }

```

> **bootstrap.yml初始化环境**



初始化系统环境，修改内核参数。
```
ansible-playbook bootstrap.yml
```

> **deploy.yml部署任务**




部署 TiDB 集群软件。
```
ansible-playbook deploy.yml
```

> **start.yml启动集群**


启动 TiDB 集群。
```
ansible-playbook start.yml
```

#### 测试集群部署
TiDB 兼容 MySQL，因此可使用 MySQL 客户端直接连接 TiDB。推荐配置负载均衡以提供统一的 SQL 接口。

使用 MySQL 客户端连接 TiDB 集群。TiDB 服务的默认端口为 4000。

```
mysql -u root -h 172.16.10.1 -P 4000
```








