# TiDB-TiDB集群Ansible方式节点缩容
时间：2020-12-22

### 中控机操作目标机停用TiDB服务
```
[tidb@tidb01-41 tidb-ansible]$ ansible-playbook stop.yml -l 192.168.1.44

PLAY [check config locally] **********************************************************************************************
skipping: no hosts matched

......
......

Congrats! All goes well. :-)

```



### 登陆验证TiDB服务关闭


```
[tidb@tidb01-41 tidb-ansible]$ mysql -u root -h 192.168.1.44 -P 4000
ERROR 2003 (HY000): Can't connect to MySQL server on '192.168.1.44' (111)

```



### 中控机从inventory.ini移除IP


![99c7436e809d9c19fd042b08a6f1eb3.png](http://cdn.lifemini.cn/dbblog/20201227/b99b0347cb5d4e4ebb0097f9b8345874.png)

node_exporter and blackbox_exporter servers部分的监控IP信息同理也要移除。

```
# node_exporter and blackbox_exporter servers
[monitored_servers]
192.168.1.41
192.168.1.42
192.168.1.43

```



### 更新普哦米修斯



```
[tidb@tidb01-41 tidb-ansible]$ vi inventory.ini 
[tidb@tidb01-41 tidb-ansible]$ ansible-playbook rolling_update_monitor.yml --tags=prometheus

PLAY [check config locally] **********************************************************************************************

.....
.....


PLAY RECAP ***************************************************************************************************************
192.168.1.41               : ok=3    changed=0    unreachable=0    failed=0   
192.168.1.42               : ok=25   changed=8    unreachable=0    failed=0   
192.168.1.43               : ok=3    changed=0    unreachable=0    failed=0   
localhost                  : ok=7    changed=4    unreachable=0    failed=0   

Congrats! All goes well. :-)
```



红色部分需要一段时间才能消失，是整个集群还没有反映过来；
但是可以看到，TiDB的实例数量已经降到了2。

![1dc88c18a7de3dcafe8c757f993eda2.png](http://cdn.lifemini.cn/dbblog/20201227/dc89babef59f4262a0ff7b12b18ab45b.png)













