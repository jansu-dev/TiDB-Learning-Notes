# TiDB-TiDB集群Ansible方式节点扩容
时间：2020-12-22

### 配置互信和sudo规则

对于TiDB集群节点的扩容操作，首先修改hosts.ini文件；


```
[tidb@tidb01-41 tidb-ansible]$ vi hosts.ini 
[tidb@tidb01-41 tidb-ansible]$ cat hosts.ini 
[servers]
192.168.1.44

[all:vars]
username = tidb
ntp_server = cn.pool.ntp.org

```

![029282675fd15d6d77eb0e48d227694.png](http://cdn.lifemini.cn/dbblog/20201227/fcec4328a4294836b6d60223c1d6ce37.png)



### 中控机操作部署机建用户

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

Congrats! All goes well. :-)

```

### 中控机操作部署机配置ntp服务

***注意：生产上应该指向自己的ntp服务器，本次测试采用了公网公用的ntp服务不稳定。***

```
[tidb@tidb01-41 tidb-ansible]$ ansible-playbook -i hosts.ini deploy_ntp.yml -u tidb -b

PLAY [all] ***************************************************************************************************************

......
......

Congrats! All goes well. :-)
```




### 中控及操作部署机设置CPU模式


调整CPU模式，如果同本文出现一样的报错，说明此版本的操作系统不支持CPU模式修改，可直接跳过。

```
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



### 执行bootstrap.yml生成模板


```

[tidb@tidb01-41 tidb-ansible]$ ansible-playbook bootstrap.yml -l 192.168.1.44

PLAY [initializing deployment target] ************************************************************************************

......
......
......

Congrats! All goes well. :-)
```

### 执行deploy.yml开始部署



```
[tidb@tidb01-41 tidb-ansible]$ ansible-playbook bootstrap.yml -l 192.168.1.44

PLAY [initializing deployment target] ************************************************************************************
skipping: no hosts matched

.....
.....

Congrats! All goes well. :-)
```


### 节点软件部署目录验证
```
[root@tidb04-44 ~]# cd /data/tidb/deploy/
[root@tidb04-44 deploy]# ll
total 0
drwxr-xr-x.  2 tidb tidb   6 Dec 27 01:18 backup
drwxr-xr-x.  2 tidb tidb  25 Dec 27 01:18 bin
drwxr-xr-x.  2 tidb tidb  23 Dec 27 01:18 conf
drwxr-xr-x.  2 tidb tidb   6 Dec 27 01:18 log
drwxr-xr-x.  2 tidb tidb  66 Dec 27 01:18 scripts
drwxrwxr-x. 13 tidb tidb 211 Sep 16  2018 spark

```

### 执行start.yml开启tidb服务

```
[tidb@tidb01-41 tidb-ansible]$ ansible-playbook start.yml -l 192.168.1.44

PLAY [check config locally] **********************************************************************************************
skipping: no hosts matched

......
......

Congrats! All goes well. :-)
```


### TiDB节点登陆验证

登陆验证成功

```
[tidb@tidb01-41 tidb-ansible]$ mysql -u root -h 192.168.1.44 -P 4000
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 2
Server version: 5.7.25-TiDB-v3.0.1 MySQL Community Server (Apache License 2.0)

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MySQL [(none)]> 
```


### 更新普罗米修斯

普罗米修斯是以主动pull的方式，从相应节点拉去所需要的信息；
因此，如果不手动更新，普罗米修斯便不会手动去拉取相应信息，无法达到监控的目的。


更新普罗米修斯前：

![98796cd631809c0bb316b105822930c.png](http://cdn.lifemini.cn/dbblog/20201227/46d3e18a3fee4a5c815b5dca2aae49e6.png)

普罗米修斯是通过pull的方式去新的tidb节点拉取的。

```
[tidb@tidb01-41 tidb-ansible]$ ansible-playbook rolling_update_monitor.yml --tags=prometheus

PLAY [check config locally] **********************************************************************************************

......
......


PLAY RECAP ***************************************************************************************************************
192.168.1.41               : ok=3    changed=0    unreachable=0    failed=0   
192.168.1.42               : ok=25   changed=8    unreachable=0    failed=0   
192.168.1.43               : ok=3    changed=0    unreachable=0    failed=0   
192.168.1.44               : ok=3    changed=0    unreachable=0    failed=0   
localhost                  : ok=7    changed=4    unreachable=0    failed=0   

Congrats! All goes well. :-)

```

更新普罗米修斯后：

![0d15b132201b1d48c858b674ea2b923.png](http://cdn.lifemini.cn/dbblog/20201227/486672e3306b41edb86b698d36d786be.png)


可以看到节点已经更新完毕。




