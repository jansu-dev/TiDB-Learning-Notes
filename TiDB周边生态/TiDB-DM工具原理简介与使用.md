# TiDB-DM工具原理简介与使用

## 安装MySQL5.7
```shell
# 下载
wget https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm


#安装mysql源
 yum localinstall mysql57-community-release-el7-11.noarch.rpm


# 检查是否成功
yum repolist enabled | grep "mysql.*-community.*"
yum install mysql-server
systemctl start mysqld
systemctl status mysqld
systemctl enable mysqld

# 重载所有修改过的配置文件
systemctl daemon-reload
grep 'temporary password' /var/log/mysqld.log
mysql -uroot -p

# 修改密码，一开始输入密码尽量复杂点，字符、大小写字母、数字都要有

ALTER USER 'root'@'localhost' IDENTIFIED BY 'MyNewPass4!'

# 现在可以回到第3步，设置一个简单的密码了。
SHOW VARIABLES LIKE 'validate_password%';
set global validate_password_policy=LOW; 
set global validate_password_length=6; 

# 这个密码可以和客户端密码不一致，但最好一致。
ALTER USER 'root'@'localhost' IDENTIFIED BY '123123';
grant all privileges on *.* to root@'%' identified by '123123' with grant option;


firewall-cmd --state
firewall-cmd --zone=public --add-port=3306/tcp --permanent
## zone -- 作用域
## add-port=80/tcp -- 添加端口，格式为：端口/通讯协议
## permanent -- 永久生效，没有此参数重启后失效
## 开启3306端口后，workbench或naivcat 就能连接到MySQL数据库了
firewall-cmd --reload
```

## 部署DM

```shell
[tidb@tiup-tidb41 dumpling_dir]$ tiup install dm

[tidb@tiup-tidb41 dumpling_dir]$ tiup list --installed
Available components:
Name      Owner    Description
----      -----    -----------
dm        pingcap  Data Migration Platform manager
dm-master  pingcap  dm-master component of Data Migration Platform
dm-worker  pingcap  dm-worker component of Data Migration Platform

......
......



[tidb@tiup-tidb41 ~]$ mkdir dm
[tidb@tiup-tidb41 ~]$ cd dm/
[tidb@tiup-tidb41 dm]$ ll
total 0
[tidb@tiup-tidb41 dm]$ vi topology.yaml 
[tidb@tiup-tidb41 dm]$ tiup dm deploy dm-test v2.0.1 /home/tidb/dm/topology.yaml --user root -p
Starting component `dm`: /home/tidb/.tiup/components/dm/v1.3.1/tiup-dm deploy dm-test v2.0.1 /home/tidb/dm/topology.yaml --user root -p
Please confirm your topology:
Cluster type:    dm
Cluster name:    dm-test
Cluster version: v2.0.1
Type       Host            Ports      OS/Arch       Directories
----       ----            -----      -------       -----------
dm-master  192.168.169.41  8261/8291  linux/x86_64  /data/tidb-deploy/dm/dm-master-8261,/data/tidb-data/dm/dm-master-8261
dm-master  192.168.169.42  8261/8291  linux/x86_64  /data/tidb-deploy/dm/dm-master-8261,/data/tidb-data/dm/dm-master-8261
dm-master  192.168.169.43  8261/8291  linux/x86_64  /data/tidb-deploy/dm/dm-master-8261,/data/tidb-data/dm/dm-master-8261
dm-worker  192.168.169.41  8262       linux/x86_64  /data/tidb-deploy/dm/dm-worker-8262,/data/tidb-data/dm/dm-worker-8262
dm-worker  192.168.169.42  8262       linux/x86_64  /data/tidb-deploy/dm/dm-worker-8262,/data/tidb-data/dm/dm-worker-8262
dm-worker  192.168.169.43  8262       linux/x86_64  /data/tidb-deploy/dm/dm-worker-8262,/data/tidb-data/dm/dm-worker-8262
Attention:
    1. If the topology is not what you expected, check your yaml file.
    2. Please confirm there is no port/directory conflicts in same host.
Do you want to continue? [y/N]:  y
Input SSH password: 
+ Generate SSH keys ... Done
+ Download TiDB components
  - Download dm-master:v2.0.1 (linux/amd64) ... Done
  - Download dm-worker:v2.0.1 (linux/amd64) ... Done
+ Initialize target host environments
  - Prepare 192.168.169.41:22 ... Done
  - Prepare 192.168.169.42:22 ... Done
  - Prepare 192.168.169.43:22 ... Done
+ Copy files
  - Copy dm-master -> 192.168.169.41 ... Done
  - Copy dm-master -> 192.168.169.42 ... Done
  - Copy dm-master -> 192.168.169.43 ... Done
  - Copy dm-worker -> 192.168.169.41 ... Done
  - Copy dm-worker -> 192.168.169.42 ... Done
  - Copy dm-worker -> 192.168.169.43 ... Done
Cluster `dm-test` deployed successfully, you can start it with command: `tiup dm start dm-test`

[tidb@tiup-tidb41 dm]$ tiup dm list
Starting component `dm`: /home/tidb/.tiup/components/dm/v1.3.1/tiup-dm list
Name     User  Version  Path                                          PrivateKey
----     ----  -------  ----                                          ----------
dm-test  tidb  v2.0.1   /home/tidb/.tiup/storage/dm/clusters/dm-test  /home/tidb/.tiup/storage/dm/clusters/dm-test/ssh/id_rsa


[tidb@tiup-tidb41 dm]$ tiup dm display dm-test
Starting component `dm`: /home/tidb/.tiup/components/dm/v1.3.1/tiup-dm display dm-test
Cluster type:       dm
Cluster name:       dm-test
Cluster version:    v2.0.1
SSH type:           builtin
ID                   Role       Host            Ports      OS/Arch       Status  Data Dir                           Deploy Dir
--                   ----       ----            -----      -------       ------  --------                           ----------
192.168.169.41:8261  dm-master  192.168.169.41  8261/8291  linux/x86_64  Down    /data/tidb-data/dm/dm-master-8261  /data/tidb-deploy/dm/dm-master-8261
192.168.169.42:8261  dm-master  192.168.169.42  8261/8291  linux/x86_64  Down    /data/tidb-data/dm/dm-master-8261  /data/tidb-deploy/dm/dm-master-8261
192.168.169.43:8261  dm-master  192.168.169.43  8261/8291  linux/x86_64  Down    /data/tidb-data/dm/dm-master-8261  /data/tidb-deploy/dm/dm-master-8261
192.168.169.41:8262  dm-worker  192.168.169.41  8262       linux/x86_64  N/A     /data/tidb-data/dm/dm-worker-8262  /data/tidb-deploy/dm/dm-worker-8262
192.168.169.42:8262  dm-worker  192.168.169.42  8262       linux/x86_64  N/A     /data/tidb-data/dm/dm-worker-8262  /data/tidb-deploy/dm/dm-worker-8262
192.168.169.43:8262  dm-worker  192.168.169.43  8262       linux/x86_64  N/A     /data/tidb-data/dm/dm-worker-8262  /data/tidb-deploy/dm/dm-worker-8262
Total nodes: 6
[tidb@tiup-tidb41 dm]$ tiup dm start dm-test
Starting component `dm`: /home/tidb/.tiup/components/dm/v1.3.1/tiup-dm start dm-test
Starting cluster dm-test...
+ [ Serial ] - SSHKeySet: privateKey=/home/tidb/.tiup/storage/dm/clusters/dm-test/ssh/id_rsa, publicKey=/home/tidb/.tiup/storage/dm/clusters/dm-test/ssh/id_rsa.pub
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.43
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.41
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.42
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.41
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.43
+ [Parallel] - UserSSH: user=tidb, host=192.168.169.42
+ [ Serial ] - StartCluster
Starting component dm-master
	Starting instance dm-master 192.168.169.41:8261
	Starting instance dm-master 192.168.169.43:8261
	Starting instance dm-master 192.168.169.42:8261
	Start dm-master 192.168.169.42:8261 success
	Start dm-master 192.168.169.43:8261 success
	Start dm-master 192.168.169.41:8261 success
Starting component dm-worker
	Starting instance dm-worker 192.168.169.43:8262
	Starting instance dm-worker 192.168.169.41:8262
	Starting instance dm-worker 192.168.169.42:8262
	Start dm-worker 192.168.169.42:8262 success
	Start dm-worker 192.168.169.41:8262 success
	Start dm-worker 192.168.169.43:8262 success
Started cluster `dm-test` successfully
[tidb@tiup-tidb41 dm]$ tiup dm display dm-test
Starting component `dm`: /home/tidb/.tiup/components/dm/v1.3.1/tiup-dm display dm-test
Cluster type:       dm
Cluster name:       dm-test
Cluster version:    v2.0.1
SSH type:           builtin
ID                   Role       Host            Ports      OS/Arch       Status     Data Dir                           Deploy Dir
--                   ----       ----            -----      -------       ------     --------                           ----------
192.168.169.41:8261  dm-master  192.168.169.41  8261/8291  linux/x86_64  Healthy    /data/tidb-data/dm/dm-master-8261  /data/tidb-deploy/dm/dm-master-8261
192.168.169.42:8261  dm-master  192.168.169.42  8261/8291  linux/x86_64  Healthy|L  /data/tidb-data/dm/dm-master-8261  /data/tidb-deploy/dm/dm-master-8261
192.168.169.43:8261  dm-master  192.168.169.43  8261/8291  linux/x86_64  Healthy    /data/tidb-data/dm/dm-master-8261  /data/tidb-deploy/dm/dm-master-8261
192.168.169.41:8262  dm-worker  192.168.169.41  8262       linux/x86_64  Free       /data/tidb-data/dm/dm-worker-8262  /data/tidb-deploy/dm/dm-worker-8262
192.168.169.42:8262  dm-worker  192.168.169.42  8262       linux/x86_64  Free       /data/tidb-data/dm/dm-worker-8262  /data/tidb-deploy/dm/dm-worker-8262
192.168.169.43:8262  dm-worker  192.168.169.43  8262       linux/x86_64  Free       /data/tidb-data/dm/dm-worker-8262  /data/tidb-deploy/dm/dm-worker-8262
```


上游数据准备

```
create database user;

create database store;

create database log;

use user;

create table information (id int,name varchar(20));

create table log (id int,name varchar(20));

use log;

create table messages(id int,name varchar(20));



# 192.168.169.44

use store;

create table store_bj (id int primary key,name varchar(20));

create table store_tj (id int primary key,name varchar(20));

insert into store.store_bj values (1,'store_bj_01'),(2,'store_bj_02');

insert into store.store_tj values (1,'store_tj_01'),(2,'store_tj_02');

# 192.168.169.45

use store;

create table store_sh (id int primary key,name varchar(20));

create table store_sz (id int primary key,name varchar(20));

insert into store.store_sh values (1,'store_sh_01'),(2,'store_sh_02');

insert into store.store_sz values (1,'store_suzhou_01'),(2,'store_suzhou_02');

# 192.168.169.46

use store;

create table store_gz (id int primary key,name varchar(20));

create table store_sz (id int primary key,name varchar(20));

insert into store.store_gz values (1,'store_gz_01'),(2,'store_gz_02');

insert into store.store_sz values (1,'store_shenzhen_01'),(2,'store_shenzhen_02');


```

下游数据准备

```
create database user_north;

create database user_east;

create database user_south;

use user_north;

create table information (id int primary key,name varchar(20));

create table log (id int primary key,name varchar(20));

use user_east;

create table information (id int primary key,name varchar(20));

create table log (id int primary key,name varchar(20));

use user_south;

create table information (id int primary key,name varchar(20));

create table log (id int primary key,name varchar(20));


create database store;

use store;


create table store_bj (id int primary key,name varchar(20));
create table store_tj (id int primary key,name varchar(20));
create table store_sh (id int primary key,name varchar(20));
create table store_gz (id int primary key,name varchar(20));
create table store_suzhou   (id int primary key,name varchar(20));
create table store_shenzhen (id int primary key,name varchar(20));

```


创建source对应的worker
```
[tidb@tiup-tidb41 conf]$ tiup dmctl --master-addr=192.168.169.41:8261 operate-source create source1.yaml 
Starting component `dmctl`: /home/tidb/.tiup/components/dmctl/v2.0.1/dmctl/dmctl --master-addr=192.168.169.41:8261 operate-source create source1.yaml
{
    "result": true,
    "msg": "",
    "sources": [
        {
            "result": true,
            "msg": "",
            "source": "mysql-replica-01",
            "worker": "dm-192.168.169.41-8262"
        }
    ]
}


[tidb@tiup-tidb41 conf]$ tiup dmctl --master-addr=192.168.169.41:8261 operate-source create source2.yaml 
Starting component `dmctl`: /home/tidb/.tiup/components/dmctl/v2.0.1/dmctl/dmctl --master-addr=192.168.169.41:8261 operate-source create source2.yaml
{
    "result": true,
    "msg": "",
    "sources": [
        {
            "result": true,
            "msg": "",
            "source": "mysql-replica-02",
            "worker": "dm-192.168.169.42-8262"
        }
    ]
}


[tidb@tiup-tidb41 conf]$ tiup dmctl --master-addr=192.168.169.41:8261 operate-source create source3.yaml 
Starting component `dmctl`: /home/tidb/.tiup/components/dmctl/v2.0.1/dmctl/dmctl --master-addr=192.168.169.41:8261 operate-source create source3.yaml
{
    "result": true,
    "msg": "",
    "sources": [
        {
            "result": true,
            "msg": "",
            "source": "mysql-replica-03",
            "worker": "dm-192.168.169.43-8262"
        }
    ]
}











[tidb@tiup-tidb41 conf]$ tiup dmctl --master-addr=192.168.169.41:8261 list-member
Starting component `dmctl`: /home/tidb/.tiup/components/dmctl/v2.0.1/dmctl/dmctl --master-addr=192.168.169.41:8261 list-member
{
    "result": true,
    "msg": "",
    "members": [
        {
            "leader": {
                "msg": "",
                "name": "dm-192.168.169.41-8261",
                "addr": "192.168.169.41:8261"
            }
        },
        {
            "master": {
                "msg": "",
                "masters": [
                    {
                        "name": "dm-192.168.169.41-8261",
                        "memberID": "11955134185808625835",
                        "alive": true,
                        "peerURLs": [
                            "http://192.168.169.41:8291"
                        ],
                        "clientURLs": [
                            "http://192.168.169.41:8261"
                        ]
                    },
                    {
                        "name": "dm-192.168.169.42-8261",
                        "memberID": "16647128463965627029",
                        "alive": true,
                        "peerURLs": [
                            "http://192.168.169.42:8291"
                        ],
                        "clientURLs": [
                            "http://192.168.169.42:8261"
                        ]
                    },
                    {
                        "name": "dm-192.168.169.43-8261",
                        "memberID": "7578209210746128387",
                        "alive": true,
                        "peerURLs": [
                            "http://192.168.169.43:8291"
                        ],
                        "clientURLs": [
                            "http://192.168.169.43:8261"
                        ]
                    }
                ]
            }
        },
        {
            "worker": {
                "msg": "",
                "workers": [
                    {
                        "name": "dm-192.168.169.41-8262",
                        "addr": "192.168.169.41:8262",
                        "stage": "bound",
                        "source": "mysql-replica-01"
                    },
                    {
                        "name": "dm-192.168.169.42-8262",
                        "addr": "192.168.169.42:8262",
                        "stage": "bound",
                        "source": "mysql-replica-02"
                    },
                    {
                        "name": "dm-192.168.169.43-8262",
                        "addr": "192.168.169.43:8262",
                        "stage": "bound",
                        "source": "mysql-replica-03"
                    }
                ]
            }
        }
    ]
}

```


开始任务
```
[tidb@tiup-tidb41 dm]$ tiup dmctl -master-addr 192.168.169.42:8261 start-task task.yml


```


## 参考文章

[https://www.bookstack.cn/read/tidb-data-migration-1.0-zh/zh-get-started.md](https://www.bookstack.cn/read/tidb-data-migration-1.0-zh/zh-get-started.md)

[]