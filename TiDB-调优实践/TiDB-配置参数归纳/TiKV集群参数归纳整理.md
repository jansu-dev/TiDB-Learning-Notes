# TiDB-TiKV集群参数归纳整理  


## TiKV普通参数限制

#### server参数
 - 涵义：Http API 服务的工作线程数量    
 - 默认值: 1 
 - 作用：
   - 1 --> 默认值、最小值     
 - 建议：如果创建表的数量特别多，建议将该值设为 false 
 - 验证： 
   ```shell

   ```

#### grpc-compression-type参数
 - 涵义：gRpc 消息的的压缩算法，取值：none， deflate， gzip 
 - 默认值: none 
 - 作用：
   - 1 --> 默认值、最小值     
 - 建议： 
 - 验证： 
   ```shell

   ```

#### grpc-concurrency参数
 - 涵义：gRpc 工作线程的数量
 - 默认值: 4 
 - 作用：
   - 1 --> 最小值  
   - 4 --> 默认值   
 - 建议： 
 - 验证： 
   ```shell

   ```

#### grpc-concurrent-stream参数
 - 涵义：一个 gRpc 链接中的最大请求数量
 - 默认值: 1024 
 - 作用：
   - 1 --> 最小值  
   - 1024 --> 默认值   
 - 建议： 
 - 验证： 
   ```shell

   ```

#### grpc-memory-pool-quota参数
 - 涵义：gRpc 可以使用的内存大小限制
 - 默认值: 32G 
 - 作用：
   - 1 --> 最小值  
   - 1024 --> 默认值   
 - 建议：建议仅在出现内存不足 (OOM) 的情况下限制内存使用，限制内存使用可能会导致卡顿 
 - 验证： 
   ```shell

   ```
#### grpc-raft-conn-num参数
 - 涵义：TiKV 节点之间用于 raft 数据连接的最大数量
 - 默认值: 10 
 - 作用：
   - 1 --> 最小值  
   - 10 --> 默认值   
 - 建议：
 - 验证： 
   ```shell

   ```

#### grpc-stream-initial-window-size参数
 - 涵义：grpc stream 初始化的窗口大小，单位：KB|MB|GB
 - 默认值: 2MB  
 - 作用：
   - 1KB --> 最小值  
   - 2MB --> 默认值   
 - 建议：
 - 验证： 
   ```shell

   ```

#### grpc-keepalive-time参数
 - 涵义：grpc 请求尝试连接时长超过该参数值限制便会关闭 gRpc 连接  
 - 默认值: 3s
 - 作用：
   - 1s --> 最小值  
   - 3s --> 默认值   
 - 建议：
 - 验证： 
   ```shell

   ```

#### concurrent-send-snap-limit参数 
 - 涵义：同一时间点，能够发送的所有 snapshot 最大数量  
 - 默认值: 32
 - 作用：
   - 1 --> 最小值  
   - 32 --> 默认值   
 - 建议：
 - 验证： 
   ```shell

   ```

#### concurrent-recv-snap-limit参数 
 - 涵义：同一时间点，能够接收的所有 snapshot 最大数量  
 - 默认值: 32
 - 作用：
   - 1 --> 最小值  
   - 32 --> 默认值   
 - 建议：
 - 验证： 
   ```shell

   ```

#### end-point-recursion-limit参数
 - 涵义：end-point 下推查询请求解码消息时，最多允许的递归层数    
 - 默认值: 1000
 - 作用：
   - 1 --> 最小值  
   - 1000 --> 默认值   
 - 建议：
 - 验证： 
   ```shell

   ```

#### end-point-request-max-handle-duration参数
 - 涵义：end-point 下推任务属于允许的最大处理时长    
 - 默认值: 60s
 - 作用：
   - 1s --> 最小值  
   - 60s --> 默认值   
 - 建议：
 - 验证： 
   ```shell

   ```

#### snap-max-write-bytes-per-sec
 - 涵义：处理 snap 时允许使用的最大磁盘带宽，单位KB|MB|GB     
 - 默认值: 100MB
 - 作用：
   - 1KB --> 最小值  
   - 100MB --> 默认值   
 - 建议：
 - 验证： 
   ```shell

   ```


#### end-point-slow-log-thread参数
 - 涵义：下推请求查询慢日志输出阈值     
 - 默认值: 1s
 - 作用：
   - 0 --> 关闭  
   - 1s --> 默认值   
 - 建议：
 - 验证： 
   ```shell

   ```

#### readpool.unified参数   

 - min-thread-count
   - 涵义：统一处理读请求的线程池最少拥有的线程数量     
   - 默认值: 1
   - 作用： 
   - 建议：
   - 验证： 
     ```shell
  
     ```
 - max-thread-count
   - 涵义：统一处理读请求的线程池最多拥有的线程数量     
   - 默认值: CPU * 0.8,最少为 4
   - 作用： 
   - 建议：
   - 验证： 
     ```shell
  
     ```
 - stack-size
   - 涵义：统一处理读请求的线程池最少拥有的线程数量     
   - 默认值: 1
   - 作用： 
   - 建议：
   - 验证： 
     ```shell
  
     ```
 - min-thread-count
   - 涵义：统一处理读请求的线程池最少拥有的线程数量     
   - 默认值: 1
   - 作用： 
   - 建议：
   - 验证： 
     ```shell
  
     ```

### RocksDB配置


#### storage.block-cache

 - shared
   - 涵义：RocksDB 多个 CF 之间共享 block cache 配置选项，开启之后，为每个 CF 单独配置的 block cache 将无效     
   - 默认值: true   
   - 作用：在整个 RocksDB 存储层之上构建缓存层，相比于各 CF 设置缓存层的方法，在更高层次建立了缓冲、更加贴近业务，有利于增大缓存的命中率    
   - 建议：不做更改，使用默认开启  
   - 验证： 
     ```shell
   
     ```  
     
 - capacity
   - 涵义：共享 block cache 的大小，v3.0 版本引入，单位：KB|MB|GB       
   - 默认值: 系统总内存大小的 45%   
   - 作用：限制缓存层使用内存的最大值    
   - 建议：TiKV 单独部署的情况下，系统总内存大小的 80%  
   - 验证： 
     ```shell
   
     ```



