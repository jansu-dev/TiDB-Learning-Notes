# TiDB-架构原理总体摘要

## summary
> - [整体架构与逻辑策略](#整体架构与特性场景)  
>   - [TiKV分层架构](#TiKV分层架构)
>   - [TiKV逻辑视图策略](#TiKV逻辑视图策略)
> - [分裂与水平扩展](#分裂与水平扩展)  
>   - [regin分裂过程](#regin分裂过程)  
>   - [水平扩展实现过程](#水平扩展实现过程)  
> - [事务模型](#事务模型)  
>   - [Percolators](#Percolators)  
>   - [去中心化的2PC实现](#去中心化的2PC实现)  
> - [SQL引擎](#SQL引擎)  
>   - [关系模型](#关系模型)  
>   - [一致索引](#一致索引)  
>   - [完善SQL功能](#完善SQL功能)  
>   - [HTAP(OLTP、OLAP)](#HTAP(OLTP、OLAP))  



## 整体架构与特性场景

#### TiKV分层架构


![5e721f8034edfca1e4e32f774f6e62d.png](http://cdn.lifemini.cn/dbblog/20210106/b7b42a2b12aa451bbd693ca112fa941d.png)

TiKV是一个分布式key-value存储引擎，内部采用嵌入式数据库rocksdb编程改良实现。  
rocksdb数据库是经由Facebook改良后的levelDB键值数据库，有良好的batch write、compation、多个memTab、LSM-Tree存储结构等特性。  

TiKV设计的优点：
 - 高度分层优点：有利于单独对某层次进行组件优化、有利于在开发时及时替换某层组件（如：使用mock假组件进行测试）
 - raft机制：TiKV内部通过实现raft协议保证多store下的数据一致性，raft协议有paxos改良而来。
    - 多数派写入特性，raft协议的acceptor仅接收最大proposal number特性及多数派写入成功才算整体写入成功的特性，在tikv引擎中**快速的**保证服务的**强一致性**。 
    - 强leader特性：通过节点选主后**仅在leader节点**上进行读写操作并记录**日志**，由follower节点来追赶主节点的日志实现**多store节点数据一致性**，数据的**容灾及高可用**。  
 - 不依赖分布式文件系统优点：有利于降低整个系统的延时。设想，如果tikv依赖分布式文件系统，那么数据在将要落盘时的操作将经历，向master节点请求storage node存储节点的位置信息，与storage node节点交互并将数据写入操作，而采用本地文件系统则可以避免分布式文件系统在I/O时的网络请求。加之TiKV配备**M.2 NVMe协议**的SSD固态硬盘，将极大提高本地文件系统I/O性能，减少文件系统层面的时延。


#### TiKV逻辑视图策略

TiKV逻辑视图，在逻辑上如何管理、遍历数据实现真正的分布式逻辑。目前有hash map和range map结合的方式，但是hash map由于结果是离散的无法满足range scan。

具体策略：
 - Region在逻辑上是全局有序的，从无穷小到无穷大，有利于sql的range scan
 - 每个Region的key和value的数据类型均是数组,key与value勇byte位比较实现有序排列
 - 对于Region的分片是相对于key值进行的，当key和value的bytes大小超过阈值时（96MB），Region就会在逻辑上进行拆分，拆分后key依旧有序。


## 分裂与水平扩展

#### regin分裂过程   
当Region数据量的不断增长，会在PD Server的元数据中逻辑上的将Region先拆分为两个Region。

分裂过程：
 - 元数据Region逻辑分裂
 - 分裂后才PD会进行自动调度

#### 水平扩展实现过程
水平扩展是通过增加副本、删除副本的操作来实现的，Region分裂的调度时时刻刻都在发生，DBA完全无感知。

如：region分裂后的水平扩展，store在Region分裂后可能会导致剩余存储容量不够用情况，整个过由PD Server master来自动进行，所有的region leader会不断的通过心跳汇报给PD master，因此pd master有能力通过算法和调度命令完成调度。  
具体步骤如下：
 - leader迁移走，后续调度不会影响生产
 - 在新store增加一个副本，同时从新的leader拉去Replica的Region全量
 - 在存储容量剩余不足的store上面，将已经迁移走的Region删除掉

## 事务模型

#### Percolators

#### 去中心化的2PC实现

两阶段提交中存在单点问题，TiDB会产生一个全局TSO（**类似于Oracle的scn**）,TSO 由PD Server master产生。

事务的所得模型V3.0版本之前乐观锁模型，V3.0开始支持悲观锁模型
事务的隔离级别，目前仅支持snapshot isolation的隔离级别

## SQL引擎
client首次访问TiKV存储引擎获取数据时，会先访问PD Server获取并缓存，如Region Leader及其他follower的路由信息等；
当client再次访问TiKV相同Region时，会重用之前的缓存信息。

SQL的执行过程：
 - SQL首先通过Pasrsor转换为AST抽象语法树
 - 对AST进行语法校验、语义校验，如：select * B where B.id=1;(语法校验失败)，select * from B(当B表不存在于DB中时，语义校验失败)
 - 进行逻辑优化，基于代数表达式层面的优化，如：A hash_join B <=> A merge_join B 
 - 结合统计信息，基于成本件合适的物理执行计划，并调用具体的物理算子下推到TiKV层执行并获取结果。无论是在TiDB层面的join算子,还是TiKV层面的aggregation算子均利用单CPU多核特性，采用多线程并行的执行计算操作。







## 参考文章

[PingCAP University - TiDB 架构原理 https://university.pingcap.com/courses/PCTA/chapter/%E6%A6%82%E8%BF%B0/lesson/TiDB-%E6%9E%B6%E6%9E%84%E5%8E%9F%E7%90%86](https://university.pingcap.com/courses/PCTA/chapter/%E6%A6%82%E8%BF%B0/lesson/TiDB-%E6%9E%B6%E6%9E%84%E5%8E%9F%E7%90%86)