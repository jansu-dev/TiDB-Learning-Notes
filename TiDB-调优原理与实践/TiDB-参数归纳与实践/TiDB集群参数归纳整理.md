# TiDB-TiDB集群参数归纳整理  

> - [TiDB普通参数限制](#split-table参数)  
>   - [split-table参数](#split-table参数)    
>   - [token-limit参数](#token-limit参数)  
> - [mem-quota-query参数](#mem-quota-query参数)  
> - [oom-use-tmp-storage参数](#oom-use-tmp-storage参数)  
> - [tmp-storage-path参数](#tmp-storage-path参数)  
> - [tmp-storage-quota参数](#tmp-storage-quota参数)  
> - [lower-case-table-names参数](#lower-case-table-names参数)  
> - [lease参数](#lease参数)  
> - [compatible-kill-query参数](#compatible-kill-query参数)  
> - [check-mb4-value-in-utf8参数](#check-mb4-value-in-utf8参数)    
> - [treat-old-version-utf8-as-utf8mb4参数](#treat-old-version-utf8-as-utf8mb4参数)  
> - [alter-primary-key参数](#alter-primary-key参数)  
> - [server-version参数](#server-version参数)  
> - [repair-mode参数](#repair-mode参数)  
> - [repair-table-list参数](#repair-table-list参数)  
> - [new_collations_enabled_on_first_bootstrap参数](#new_collations_enabled_on_first_bootstrap参数)  
> - [max-server-connections参数](#max-server-connections参数)  
> - [max-index-length参数](#max-index-length参数)  
> - [log相关配置项](#log相关配置项)   
> - [log.file日志文件相关配置项 ](#log.file日志文件相关配置项 )  
> - [prepared-plan-cache实验参数配置](#prepared-plan-cache实验参数配置)  
> - [参考文章](#参考文章)

## TiDB普通参数限制

### split-table参数   

 - 涵义：为每个 table 对象创建单独的 region    
 - 默认值: true
 - 作用：参数开启有利于 PD 对热点表的控制，如果创建的表特别多会出现空 region 特别多的现象，反而不利于调度     
 - 建议：如果创建表的数量特别多，建议将该值设为 false 
 - 使用： 
   ```shell

   ```  


### token-limit参数

 - 涵义：可以同时执行请求的 session 个数    
 - 默认值: 1000   
 - 作用：限制 session 的并发度，因为在 tidb 源码中可以看出 conn 函数用于不断监听请求，实际执行命令的是 session 模块，由session模块进行递归构建 AST ，该参数意味着在某段时间内 tidb 处理 session 请求的能力   
 - 建议：可通过内存使用情况、业务需求适当调整
 - 使用：  
   ```
  
   ```



## mem-quato-query参数 

 - 涵义：控制单挑 SQL 语句占用内存的最大使用量，以字节(Bytes)为单位  
 - 默认值:   
    - v2.0.x和v3.0.x为1073741824Bytes(1G)   
    - v4.0.9以上为34359738368(32G)
 - 作用：因为 TiDB 集群由 Go 语言实现，Go 本身是有内存回收机制的，不加以限制会出现单条 SQL 执行时间过长导致 TiDB 无法及时回收内存占用导致内存溢出(oom-action)的现象，而且 SQL 长时间计算不出结果，直至最后 crash;  
    - 如：单条 SQL 进行大数据量的全表遍历、排序，导致相关数据全部存在 tidb 内存中，数据量大超过 1G 时， TiDB 就会 crash  
 - 建议：初始化 v4.0.9 版本以前集群时，及时调整该参数  
 - 使用：   
   ```
  
   ```


## oom-use-tmp-storage参数

 - 涵义：设置单挑 SQL 占用内存使用超过 mem-quato-query 时，为某些算子启用临时磁盘   
 - 默认值: true
 - 作用：TiDB 源码可得 session 会驱动构建 AST-->Logical Plan-->Physical Plan-->Executer(算子)，最后 Executer 下发算子到 TiKV，启用算子临时磁盘，有利于减少算子部分的内存占用，达到减少 oom-action 的目的 
 - 建议：将该参数开启  
 - 使用：
   ```

   ```

## tmp-storage-path参数  

 - 涵义：oom-use-tmp-storage 参数对应的临时文件存储路径  
 - 默认值: <操作系统临时文件夹>/<操作系统用户ID>_tidb/hash(<host>:<port>/<statusHost>:<statusPort>)/tmp-storage  
 - 作用：作为 oom-use-tmp-storage 相关参数使用，在 oom-use-tmp-storage 参数不启用时，tmp-storage-path 参数无效  
 - 建议：不做改动  
 - 使用：
   ```

   ```


## tmp-storage-quota参数

 - 涵义：tmp-storage-path 存储使用的限额，单位字节(Bytes)   
 - 默认值: -1    
 - 作用：当 tmp-storage-path 路径下的使用超过限额时，返回错误 out oof global storage quotal! 错误,并取消当前 SQL 操作  
 - 建议：结合操作系统存储容量，适当放大 tmp-storage-quota 限制  
 - 使用：
 ```

 ```
## oom-action

 - 涵义：设定 SQL 操作内存占用超过 mem-quota-query 限制时，是仅输出日志，还是既取消当前操作并输出日志  
 - 默认值: "log"   
 - 作用：有利于 DBA 定位 SQL 操作出现 OOM 行为的原因;  
 - 建议：将该参数设置为 "cancel";  
 - 使用：  
 ```

 ```


## lower-case-table-names参数

 - 涵义：设定 TiDB 对于表名大小写是否敏感，TiDB 当前仅支持该参数设置为 2    
 - 默认值: 2   
 - 作用：参数值为 2 时,按照区分大小写来保存表名,但按照小写的字节序(不区分大小写)来比较;   
 - 建议：不做更改;  
 - 使用：
 ```

 ```

## lease参数

 - 涵义：DDL 租约超时时间，单位秒(s);    
 - 默认值： 45s  
 - 作用：用于限定 DDL 语句的超时时间，在 v3.0.x 之后 TiDB 实现了异步 DDL，就是以 Job 的形式保存在 PD 队列中，由 TiKV 子节点分别执行 DDL 操作，这就涉及到执行时间的问题，该参数用于限制 DDL 操作的执行时间  
 - 建议：不做更改;  
 - 使用：
  ```

  ```

## compatible-kill-query参数

 - 涵义：设置 kill 操作的兼容性 
 - 默认值: false  
 - 作用：在确保 kill 操作所连接 session 正确性的前提下，直接终止先要总之的 SQL 操作  
 - 建议：不做更改;  
 - 使用：
 ```

 ```
## check-mb4-value-in-utf8参数 

 - 涵义：检验插入字符是否为 utf8 字符;  
 - 默认值: true
 - 作用：开始该参数，当插入utf8mb4字符时，TiDB 会报错,如：emoji 表情;  
 - 建议：更改为 flase，因为 MySQL8 和 TiDB v4.0.x 已将默认字符集更改为 utf8mb4，并且 utf8mb4 是 utf8 的超级，兼容 utf8 字符集  
 - 使用：
 ```

 ```



## treat-olf-version-utf8-as-utf8mb4参数

 - 涵义：设置是否将原来 TiDB 中 utf8 字符集的数据当作 utf8mb4 字符集来对待   
 - 默认值: true
 - 作用：同涵义; 
 - 建议：将该参数开启;  
 - 使用：
   ```

   ```


## alter-primary-key参数

 - 涵义：在集群初始化后，是否可以动态添加、删除主键;   
 - 默认值: false
 - 作用：同涵义，但如果原表主键为 int 或 bigint 类型，即使开启该参数也无法动态删除、添加主键 
 - 建议：将该参数开启  
 - 使用：
   ```

   ```


## server-version参数

 - 涵义：设置内置函数 version() 的返回结果;   
 - 默认值: "",默认情况下，TiDB 版本号返回格式为: 5.7.${mysql-lastest-minor-version}-TiDB-${TiDB-version}
 - 作用：同涵义 
 - 建议：不做更改   
 - 使用：
   ```

   ```


## repair-mode参数

 - 涵义：是否开启非可信修复模式;   
 - 默认值: false
 - 作用：启动非可信修复模式情况下，可以过滤 repair-table-list 内存表中所列出的坏表加载； 
 - 建议：将该参数开启，默认情况下不支持修复语法，启动时会加载所有表信息；   
 - 使用：
   ```

   ```


## repair-table-list参数

 - 涵义：对应 repair-mode 参数为 true 时，用于在配置文件中列出怀表配置项;   
 - 默认值: []
 - 作用：当repair-mode为true，且[]内表项非空时，TiDB 在启动时不加载 [] 内表信息； 
 - 建议：不开启，结合具体情况使用，紧急情况下拉起数据库  
 - 使用：
   ```

   ```


## new_collations_enabled_on_first_bootstrap参数

 - 涵义：用于开启是否启用新版本的字符集框架;   
 - 默认值:  
   - 4.0.x版本及之后，默认开启；  
   - 4.0.x版本之前，没有该参数；  
 - 作用：TiDB 在 v4.0.x 之后启动了新的字符集框架，所以新增了该参数，该参数仅在集群初始化阶段可设置，由低于 v4.0.x 之前版本升级过来的 TiDB 改变该参数配置也无法生效； 
 - 建议：将该参数开启  
 - 使用：
   ```

   ```

# 测试一下4.0.x是否可以动态修改

## max-server-connections参数

 - 涵义：限制 TiDb 同时允许最大客户端连接数;   
 - 默认值: 0
 - 作用：默认情况下，该参数值为 0,表示不限制客户端连接数，大于 0 时，为限制客户端连接数的值（类似于Oracle中的process）； 
 - 建议：将该参数结合内存资源使用、适当调节参数值大小，限制资源使用；   
 - 使用：
   ```

   ```


## max-index-length参数

 - 涵义：设置新建索引的长度限制，单位字节Bytes;   
 - 默认值: 3072
 - 作用：该参数值域为[3072,3072*4],从 v3.0.11 版本开始增加 max-index-length 参数，默认值为 3072 字节，目的是为了兼容 MySQL，v3.0.11版本之前，虽然没有该参数调节，但是默认限制也是 3072 字节； 
 - 建议：不做修改   
 - 使用：
   ```

   ```


## enable-telemetry参数

 - 涵义：是否开启遥测功能;   
 - 默认值: true
 - 作用：遥测用户在 TiDB 使用过程中，PingCap 公司搜集用户使用情况，以便于 TiDB 改进； 
 - 建议：不做修改  
 - 使用：
   ```

   ```


## log相关配置项

> - [level参数](#level参数)  
> - [format参数](#format参数)  
> - [enable-timestamp参数](#enable-timestamp参数)  
> - [enable-slow-log参数](#enable-slow-log参数)  
> - [slow-query-file参数](#slow-query-file参数)  
> - [slow-threshold参数](#slow-threshold参数)  
> - [record-plan-in-slow-log参数](#record-plan-in-slow-log参数)  
> - [expensive-threshold参数](#expensive-threshold参数)  
> - [query-log-max-len参数](#query-log-max-len参数) 
> - [log相关配置项使用](#log相关配置项使用) 

#### level参数

 - 涵义：指定日志的输出级别   
 - 默认值: "info"



#### format参数

 - 涵义：指定日志输出的格式   
 - 默认值: "text"
 - 可选项: [json, text, console] 



#### enable-slow-log参数

 - 涵义：是否开启慢查询日志;   
 - 默认值: true
 - 作用：开启慢查询日志有利于定位慢 SQL； 


#### slow-query-file参数

 - 涵义：慢查询日志名称;   
 - 默认值: "tidb-slow.log" 

#### slow-threshold参数

 - 涵义：控制采集慢日志的最大时间阈值;   
 - 默认值: 300ms 
 - 作用：SQL 操作执行时间大于该阈值，便将 SQL 相应慢日志信息输出到 slow-log 中； 
 - 建议：结合业务情况修改    

#### record-plan-in-slow-log参数  

 - 涵义：是否在 slow-log 中记录执行计划;   
 - 默认值: 1
 - 作用：
    - 0 --> 关闭 
    - 1 --> 开启 
 - 建议：不做修改  
 - 使用：
   ```
    tidb_record_plan_in_slow_log 
   ```


#### expensive-threshold参数  

 - 涵义：输出 expendive 操作的行数阈值;   
 - 默认值: 10000 
 - 作用：当操作的行数大于该参数阈值时，TiDB 识别此SQL操作为一个昂贵操作，并带有 [EXPENSIVE_QUERY] 前缀输出在日志中； 
 - 建议：不做修改，或结合业务修改  

#### record-plan-in-slow-log参数  

 - 涵义：是否开启遥测功能;   
 - 默认值: true
 - 作用：遥测用户在 TiDB 使用过程中，PingCap 公司搜集用户使用情况，以便于 TiDB 改进； 
 - 建议：不做修改  

#### query-log-max-len参数  

 - 涵义：在 slow-log 中，最长的 SQL 语句的输出长度限制;   
 - 默认值: 4096
 - 作用：当超过该参数值限制时，SQL 语句会被阶段输出至 slow-log中； 
 - 建议：不做修改  

#### log相关配置项使用

```

```

## log.file日志文件相关配置项   

> - [filename参数](#filename参数)  
> - [max-size参数](#max-size参数)  

#### fiiename参数

 - 涵义：一般日志的名字;   
 - 默认值: ""
 - 作用：如果设置，会输出一般日志到这个文件 
 - 建议：不做修改  

#### max-size参数  

 - 涵义：日志文件的大小限制;   
 - 默认值: 300MB
 - 作用：同涵义，最大上限 4GB； 
 - 建议：不做修改  

#### max-days参数  

 - 涵义：日志文件大小限制;   
 - 默认值: 0
 - 作用：默认值 0 表示不清理历史日志文件，会造成日志文件大量堆积占用磁盘空间，设置大于零参数值后会定期清理过期日志文件； 
 - 建议：结合业务容忍度、磁盘空间修改  

#### max-backup参数  

 - 涵义：保留的日志最大数量;   
 - 默认值: 0
 - 作用：
   - 0 --> 全部保存，也是默认值   
   - 7 --> 会最大保留7个老的日志文件   
 - 建议：结合业务容忍度、磁盘空间、巡检计划修改  


#### log.file日志文件相关配置项使用

```

```


## security安全相关配置项 

> - [level参数](#level参数)  
> - [format参数](#format参数)  
> - [enable-timestamp参数](#enable-timestamp参数)  
> - [enable-slow-log参数](#enable-slow-log参数)  
> - [slow-query-file参数](#slow-query-file参数)  
> - [slow-threshold参数](#slow-threshold参数)  
> - [record-plan-in-slow-log参数](#record-plan-in-slow-log参数)  
> - [expensive-threshold参数](#expensive-threshold参数)  
> - [query-log-max-len参数](#query-log-max-len参数) 
> - [log相关配置项使用](#log相关配置项使用) 

#### ssl-ca参数  

 - 涵义：是否开启遥测功能;   
 - 默认值: true
 - 作用：遥测用户在 TiDB 使用过程中，PingCap 公司搜集用户使用情况，以便于 TiDB 改进； 
 - 建议：不做修改  
 - 使用：
   ```

   ```
#### ssl-cert参数  

 - 涵义：是否开启遥测功能;   
 - 默认值: true
 - 作用：遥测用户在 TiDB 使用过程中，PingCap 公司搜集用户使用情况，以便于 TiDB 改进； 
 - 建议：不做修改  
 - 使用：
   ```

   ```
#### ssl-key参数  

 - 涵义：是否开启遥测功能;   
 - 默认值: true
 - 作用：遥测用户在 TiDB 使用过程中，PingCap 公司搜集用户使用情况，以便于 TiDB 改进； 
 - 建议：不做修改  
 - 使用：
   ```

   ```
#### cluster-ssl-ca参数  

 - 涵义：是否开启遥测功能;   
 - 默认值: true
 - 作用：遥测用户在 TiDB 使用过程中，PingCap 公司搜集用户使用情况，以便于 TiDB 改进； 
 - 建议：不做修改  
 - 使用：
   ```

   ```
#### cluster-ssl-cert参数  

 - 涵义：是否开启遥测功能;   
 - 默认值: true
 - 作用：遥测用户在 TiDB 使用过程中，PingCap 公司搜集用户使用情况，以便于 TiDB 改进； 
 - 建议：不做修改  
 - 使用：
   ```

   ```


#### cluster-ssl-key参数  

 - 涵义：是否开启遥测功能;   
 - 默认值: true
 - 作用：遥测用户在 TiDB 使用过程中，PingCap 公司搜集用户使用情况，以便于 TiDB 改进； 
 - 建议：不做修改  
 - 使用：
   ```

   ```



## performance性能相关配置 

> - [max-procs参数](#max-procs参数)  
> - [max-memory参数](#max-memory参数)  
> - [memory-usage-alarm-ratio参数](#memory-usage-alarm-ratio参数)  
> - [enable-slow-log参数](#enable-slow-log参数)  
> - [slow-query-file参数](#slow-query-file参数)  
> - [slow-threshold参数](#slow-threshold参数)  
> - [record-plan-in-slow-log参数](#record-plan-in-slow-log参数)  
> - [expensive-threshold参数](#expensive-threshold参数)  
> - [query-log-max-len参数](#query-log-max-len参数) 
> - [log相关配置项使用](#log相关配置项使用) 


#### max-procs参数  

 - 涵义：TiDB 使用 CPU 的数量限制;   
 - 默认值: 0
 - 作用：TiDB 所能使用 CPU 的vCore数量越大，意味着所能使用的线程的并发能力越高     
   - 0 --> 使用机器上所有的 CPU，也是默认值 
   - n --> 限制 TiDB 所使用 CPU 的 vCore 个数
 - 建议：如果是单独部署建议不做修改，如果存在混合部署，酌情限制每个 TiDB 使用  


#### max-memory参数  

 - 涵义：限制 TIDB 的 Prepare-cache 所能使用的最大内存容量   
 - 默认值: 0  
 - 作用：Prepare cache LRU 内存使用量限制，TiDB 中prepare阶段会缓存执行计划，但内存资源有限， Prepare cache 使用内存超过 performance.max-memory * (1 - prepare-plan-cache.memory-guard-ratio)时，会使用 LRU 算法剔除 cache 中的元素   
   - 该值仅在 prepare-plan-cache.enabled 为 true 时，才生效    
 - 建议：不做修改，当出现性能问题时可具体问题具体分析，当出现大量 SQL 重复解析且非阔不可时再做更改    


#### max-memory-quota参数  

 - 涵义：限制 TIDB 实例总的内存使用量,单位字节(Bytes)     
 - 默认值: 0   
 - 作用：同涵义，类似于 Oracle 的 memory_target  
   - 0 --> 不对实例的内存限制,默认值    
 - 建议：不存在混合部署情况下，除系统内存足够系统使用运行之外全部留给 TiDB 使用；混合部署和酌情限制      


#### memory-usage-alarm-ratio参数  

 - 涵义：当 TiDB 实例占用内存使用量占总内存比例达到阈值便会报警   
 - 默认值: 0.8  
 - 作用：同涵义，当 TiDB 实例内存占用达到告警阈值时，会认为存在内存溢出风险，将正在执行的 SQL 语句前 10 和、运行时间最长的 10 条 SQL 语句、和相关的 heap profile 记录在 tmp-storage-path/record 中，并在日志中输出一条记录 "tidb-server has the risk of OOM"； 
   - 0 --> 关闭内存阈值报警功能  
   - 1 --> 关闭内存阈值报警功能
   - server-memory-quota 未设置 --> 报警阈值 = memory-usage-alarm-ratio * 系统内存大小  
   - server-memory-quota 设置大于 0  --> 报警阈值 = memory-usage-alarm-ratio * server-memory-quota
 - 建议：不做更改  


#### txn-entry-size-limit参数  

 - 涵义：TiDB 限制每个事务中，单行数据的大小限制，单位字节(Bytes);   
 - 默认值：6291456(6MB)   
 - 作用：同涵义，限制事务中key-value记录大小限制。若超出该限制返回 entry too large 错误  
   - 最大不超过125829120(120MB)  
   - TiKV 中类似限制为 raft-entry-max-size，默认也为 8MB ，在调整设置时要将两个参数一起调整   
 - 建议：不做修改  
 - 使用：
   ```

   ```

#### txn-total-size-limit参数  

 - 涵义：TiDB 单个事务大小限制(一个事务可以可以由多条语句构成)，单位字节Bytes   
 - 默认值: 104857600(100GB)
 - 作用： 同涵义
 - 建议：一般不做修改，当时当下游为 Kafka 时，该参数值不要超过 1GB，否则会报错  


#### stmt-count-limit参数  

 - 涵义：TiDB 单个事务允许的最大语句条数限制   
 - 默认值: 5000  
 - 作用：当单个事务语句条数超过阈值时，客户端会得到错误 count 5001 exceeds the transaction limitation, autocommit = false 
   - 乐观事务中，乐观事务会重试该事务，可选择调大该限制  
   - 悲观事务中，不受此参数限制
 - 建议：不做修改  


#### tcp-keep-alive参数  

 - 涵义：iDB 在 TCP 层开启 keepalive;   
 - 默认值: true
 - 作用：保持 TCP 层的握手； 
 - 建议：不做修改  


#### cross-join参数  

 - 涵义：判定 SQL 语句在做 cross join 时，两边表是否可以没有 where 语句;   
 - 默认值: true
 - 作用：控制资源使用 
 - 建议：不做修改  
 - 使用：
   ```

   ```
#### stats-lease参数  

 - 涵义：重载统计信息，更新表行数，检查是否自动 analyze ，利用 feedback 更新统计信息以及加载列统计信息的时间间隔;   
 - 默认值: 3s  
 - 作用：
   - 每隔 stats-lease 时间，TiDB 会检查统计信息是否有更新，如果有会将其更新到内存中  
   - 每隔 20 * stats-lease 时间，TiDB 会将 DML 产生的总行数以及修改行数变化更新到系统表中  
   - 每隔 stats-lease 时间，TiDB 会检查是否有表或者索引需要自动 analyze  
   - 每隔 stats-lease 时间，TiDB 会检查是否有列的统计信息需要被加载到内存中
   - 每隔 200 * stats-lease 时间，TiDB 会将内存中缓存的 feedback 写入系统表中  
   - 每隔 5 * stats-lease 时间，TiDB会读取系统表中的 feedback，更新内存中缓存的统计信息   
   - 如果 stats-lease 值设置为 0 时，TiDB 会以默认 3s 的时间间隔周期读取系统表中的统计信息并更新到中，到那时不会自动更改系统统计信息系统表  
     - 包含 mysql.stats_meta,不再自动记录事务中对某张表的修改行数，也不会更新到这个系统表中  
     - 包含 mysql.stats_histograms/mysql.stats_buckets/mysql.stats_top_n,不再主动更新统计信息，不再自动 analyze 
     - 包括 mysql.stats_feedback,不再根据查询的数据反馈的部分统计信息更新表和索引的统计信息
 - 建议：不做修改  
 - 使用：
   ```

   ```
#### run-auto-analyze参数  

 - 涵义：是否自动 analyze  
 - 默认值: true
 - 作用：即使更新统计信息，确保基于 CBO 的 TiDB 优化器产生正确的执行计划
 - 建议：不做修改  
 - 使用：
   ```

   ```
#### feedback-probability参数  

 - 涵义：对查询收集统计信息反馈的概率;   
 - 默认值: 0.05
 - 作用：TiDB 使用动态采样的方法从所有 SQL 操作中，以 feedback-probability 参数值的概率抽取作为反馈，用于更新统计信息
 - 建议：不做修改  
 - 使用：
   ```

   ```
#### query-feedback-limit参数  

 - 涵义：限制内存中缓存的最大 query feedback 数量，超过这个值数量的 feedback 就会被丢弃     
 - 默认值: 1024 
 - 作用：同涵义   
 - 建议：不做修改，如果出现统计信息不准的情况，再定位确实是这个原因时可酌情更改     
 - 使用：
   ```

   ```
#### pseudo-estimate-ratio参数  

 - 涵义：修改过的行数/表的总行数的比值，超过该值时系统会认为统计信息已经过期，采用 pseudo 假设的方式作为统计信息参考值生成执行计划  
 - 默认值: 0.8
 - 作用：使用评估阈值判断在统计信息不准确的时候，提供另一种方式保证优化器准确性   
   - 0.8 --> 默认值  
   - 0   --> 最小值  
   - 1   --> 最大值   
 - 建议：不做修改  
 - 使用：
   ```

   ```
#### force-priority参数  

 - 涵义：把所有语句优先级设置为 force-priority    
 - 默认值: NO_PRIORITY  
   - 可选值 NO_PRIORITY, LOW_PRIORITY, HIGH_PRIORITY, DELAYED
 - 作用：  
 - 建议：不做修改  
 - 使用：
   ```

   ```

#### distinct-agg-push-down参数  

 - 涵义：控制带有 distinct 关键字的 SQL 操作是否将计算下推到 TiKV 上的 Coprocessor 上执行     
 - 默认值: false
 - 作用：同涵义  
   - false --> 默认值，作为系统变量 tidb_opt_distinct_agg_push_down 的初始化值  
   - true  --> 优化操作
 - 建议：修改为 true    
 - 使用：
   ```

   ```

## prepared-plan-cache实验参数配置 

> - [enabled参数](#enabled参数)  
> - [capacity参数](#capacity参数)  
> - [memory-guard-ratio参数](#memory-guard-ratio参数)  

#### enabled参数

 - 涵义：开启 prepare 语句的 plan cache 功能    
 - 默认值: false
 - 作用：缓存已经解析过的执行计划   
 - 建议：不做修改，在v4.0.9中该参数为实验参数，如有需求谨慎修改  

#### capacity参数

 - 涵义：缓存语句的数量    
 - 默认值: 100
 - 作用：同涵义   
 - 建议：不做修改  

#### memory-guard-ratio参数

 - 涵义：防止超过 performance.max-memory 内存使用限制，当超过 max-memory * (1 - prepared-plan-cache.memory-guard-ratio) 会被 LRU 算法剔除 Cache    
 - 默认值: 0.1 
 - 作用：同涵义  
   - 0 --> 最小值  
   - 1 --> 最大值  
   - n --> n 介于 [1~0] 之间  
 - 建议：不做修改  



## tikv-client相关参数配置 

> - [grpc-connection-count参数](#grpc-connection-count参数)  
> - [grpc-keepalive-time参数](#grpc-keepalive-time参数)  
> - [grpc-keepalive-timeout参数](#grpc-keepalive-timeout参数)  
> - [commit-timeout参数](#commit-timeout参数)  
> - [max-txn-ttl参数](#max-txn-ttl参数)  
> - [max-batch-size参数](#max-batch-size参数) 
> - [max-batch-wait-time参数](#max-batch-wait-time参数) 
> - [batch-wait-size参数](#batch-wait-size参数) 
> - [overload-threshold参数](#overload-threshold参数) 
> - [tikv-client相关参数使用](#tikv-client相关参数使用) 


#### grpc-connection-count参数

 - 涵义：在 TiDB 层限制跟每个 TiKV 节点建立连接的最大连接数限制    
 - 默认值: 16
 - 作用：同涵义   
 - 建议：不做修改，如果部署 TiDB 节点特别多,可酌情增加    

#### grpc-keepalive-time参数

 - 涵义：TiDB 和 TiKV 之间 rpc 连接保持活跃的时间间隔    
 - 默认值: 10
 - 作用：同涵义，如果超过参数值限制， grpc client(TiDB组件) 会发起一次 Ping 判断 TiKV 节点是否存活   
 - 建议：不做修改  

#### grpc-keepalive-timeout参数

 - 涵义：与 grpc-keepalive-time 对应，在发起 Ping TiKV 活性检查之后的超时时间,单位秒(s)    
 - 默认值: 3
 - 作用：同涵义   
 - 建议：不做修改  


#### commit-timeout参数

 - 涵义：执行事务提交时，最大的超时时间，单位秒(s)    
 - 默认值: 41s
 - 作用：同涵义   
 - 建议：不做修改  


#### max-txn-ttl参数 

 - 涵义：单个事务持有锁的最长时间，单位毫秒(ms)    
 - 默认值: 600000ms(10min)
 - 作用：同涵义，事务锁持有时间超过参数阈值，并在其他事务并发处理锁问题相遇时，肯能被其他事务处理掉   
 - 建议：不做修改  



#### max-batch-size参数

 - 涵义：批量发送 rpc 封装的数据包最大数量，使用并发策略减低 rpc 延迟    
 - 默认值: 128
 - 作用：同涵义  
   - n --> 将使用BatchCommands api 向 TiKV 发送请求   
 - 建议：不建议修改(官方标注)  


#### max-batch-wait-time参数

 - 涵义：与 max-batch-size 批量 rpc 对应，等待本参数值规定时间，在此阶段积攒数据直至超过参数阈值，再进行封包 rpc 至 TiKV 节点，单位纳秒 (μs)    
 - 默认值: 0μs
 - 作用：同涵义 
   - 0 --> 默认值，此参数失效  
   - n --> 该参数有效   
 - 建议：不建议修改(官方标注)  


#### batch-wait-size参数

 - 涵义：批量向参数 TIKV 发送的封装包最大数量    
 - 默认值: 8
 - 作用：同涵义   
   - 0 --> 表示关闭该功能  
   - n --> 同涵义   
 - 建议：不建议修改(官方标注)  

#### overload-threshold参数  

 - 涵义：TiKV 负载阈值，如果超过该参数规定阈值，会收集更多的 batch 封包数据，之后再进行封包，然后 rpc，依次来减轻 TiKV rpc 负载    
 - 默认值: 200  
 - 作用：同涵义   
   - 0 --> 表示关闭该功能  
   - n --> 同涵义   
 - 建议：不建议修改(官方标注)  


#### copr-cache相关参数配置 

 - enable参数
   - 涵义：是否开启下推计算结果缓存    
   - 默认值: false  
   - 作用：同涵义 
     - false --> 默认值，开启  
     - true  --> 不开启   
   - 建议：建议开启


 - capacity-mb参数
   - 涵义：与 enable 参数对应，下推计算结果缓存数据量总大小，当缓存空间占满后，旧缓存条目将会提出 Cache，单位兆(MB),浮点类型(float)    
   - 默认值: 1000.0
   - 作用：同涵义 
   - 建议：不建议修改,可依据具体情况调大  


 - admission-max-result-mb参数
   - 涵义：指定被缓存下推最大结果集大小，单个下推计算在 TiKV 组件 Coprocessor 中返回结果集小于该阈值则被缓存，否则忽略，单位兆(MB),浮点  类型(float)      
   - 默认值: 10.0
   - 作用：同涵义，增加缓存层，在缓存命中较大时能有效加快数据处理速度     
   - 建议：
     - 调大该值可缓存更多下推请求，也将导致缓存空间容易被占满，具体情况依赖缓存命中情况修改  
     - 每个下推计算结果集大小一般都会小于 Region 大小，因此将该值设置得远超过 Region 大小没有意义  
     - 因为 Region 在 TiKV 上不定分布，下推计算一般以 Region 为单位，所以没意义  


 - admission-min-process-ms参数
   - 涵义：控制单个下推计算处理时间阈值，小于该阈值说明处理速度很快，没有缓存优化必要，单位毫秒(ms)    
   - 默认值: 5
   - 作用：同涵义 
   - 建议：不建议修改  


#### txn-local-latches相关参数配置
 - enable参数
   - 涵义：开启/关闭内存事务锁    
   - 默认值: false
   - 作用：同涵义   
   - 建议：在事务冲突比较严重时，建议开启  
  
 - capacity参数
   - 涵义：Hash 对应的槽位 (solt) 数，会自动上调为 2 的指数倍，每个槽位占 32 Bytes 内存     
   - 默认值: 2048000 
   - 作用：同涵义    
   - 建议：当写入数据范围比较广时(如：导数据时)，设置过小会导致变慢，性能下降   

#### tikv-client相关参数使用 

```

```


## binlog相关参数配置 


#### enable参数  

 - 涵义：开启/关闭 binlog      
 - 默认值: false
 - 作用：同涵义   
 - 建议：建议开启，可配合 BR 完善增量备份策略  

#### wirite-timeout参数

 - 涵义：写 binlog 的超时时间某，单位秒(s)     
 - 默认值: 15s
 - 作用：同涵义   
 - 建议：不做修改  

#### ignore-error参数

 - 涵义：开启/关闭 binlog 发生错误时处理      
 - 默认值: false
 - 作用：同涵义  
   - true  --> binlog 发生错误时，TiDB 会停止写入 binlog，并且在监控项 tidb_server_critical_error_total 上计数加 1   
   - false --> binlog 发生错误时，TiDB 会停止整个实例的服务
 - 建议：修改为 true   

#### binlog-socket参数

 - 涵义：binlog 输出的网络地址      
 - 默认值: ""
 - 作用：同涵义  
 - 建议：有网络存储需求时，可修改该值   

#### strategy参数

 - 涵义：输出 binlog 时，选择 pump 进程的策略      
 - 默认值: "range"
 - 作用：同涵义，仅提供 range、hash 两中策略选择  
 - 建议：不做修改   



## status相关参数配置

TiDB 服务状态相关配置

#### report-status参数

 - 涵义：控制开启 HTTP API 服务的开/关    
 - 默认值: true
 - 作用：同涵义   
 - 建议：不做修改  

#### record-db-qps参数

 - 涵义：输出与 database 相关参数的 QPS meterics 到 Promethus 的开关    
 - 默认值: false
 - 作用：同涵义   
 - 建议：不做修改  

## stmt-summary参数相关配置

系统表 events_staement-summary_by_digest 的相关配置

#### max-stmt-count参数 

 - 涵义：events_staement-summary_by_digest 系统表中保存的 SQL 种类的最大数量    
 - 默认值: 100
 - 作用：同涵义   
 - 建议：不做修改 


#### max-sql-length参数

 - 涵义：events_staement-summary_by_digest 系统表中 DIGEST_TEXT 和 QUERY_SAMPLE_TEXT 两列的最大显示长度    
 - 默认值: 4096
 - 作用：同涵义   
 - 建议：不做修改 

#### pessimistic-txn相关参数配置

 - enable参数
   - 涵义：开启/关闭悲观事务    
   - 默认值: true
   - 作用：同涵义   
   - 建议：结合业务场景和基准测试情况修改  
  
 - max-retry-count参数
   - 涵义：与 enable 参数对应，限制悲观事务的最大重试次数，重试次数超过参数阈值后，该语句执行将会报错     
   - 默认值: 256
   - 作用：同涵义    
   - 建议：不做修改

#### rexperimental参数

 - allow-experssion-index参数
   - 涵义：用于控制是否能够创建表达式索引     
   - 默认值: false
   - 作用：同涵义    
   - 建议：结合业务场景酌情修改





## 参考文章  

 - [PingCap 官方文档-TiDB 配置文件描述](https://docs.pingcap.com/zh/tidb/stable/tidb-configuration-file)




