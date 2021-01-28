# TiDB-Grafana监控解读之Overview




## SystemInfo

#### CPU usage
涵义: 每台服务器的CPU的使用率 
作用: 用于评估每台服务器总体的 CPU 压力情况
标准: 使用率超过 80%，很大程度上 CPU 可能就是系统瓶颈  

![image.png](./tidb-overview-pic/cpu_usage.png)

#### CPU Load
涵义: 每台服务器的CPU的使用率 
作用: 用于评估每台服务器总体的 CPU 压力情况
标准: CPU 的 Load 应该小于 CPU vCore 的个数，否则可能会成为系统的瓶颈    

![image.png](./tidb-overview-pic/load.png)

