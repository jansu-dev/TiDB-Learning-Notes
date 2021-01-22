# TiDB-TiDB集群参数理解


参数名：tidb_distsql_scan_concurrency  
意义：在进行扫描数据的时候的并发度，这里包括扫描 Table 以及索引数据 

参数名：tidb_index_lookup_size

如果是需要访问索引获取行 ID 之后再访问 Table 数据，那么每次会把一批行 ID 作为一次请求去访问 Table 数据，这个参数可以设置 Batch 的大小，较大的 Batch 会使得延迟增加，较小的 Batch 可能会造成更多的查询次数。这个参数的合适大小与查询涉及的数据量有关。一般不需要调整。

tidb_index_lookup_concurrency

如果是需要访问索引获取行 ID 之后再访问 Table 数据，每次通过行 ID 获取数据时候的并发度通过这个参数调节。

 tidb_index_serial_scan_concurrency


 