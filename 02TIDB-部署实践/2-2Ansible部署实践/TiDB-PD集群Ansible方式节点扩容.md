# TiDB-PD集群Ansible方式节点扩容
时间：2020-12-21


### 配置inventory.ini新节点IP信息
```
......
......

[pd_servers]
192.168.1.41
192.168.1.42
192.168.1.43
192.168.1.44

......
......

# node_exporter and blackbox_exporter servers
[monitored_servers]
192.168.1.41
192.168.1.42
192.168.1.43
192.168.1.44

......
......

```


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
......
......

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








### 执行bootstrap.yml生成模板文件
```
[tidb@tidb01-41 tidb-ansible]$ 
[tidb@tidb01-41 tidb-ansible]$ vi inventory.ini 
[tidb@tidb01-41 tidb-ansible]$ ansible-playbook bootstrap.yml -l 192.168.1.44

PLAY [initializing deployment target] ************************************************************************************
skipping: no hosts matched

......
......

Congrats! All goes well. :-)

```


### 执行deploy.yml正式部署新节点
```
[tidb@tidb01-41 tidb-ansible]$ vi inventory.ini 
[tidb@tidb01-41 tidb-ansible]$ ansible-playbook bootstrap.yml -l 192.168.1.44

PLAY [initializing deployment target] ************************************************************************************
skipping: no hosts matched

......
......

Congrats! All goes well. :-)
```


### 滚动更新普罗米修斯
```
[tidb@tidb01-41 tidb-ansible]$ vi inventory.ini 
[tidb@tidb01-41 tidb-ansible]$ ansible-playbook rolling_update_monitor.yml --tags=prometheus

PLAY [check config locally] ****************************************************************************************************

......
......

PLAY RECAP *********************************************************************************************************************
192.168.1.41               : ok=3    changed=0    unreachable=0    failed=0   
192.168.1.42               : ok=25   changed=8    unreachable=0    failed=0   
192.168.1.43               : ok=3    changed=0    unreachable=0    failed=0   
localhost                  : ok=7    changed=4    unreachable=0    failed=0   

Congrats! All goes well. :-)
```

### 基于Grafana可视化界面验证

![39368d20da884d3e70484891aa58aae.png](http://cdn.lifemini.cn/dbblog/20201227/b5ceba7b9807484b9f385d382d5ab325.png)



