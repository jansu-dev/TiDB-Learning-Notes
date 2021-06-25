# TiKV-Region 概念解析
时间:2021-03-02



## Region 概念基础





## Region 概念对比




```rust
/// Some information about the current region the coprocessor is running in.
#[derive(Debug, Clone)]
pub struct Region {
    pub id: u64,
    pub region_epoch: RegionEpoch,
}

#[derive(Debug, Clone)]
pub struct RegionEpoch {
    pub conf_ver: u64,
    pub version: u64,
}
```






[Internal Layout of a Heap Table File](https://www.interdb.jp/pg/pgsql01.html)



 - Region 定义 Region 内容，只有读操作涉及基于 region 信息定位数据，写操作仅需按照操作 KV 方式 append 写入，后期 Region 自动 Split 即可 ，因此 Region 信息都可以在 coprocessor 中找到，也是注释 **“region the coprocessor is running in”** 的原因。
 
 - RegionEpoch 记录 Region 的版本状态   
   - conf_ver 会在每次做 ConfChange 的时候递增    
   - version 则是会在每次做 split/merge 的时候递增     


[](https://zhuanlan.zhihu.com/p/24564094)



oracle block 

https://blog.51cto.com/luruoyu/624464     

同为逻辑概念 oracle 封装的是 C++ 的 seek 函数，该函数用于直接读取磁盘数据
而TiDB则封装的是 RocksDB 的调用接口，该借口调用 LSM tree 中存储的数据



## Region 信息存储


单个节点的参数设置只会对该节点的 region 有效，如果有 region 的迁移，会重新按照新节点的参数设置进行一系列的操作



将 Region 元信息从 etcd 移到 go-leveldb 存储引擎，解决大规模集群 etcd 存储瓶颈问题

v3.0 版本起，PD 默认开启配置项 use-region-storage，将 Region Meta 信息存在本地的 LevelDB 中，并通过其他机制同步 PD 节点间的信息 [切换 PD Leader 的速度慢](https://docs.pingcap.com/zh/tidb/stable/massive-regions-best-practices#%E5%88%87%E6%8D%A2-pd-leader-%E7%9A%84%E9%80%9F%E5%BA%A6%E6%85%A2)



[tikvclient: refine region-cache--issue](https://github.com/pingcap/tidb/pull/10256)


[TiDB 源码阅读系列文章（十八）tikv-client（上）-- Region 元数据信息](https://pingcap.com/blog-cn/tidb-source-code-reading-18/#%E5%A6%82%E4%BD%95%E5%AE%9A%E4%BD%8D-key-%E6%89%80%E5%9C%A8%E7%9A%84-tikv-server)



## Region 运维方法




```sql

MySQL [(none)]> use jan

MySQL [jan]> create table jan_test_table(id int,name varchar(20));

MySQL [jan]> insert into jan_test_table values (1,'jan_value_1');

MySQL [(none)]> show table jan.jan_test_table regions\G
*************************** 1. row ***************************
           REGION_ID: 7570
           START_KEY: t_394_
             END_KEY: 
           LEADER_ID: 7572
     LEADER_STORE_ID: 1003
               PEERS: 7571, 7572, 7573
          SCATTERING: 0
       WRITTEN_BYTES: 791
          READ_BYTES: 0
APPROXIMATE_SIZE(MB): 1
    APPROXIMATE_KEYS: 0
1 row in set (0.00 sec)

```


查找当前所有的 store_id  
```shell
[tidb@tidb-51-pd ~]$ tiup ctl pd -u 192.168.1.61:2379 store |grep -E "id" |grep -v "deploy_path"
Starting component `ctl`: /home/tidb/.tiup/components/ctl/v5.0.0-rc/ctl pd -u 192.168.1.61:2379 store
        "id": 1007,
        "id": 1003,
        "id": 1001,
[tidb@tidb-51-pd ~]$ tiup ctl tikv --host 192.168.1.61:20160 region-properties -r 7570
Starting component `ctl`: /home/tidb/.tiup/components/ctl/v5.0.0-rc/ctl tikv --host 192.168.1.61:20160 region-properties -r 7570
mvcc.min_ts: 18446744073709551615
mvcc.max_ts: 0
mvcc.num_rows: 0
mvcc.num_puts: 0
mvcc.num_deletes: 0
mvcc.num_versions: 0
mvcc.max_row_versions: 0
num_entries: 0
num_deletes: 0
num_files: 0
sst_files: 
middle_key_by_approximate_size: 

```

API获取表属性信息   

```shell
[tidb@tidb-51-pd bin]$ curl http://192.168.169.51:10080/schema/jan/jan_test_table
{
 "id": 69,
 "name": {
  "O": "jan_test_table",
  "L": "jan_test_table"
 },
 "charset": "utf8mb4",
 "collate": "utf8mb4_bin",
 "cols": [
  {
   "id": 1,
   "name": {
    "O": "id",
    "L": "id"
   },
   "offset": 0,
   "origin_default": null,
   "origin_default_bit": null,
   "default": null,
   "default_bit": null,
   "default_is_expr": false,
   "generated_expr_string": "",
   "generated_stored": false,
   "dependences": null,
   "type": {
    "Tp": 3,
    "Flag": 0,
    "Flen": 11,
    "Decimal": 0,
    "Charset": "binary",
    "Collate": "binary",
    "Elems": null
   },
   "state": 5,
   "comment": "",
   "hidden": false,
   "change_state_info": null,
   "version": 2
  },
  {
   "id": 2,
   "name": {
    "O": "name",
    "L": "name"
   },
   "offset": 1,
   "origin_default": null,
   "origin_default_bit": null,
   "default": null,
   "default_bit": null,
   "default_is_expr": false,
   "generated_expr_string": "",
   "generated_stored": false,
   "dependences": null,
   "type": {
    "Tp": 15,
    "Flag": 0,
    "Flen": 20,
    "Decimal": 0,
    "Charset": "utf8mb4",
    "Collate": "utf8mb4_bin",
    "Elems": null
   },
   "state": 5,
   "comment": "",
   "hidden": false,
   "change_state_info": null,
   "version": 2
  }
 ],
 "index_info": null,
 "constraint_info": null,
 "fk_info": null,
 "state": 5,
 "pk_is_handle": false,
 "is_common_handle": false,
 "comment": "",
 "auto_inc_id": 0,
 "auto_id_cache": 0,
 "auto_rand_id": 0,
 "max_col_id": 2,
 "max_idx_id": 0,
 "max_cst_id": 0,
 "update_timestamp": 423323266250702849,
 "ShardRowIDBits": 0,
 "max_shard_row_id_bits": 0,
 "auto_random_bits": 0,
 "pre_split_regions": 0,
 "partition": null,
 "compression": "",
 "view": null,
 "sequence": null,
 "Lock": null,
 "version": 3,
 "tiflash_replica": null,
 "is_columnar": false
}
```





