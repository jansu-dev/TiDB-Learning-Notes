# TiDB-中控机Ansible部署修改集群配置滚动升级


### 核心步骤

1.中控机（tidb01-41）修改集群配置
2.中控机执行rolling-update滚动更新
3.TiKV任意子节点部署目录检查配置

### 中控机（tidb01-41）修改集群配置
```
[tidb@tidb01-41 tidb-ansible]$ pwd
/home/tidb/soft/tidb-ansible
[tidb@tidb01-41 tidb-ansible]$ vi conf/tidb.yml 

......
......
log:
  # Log level: debug, info, warn, error, fatal.
  # level: "info"
  level: "debug"
......
......

```


### 中控机执行rolling-update滚动更新


```shell
[tidb@tidb01-41 soft]$ cd tidb-ansible/
[tidb@tidb01-41 tidb-ansible]$ ansible-playbook rolling_update.yml --tags=tidb

PLAY [check config locally] *********************************************************************************************************************************

TASK [check_config_static : Ensure only one monitoring host exists] *****************************************************************************************

TASK [check_config_static : Ensure monitored_servers exists] ************************************************************************************************
......
......
......

PLAY RECAP **************************************************************************************************************************************************
192.168.1.41               : ok=34   changed=6    unreachable=0    failed=0   
192.168.1.42               : ok=8    changed=0    unreachable=0    failed=0   
192.168.1.43               : ok=33   changed=6    unreachable=0    failed=0   
localhost                  : ok=1    changed=0    unreachable=0    failed=0   

Congrats! All goes well. :-)

```


### TiKV任意子节点部署目录检查配置

```
[root@tidb03-43 deploy]# ip addr |grep ens33
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    inet 192.168.1.43/24 brd 192.168.1.255 scope global noprefixroute ens33
[root@tidb03-43 deploy]# pwd
/data/tidb/deploy
[root@tidb03-43 deploy]# cat conf/tidb.toml |grep debug
level = "debug"

```