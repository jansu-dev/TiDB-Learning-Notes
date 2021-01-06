# TiDB-单机多TiKV部署

## summary
> - [配置inventory的TiKV部分](#配置inventory的TiKV部分)  
>   - [TiKV分层架构](#TiKV分层架构)

[tikv_servers]
TiKV1-1 ansible_host=172.16.10.4 deploy_dir=/data1/deploy tikv_port=20171 tikv_status_port=20181 labels="host=tikv1"
TiKV1-2 ansible_host=172.16.10.4 deploy_dir=/data2/deploy tikv_port=20172 tikv_status_port=20182 labels="host=tikv1"
TiKV2-1 ansible_host=172.16.10.5 deploy_dir=/data1/deploy tikv_port=20171 tikv_status_port=20181 labels="host=tikv2"
TiKV2-2 ansible_host=172.16.10.5 deploy_dir=/data2/deploy tikv_port=20172 tikv_status_port=20182 labels="host=tikv2"
TiKV3-1 ansible_host=172.16.10.6 deploy_dir=/data1/deploy tikv_port=20171 tikv_status_port=20181 labels="host=tikv3"
TiKV3-2 ansible_host=172.16.10.6 deploy_dir=/data2/deploy tikv_port=20172 tikv_status_port=20182 labels="host=tikv3"














## 配置inventory的TiKV部分
[tidb@tidb01-41 tidb-ansible]$ vi inventory
使用上述命令，在tikv_servers和monitored_servers中分别追加新部署节点的IP地址；

5132bd5af713ee6e76bf91a87f58d87.png

dea88cbf26d02fa12d699d69bf343c8.png

## 中控机操作部署机建用户
执行以下命令，依据输入部署目标机器的 root 用户密码；
本例新增节点IP为192.168.1.44；

[tidb@tidb01-41 tidb-ansible]$ vi hosts 
[tidb@tidb01-41 tidb-ansible]$ cat hosts 
[servers]
192.168.1.44


[all:vars]
username = tidb
ntp_server = cn.pool.ntp.org



[tidb@tidb01-41 tidb-ansible]$ ansible-playbook -i hosts create_users.yml -u root -k
SSH password: 

PLAY [all] ***************************************************************************************************************

TASK [create user] *******************************************************************************************************
ok: [192.168.1.44]

TASK [set authorized key] ************************************************************************************************
changed: [192.168.1.44]

TASK [update sudoers file] ***********************************************************************************************
ok: [192.168.1.44]

PLAY RECAP ***************************************************************************************************************
192.168.1.44               : ok=3    changed=1    unreachable=0    failed=0   

Congrats! All goes well. :-)
## 中控机操作部署机配置ntp服务
注意：生产上应该指向自己的ntp服务器，本次测试采用了公网公用的ntp服务不稳定。

[tidb@tidb01-41 tidb-ansible]$ ansible-playbook -i hosts deploy_ntp.yml -u tidb -b

PLAY [all] ***************************************************************************************************************

TASK [get facts] *********************************************************************************************************
ok: [192.168.1.44]

TASK [RedHat family Linux distribution - make sure ntp, ntpstat have been installed] *************************************
changed: [192.168.1.44] => (item=[u'ntp'])

TASK [RedHat family Linux distribution - make sure ntpdate have been installed] ******************************************
ok: [192.168.1.44] => (item=[u'ntpdate'])

TASK [Debian family Linux distribution - make sure ntp, ntpstat have been installed] *************************************

TASK [Debian family Linux distribution - make sure ntpdate have been installed] ******************************************

TASK [RedHat family Linux distribution - make sure ntpd service has been stopped] ****************************************
ok: [192.168.1.44]

TASK [Debian family Linux distribution - make sure ntp service has been stopped] *****************************************

TASK [Adjust Time | start to adjust time with cn.pool.ntp.org] ***********************************************************
changed: [192.168.1.44]

TASK [RedHat family Linux distribution - make sure ntpd service has been started] ****************************************
changed: [192.168.1.44]

TASK [Debian family Linux distribution - Make sure ntp service has been started] *****************************************

PLAY RECAP ***************************************************************************************************************
192.168.1.44               : ok=6    changed=3    unreachable=0    failed=0   

Congrats! All goes well. :-)
中控及操作部署机设置CPU模式
调整CPU模式，如果同本文出现一样的报错，说明此版本的操作系统不支持CPU模式修改，可直接跳过。

[tidb@tidb01-41 tidb-ansible]$ ansible -i hosts all -m shell -a "cpupower frequency-set --governor performance" -u tidb -b
192.168.1.44 | FAILED | rc=237 >>
Setting cpu: 0
Error setting new values. Common errors:
- Do you have proper administration rights? (super-user?)
- Is the governor you requested available and modprobed?
- Trying to set an invalid policy?
- Trying to set a specific frequency, but userspace governor is not available,
   for example because of hardware which cannot be set to a specific frequency
   or because the userspace governor isn't loaded?non-zero return code

## 执行bootstrap.yml创建模板
[tidb@tidb01-41 tidb-ansible]$ ansible-playbook bootstrap.yml -l 192.168.1.44

PLAY [initializing deployment target] ************************************************************************************
skipping: no hosts matched

PLAY [check node config] *************************************************************************************************

TASK [pre-ansible : disk space check - fail when disk is full] ***********************************************************
ok: [192.168.1.44]

......
......

PLAY RECAP ***************************************************************************************************************
192.168.1.44               : ok=21   changed=0    unreachable=0    failed=0   

Congrats! All goes well. :-)
执行start.yml启动tikv服务
Congrats! All goes well. :-)
[tidb@tidb01-41 tidb-ansible]$ ansible-playbook start.yml -l 192.168.1.44

PLAY [check config locally] **********************************************************************************************
skipping: no hosts matched

......
......

PLAY RECAP ***************************************************************************************************************
192.168.1.44               : ok=14   changed=3    unreachable=0    failed=0   

Congrats! All goes well. :-)
执行rolling-update.yml滚动更新
[tidb@tidb01-41 tidb-ansible]$ ansible-playbook rolling_update_monitor.yml --tags=prometheus

PLAY [check config locally] **********************************************************************************************

TASK [check_config_static : Ensure only one monitoring host exists] ******************************************************

......
......

PLAY RECAP ***************************************************************************************************************
192.168.1.41               : ok=3    changed=0    unreachable=0    failed=0   
192.168.1.42               : ok=25   changed=8    unreachable=0    failed=0   
192.168.1.43               : ok=3    changed=0    unreachable=0    failed=0   
192.168.1.44               : ok=3    changed=0    unreachable=0    failed=0   
localhost                  : ok=7    changed=4    unreachable=0    failed=0   

Congrats! All goes well. :-)
pd-ctl命令行验证是否成功
可以使用stores show命令可以在pd-ctl交互式命令行中看到；
"count"：4 表示当前tikv有四个节点，说明tikv节点已经添加成功了。

[tidb@tidb01-41 tidb-ansible]$ resources/bin/pd-ctl -u http://192.168.1.41:2379 -i
» stores show
{
  "count": 4,
  "stores": [
    {
      "store": {
        "id": 2001,
        "address": "192.168.1.44:20160",
        "version": "3.0.1",
        "state_name": "Up"
      },
      "status": {
        "capacity": "17 GiB",
        "available": "15 GiB",
        "leader_count": 1,
        "leader_weight": 1,
        "leader_score": 1,
        "leader_size": 1,
        "region_count": 20,
        "region_weight": 1,
        "region_score": 20,
        "region_size": 20,
        "start_ts": "2020-12-27T01:53:06-05:00",
        "last_heartbeat_ts": "2020-12-27T01:59:36.260710913-05:00",
        "uptime": "6m30.260710913s"
      }
    },
    {
      "store": {
        "id": 1,
        "address": "192.168.1.41:20160",
        "version": "3.0.1",
        "state_name": "Up"
      },
      "status": {
        "capacity": "17 GiB",
        "available": "3.4 GiB",
        "leader_weight": 1,
        "region_weight": 1,
        "region_score": 1073738348.2304688,
        "start_ts": "2020-12-27T01:02:52-05:00",
        "last_heartbeat_ts": "2020-12-27T01:59:34.041233812-05:00",
        "uptime": "56m42.041233812s"
      }
    },
    {
      "store": {
        "id": 4,
        "address": "192.168.1.43:20160",
        "version": "3.0.1",
        "state_name": "Up"
      },
      "status": {
        "capacity": "17 GiB",
        "available": "14 GiB",
        "leader_count": 9,
        "leader_weight": 1,
        "leader_score": 9,
        "leader_size": 9,
        "region_count": 20,
        "region_weight": 1,
        "region_score": 20,
        "region_size": 20,
        "start_ts": "2020-12-27T01:01:12-05:00",
        "last_heartbeat_ts": "2020-12-27T01:59:32.975729011-05:00",
        "uptime": "58m20.975729011s"
      }
    },
    {
      "store": {
        "id": 5,
        "address": "192.168.1.42:20160",
        "version": "3.0.1",
        "state_name": "Up"
      },
      "status": {
        "capacity": "17 GiB",
        "available": "13 GiB",
        "leader_count": 10,
        "leader_weight": 1,
        "leader_score": 10,
        "leader_size": 10,
        "region_count": 20,
        "region_weight": 1,
        "region_score": 20,
        "region_size": 20,
        "start_ts": "2020-12-27T01:01:12-05:00",
        "last_heartbeat_ts": "2020-12-27T01:59:33.014833325-05:00",
        "uptime": "58m21.014833325s"
      }
    }
  ]
}

» exit
[tidb@tidb01-41 tidb-ansible]$
更新普罗米修斯后：

使用普罗米修斯的Grafana图形化监控界面也可以看到当前的tikv集群也已经加入新节点成功了。



