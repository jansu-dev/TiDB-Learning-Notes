# TiDB-TiFlash OOM 问题
时间:2021-03-19




```yml

## 数据块元信息的内存 cache 大小限制，通常不需要修改
mark_cache_size = 5368709120
## 数据块 min-max 索引的内存 cache 大小限制，通常不需要修改
minmax_index_cache_size = 5368709120

[profiles.default]
    ## 单次 coprocessor 查询过程中，对中间数据的内存限制，单位为 byte，默认为 0，表示不限制
    max_memory_usage = 0
    ## 所有查询过程中，对中间数据的内存限制，单位为 byte，默认为 0，表示不限制
    max_memory_usage_for_all_queries = 0
    ## 从 v4.0.11 引入，表示 TiFlash Coprocessor 最多同时执行的 cop 请求数量。如果请求数量超过了该配置指定的值，多出的请求会排队等待。如果设为 0 或不设置，则使用默认值，即物理核数的两倍。
    cop_pool_size = 0
    ## 从 v4.0.11 引入，表示 TiFlash Coprocessor 最多同时执行的 batch 请求数量。如果请求数量超过了该配置指定的值，多出的请求会排队等待。如果设为 0 或不设置，则使用默认值，即物理核数的两倍。
    batch_cop_pool_size = 0


```


```yml
    mark_cache_size = 5368709120
    minmax_index_cache_size = 5368709120
    profiles.default.max_memory_usage = 0
    profiles.default.max_memory_usage_for_all_queries = 0
    profiles.default.cop_pool_size = 0
    profiles.default.batch_cop_pool_size = 0
```

mark_cache_size, minmax_index_cache_size 均用于配置 TiFlash 存储引擎一些数据索引信息在内存中缓存的大小。用于对磁盘上数据块的初步过滤，优化读取过程中 I/O 操作。
减少这两个参数，用于缓存的内存会减少，相应地，在读取时可能需要重新从磁盘加载索引信息，磁盘 I/O 会增加，会对读性能有一定影响


set @@tidb_allow_batch_cop=0;
set @@session.tidb_allow_batch_cop=1; # 合并对 TiFlash 的数据请求
set @@session.tidb_opt_broadcast_join=1; # 开启 broadcast join 优化，即尝试把 小表 join 大表 的操作下推到 TiFlash 节点

https://docs.pingcap.com/zh/tidb/stable/tune-tiflash-performance#tidb-%E7%9B%B8%E5%85%B3%E5%8F%82%E6%95%B0%E8%B0%83%E4%BC%98

导出dashboard  https://metricstool.pingcap.com/#backup-with-dev-tools


