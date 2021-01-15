# TiDB-Grafana监控解读之TiKV



CPU  
涵义：每个TiKV实例CPU的使用率；    
作用：判断当前 TiKV 实例是否存在 CPU 方面的性能瓶颈，一般使用率超过 80% 就需要对 TiKV 进行一些扩容操作；  

![image.png](http://cdn.lifemini.cn/dbblog/20210115/c97ca1e51a8840c9b32b25eb418ea4f1.png)


QPS  
涵义：每个 TiKV 实例上各种命令的 QPS；    
作用：可以在集群出现性能压力时问题定位，判断那个 TiKV 节点出现了压力，主要进行的什么操作，如 coprocessor 进行的就是读操作，如果某一个 TiKV 读操作特别高，其他正常可以判此时出现了读热点；    

![image.png](http://cdn.lifemini.cn/dbblog/20210115/520f715a5a5f40028bcb4b4c6f317bb4.png)



Errors  
涵义：每个 TiKV 实例上 gRPC 消息失败的个数；         
作用：网络问题定位，grpc 消息在TiDB集群中时时刻刻在发生；      



