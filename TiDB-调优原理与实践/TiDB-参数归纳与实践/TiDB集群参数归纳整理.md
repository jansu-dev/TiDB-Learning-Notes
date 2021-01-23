# TiDB-TiDB集群参数归纳整理  

> - [split-table参数](#split-table参数)  
> - [token-limit参数](#token-limit参数)  
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
>   - [level参数](#level参数)  
>   - [format参数](#format参数)  
>   - [enable-timestamp参数](#enable-timestamp参数)  
>   - [enable-slow-log参数](#enable-slow-log参数)  
>   - [slow-query-file参数](#slow-query-file参数)  
>   - [slow-threshold参数](#slow-threshold参数)  
>   - [record-plan-in-slow-log参数](#record-plan-in-slow-log参数)  
>   - [expensive-threshold参数](#expensive-threshold参数)  
>   - [query-log-max-len参数](#query-log-max-len参数)  
> - [log.file日志文件相关配置项 ](#log.file日志文件相关配置项 )  
>   - [filename参数](#filename参数)  
>   - [max-size参数](#max-size参数)  


## split-table参数   

 - 涵义：为每个 table 对象创建单独的 region    
 - 默认值: true
 - 作用：参数开启有利于 PD 对热点表的控制，如果创建的表特别多会出现空 region 特别多的现象，反而不利于调度     
 - 建议：如果创建表的数量特别多，建议将该值设为 false 
 - 使用： 
   ```shell

   ```  


## token-limit参数

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



#### performance性能相关配置 