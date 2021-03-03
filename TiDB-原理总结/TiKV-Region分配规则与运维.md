# TiKV-Region分配规则与运维
时间:2021-03-02



单个节点的参数设置只会对该节点的 region 有效，如果有 region 的迁移，会重新按照新节点的参数设置进行一系列的操作



将 Region 元信息从 etcd 移到 go-leveldb 存储引擎，解决大规模集群 etcd 存储瓶颈问题

v3.0 版本起，PD 默认开启配置项 use-region-storage，将 Region Meta 信息存在本地的 LevelDB 中，并通过其他机制同步 PD 节点间的信息 [切换 PD Leader 的速度慢](https://docs.pingcap.com/zh/tidb/stable/massive-regions-best-practices#%E5%88%87%E6%8D%A2-pd-leader-%E7%9A%84%E9%80%9F%E5%BA%A6%E6%85%A2)



[tikvclient: refine region-cache--issue](https://github.com/pingcap/tidb/pull/10256)


[TiDB 源码阅读系列文章（十八）tikv-client（上）-- Region 元数据信息](https://pingcap.com/blog-cn/tidb-source-code-reading-18/#%E5%A6%82%E4%BD%95%E5%AE%9A%E4%BD%8D-key-%E6%89%80%E5%9C%A8%E7%9A%84-tikv-server)







