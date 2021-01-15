# TiDB-PD集群Ansible方式节点缩容
时间：2020-12-22

### pd-ctl命令行删除PD节点

首先，登录pd-ctl命令行使用member命令查看删除节点对应"name": "pd_tidb04-44"；
其次，执行member delete name pd_tidb04-44操作删除该PD节点；
最后，使用member命令查看已无该name的集群节点出现。

```
[tidb@tidb01-41 tidb-ansible]$ resources/bin/pd-ctl -u http://192.168.1.41:2379 -i
» member
{
  "header": {
    "cluster_id": 6909452787323084897
  },
  "members": [
    {
      "name": "pd_tidb02-42",
      "member_id": 986258930764209162,
      "peer_urls": [
        "http://192.168.1.42:2380"
      ],
      "client_urls": [
        "http://192.168.1.42:2379"
      ]
    },
    {
      "name": "pd_tidb01-41",
      "member_id": 3654086277121920294,
      "peer_urls": [
        "http://192.168.1.41:2380"
      ],
      "client_urls": [
        "http://192.168.1.41:2379"
      ]
    },
    {
      "name": "pd_tidb04-44",
      "member_id": 6266742378045652471,
      "peer_urls": [
        "http://192.168.1.44:2380"
      ],
      "client_urls": [
        "http://192.168.1.44:2379"
      ]
    },
    {
      "name": "pd_tidb03-43",
      "member_id": 6461985847067688046,
      "peer_urls": [
        "http://192.168.1.43:2380"
      ],
      "client_urls": [
        "http://192.168.1.43:2379"
      ]
    }
  ],
  "leader": {
    "name": "pd_tidb01-41",
    "member_id": 3654086277121920294,
    "peer_urls": [
      "http://192.168.1.41:2380"
    ],
    "client_urls": [
      "http://192.168.1.41:2379"
    ]
  },
  "etcd_leader": {
    "name": "pd_tidb01-41",
    "member_id": 3654086277121920294,
    "peer_urls": [
      "http://192.168.1.41:2380"
    ],
    "client_urls": [
      "http://192.168.1.41:2379"
    ]
  }
}

» member delete name pd_tidb04-44
Success!
» member
{
  "header": {
    "cluster_id": 6909452787323084897
  },
  "members": [
    {
      "name": "pd_tidb02-42",
      "member_id": 986258930764209162,
      "peer_urls": [
        "http://192.168.1.42:2380"
      ],
      "client_urls": [
        "http://192.168.1.42:2379"
      ]
    },
    {
      "name": "pd_tidb01-41",
      "member_id": 3654086277121920294,
      "peer_urls": [
        "http://192.168.1.41:2380"
      ],
      "client_urls": [
        "http://192.168.1.41:2379"
      ]
    },
    {
      "name": "pd_tidb03-43",
      "member_id": 6461985847067688046,
      "peer_urls": [
        "http://192.168.1.43:2380"
      ],
      "client_urls": [
        "http://192.168.1.43:2379"
      ]
    }
  ],
  "leader": {
    "name": "pd_tidb01-41",
    "member_id": 3654086277121920294,
    "peer_urls": [
      "http://192.168.1.41:2380"
    ],
    "client_urls": [
      "http://192.168.1.41:2379"
    ]
  },
  "etcd_leader": {
    "name": "pd_tidb01-41",
    "member_id": 3654086277121920294,
    "peer_urls": [
      "http://192.168.1.41:2380"
    ],
    "client_urls": [
      "http://192.168.1.41:2379"
    ]
  }
}

» exit

```



### 执行stop.yml停止PD节点服务

```
[tidb@tidb01-41 tidb-ansible]$ ansible-playbook stop.yml -l 192.168.1.44

PLAY [check config locally] **********************************************************************************************
skipping: no hosts matched

......
......

Congrats! All goes well. :-)
```


### 从inventory.ini中移除IP信息


如下图所示；

![4c57d18d35394ad9e15616e20402fd7.png](http://cdn.lifemini.cn/dbblog/20201227/9151829e15b242239ba3430e67ad6786.png)



![3a63ec1627d25c3e07e5fad3aa42a69.png](http://cdn.lifemini.cn/dbblog/20201227/b4645ae5c9d742f8b01615762e9bf3af.png)




### rolling-update.yml滚动更新集群
```
[tidb@tidb01-41 tidb-ansible]$ ansible-playbook rolling_update.yml

PLAY [check config locally] ****************************************************************************************************

......
......

PLAY RECAP *********************************************************************************************************************
192.168.1.41               : ok=117  changed=15   unreachable=0    failed=0   
192.168.1.42               : ok=92   changed=10   unreachable=0    failed=0   
192.168.1.43               : ok=116  changed=15   unreachable=0    failed=0   
localhost                  : ok=7    changed=4    unreachable=0    failed=0   

Congrats! All goes well. :-)

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


### 基于Grafana的图形化界面检查


![63d36d0af6a99f38eaafd73e664ff73.png](http://cdn.lifemini.cn/dbblog/20201227/6ce5961607d0493ba7915f156eb8e971.png)