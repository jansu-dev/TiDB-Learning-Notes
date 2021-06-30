# TiDB-TiKV集群Ansible方式节点缩容
时间：2020-12-22

### pd提出TiKV节点

首先，登录pd-ctl交互式命令行，在PD集群中声明将该TiKV节点踢出TiKV集群；
而后，PD集群会将存在与被提出集群节点上的Region调度到其他机器上；
但应在命令行上为Offline状态，注意此时的offline状态并非是已调度完毕状态，而是正在调度状态；
真正的调度完成状态为tombstone（墓碑）状体，反应到命令上为该id消失。

```
[tidb@tidb01-41 tidb-ansible]$ resources/bin/pd-ctl -u http://192.168.1.41:2379 -i
» store delete 2001
Success!
» stores show
{
  "count": 4,
  "stores": [
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
        "region_score": 1073738348.6953125,
        "start_ts": "2020-12-27T01:02:52-05:00",
        "last_heartbeat_ts": "2020-12-27T02:01:44.059741115-05:00",
        "uptime": "58m52.059741115s"
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
        "last_heartbeat_ts": "2020-12-27T02:01:42.99596895-05:00",
        "uptime": "1h0m30.99596895s"
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
        "last_heartbeat_ts": "2020-12-27T02:01:43.033315794-05:00",
        "uptime": "1h0m31.033315794s"
      }
    },
    {
      "store": {
        "id": 2001,
        "address": "192.168.1.44:20160",
        "state": 1,
        "version": "3.0.1",
        "state_name": "Offline"
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
        "last_heartbeat_ts": "2020-12-27T02:01:46.276789545-05:00",
        "uptime": "8m40.276789545s"
      }
    }
  ]
}

» 

```







### 执行stop.yml停止节点tikv服务

等待offline之后,执行stop.yml停止节点tikv服务；

```
[tidb@tidb01-41 tidb-ansible]$ ansible-playbook stop.yml -l 192.168.1.44

PLAY [check config locally] *********************************************************************************************************************************
skipping: no hosts matched

......
......

Congrats! All goes well. :-)
```



### 从inventory.ini中移除tikv节点IP

如下图所示，将框选出IP移除该文件；

![5b9b77a5bb7f53af382a1459ab2b0fb.png](http://cdn.lifemini.cn/dbblog/20201227/be8f5aa1d45b4107a3a32ba367b226e6.png)


![f27369a63cad296c22e8a014c68d0b7.png](http://cdn.lifemini.cn/dbblog/20201227/52da60141a0a45f8afd9872ef198ec4b.png)

### 滚动更新普罗米修斯



```

[tidb@tidb01-41 tidb-ansible]$ vi inventory.ini 
[tidb@tidb01-41 tidb-ansible]$ ansible-playbook rolling_update_monitor.yml --tags=prometheus

PLAY [check config locally] *********************************************************************************************************************************


.....
.....

PLAY RECAP **************************************************************************************************************************************************
192.168.1.41               : ok=3    changed=0    unreachable=0    failed=0   
192.168.1.42               : ok=25   changed=8    unreachable=0    failed=0   
192.168.1.43               : ok=3    changed=0    unreachable=0    failed=0   
localhost                  : ok=7    changed=4    unreachable=0    failed=0   

Congrats! All goes well. :-)
```



### 普罗米修斯检查

![84f476fc743f2cf8de27d5b2233c761.png](http://cdn.lifemini.cn/dbblog/20201227/13103cdaa9ef4c49afb1d89d50a334be.png)


刚刚更新完毕，集群还需要一定的时间反应；
下图可以看出，红色部分已经消失。

![09c46c43533324e9562450d4224e2c4.png](http://cdn.lifemini.cn/dbblog/20201227/f83b5cb124a0412d8c32df717c55ed38.png)


