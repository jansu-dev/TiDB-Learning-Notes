# scheduler 线程池原理与调优  


## scheduler pool 线程池原理

scheduler 作用  
1. 主要是将复杂的事务请求转化为简单的 key-value 读写，但 scheduler 线程池本身不进行任何写操作；    
2. 进行严格的版本检查，写入版本是否大于已经存在的时间戳；   
3. 


## storage.scheduler-worker-pool-size

