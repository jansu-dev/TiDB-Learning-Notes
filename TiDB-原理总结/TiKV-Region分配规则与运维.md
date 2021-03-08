# TiKV-Region分配规则与运维
时间:2021-03-02



单个节点的参数设置只会对该节点的 region 有效，如果有 region 的迁移，会重新按照新节点的参数设置进行一系列的操作



将 Region 元信息从 etcd 移到 go-leveldb 存储引擎，解决大规模集群 etcd 存储瓶颈问题

v3.0 版本起，PD 默认开启配置项 use-region-storage，将 Region Meta 信息存在本地的 LevelDB 中，并通过其他机制同步 PD 节点间的信息 [切换 PD Leader 的速度慢](https://docs.pingcap.com/zh/tidb/stable/massive-regions-best-practices#%E5%88%87%E6%8D%A2-pd-leader-%E7%9A%84%E9%80%9F%E5%BA%A6%E6%85%A2)



[tikvclient: refine region-cache--issue](https://github.com/pingcap/tidb/pull/10256)


[TiDB 源码阅读系列文章（十八）tikv-client（上）-- Region 元数据信息](https://pingcap.com/blog-cn/tidb-source-code-reading-18/#%E5%A6%82%E4%BD%95%E5%AE%9A%E4%BD%8D-key-%E6%89%80%E5%9C%A8%E7%9A%84-tikv-server)









```sql

MySQL [(none)]> use jan

MySQL [jan]> create table jan_test_table(id int,name varchar(20));

MySQL [jan]> insert into jan_test_table values (1,'jan_value_1');

MySQL [jan]> show table jan_test_table regions;
+-----------+-----------+---------+-----------+-----------------+---------+------------+---------------+------------+----------------------+------------------+
| REGION_ID | START_KEY | END_KEY | LEADER_ID | LEADER_STORE_ID | PEERS   | SCATTERING | WRITTEN_BYTES | READ_BYTES | APPROXIMATE_SIZE(MB) | APPROXIMATE_KEYS |
+-----------+-----------+---------+-----------+-----------------+---------+------------+---------------+------------+----------------------+------------------+
|         2 | t_69_     |         |         3 |               1 | 3, 6, 7 |          0 |         26582 |       3324 |                    1 |             2334 |
+-----------+-----------+---------+-----------+-----------------+---------+------------+---------------+------------+----------------------+------------------+
1 row in set (0.04 sec)
```


查找当前所有的 store_id  
```shell
[tidb@tidb-51-pd bin]$ ./pd-ctl -u 192.168.169.51:2379 store |grep "id" |grep -v deploy_path
        "id": 1,
        "id": 4,
        "id": 5,

[tidb@tidb-51-pd bin]$ ./pd-ctl -u 192.168.169.51:2379 store
{
  "count": 3,
  "stores": [
    {
      "store": {
        "id": 4,
        "address": "192.168.169.52:20160",
        "version": "5.0.0-rc",
        "status_address": "192.168.169.52:20180",
        "git_hash": "901f62d0ebe67db5d59402b31603b9aa903eb3e1",
        "start_timestamp": 1614826388,
        "deploy_path": "/data/tidb-deploy/tikv-20160/bin",
        "last_heartbeat": 1614851412185271431,
        "state_name": "Up"
      },
      "status": {
        "capacity": "49.69GiB",
        "available": "43.49GiB",
        "used_size": "33.83MiB",
        "leader_count": 0,
        "leader_weight": 1,
        "leader_score": 0,
        "leader_size": 0,
        "region_count": 2,
        "region_weight": 1,
        "region_score": 16.371531365002888,
        "region_size": 2,
        "start_ts": "2021-03-03T21:53:08-05:00",
        "last_heartbeat_ts": "2021-03-04T04:50:12.185271431-05:00",
        "uptime": "6h57m4.185271431s"
      }
    },
    {
      "store": {
        "id": 5,
        "address": "192.168.169.53:20160",
        "version": "5.0.0-rc",
        "status_address": "192.168.169.53:20180",
        "git_hash": "901f62d0ebe67db5d59402b31603b9aa903eb3e1",
        "start_timestamp": 1614826388,
        "deploy_path": "/data/tidb-deploy/tikv-20160/bin",
        "last_heartbeat": 1614851412166475069,
        "state_name": "Up"
      },
      "status": {
        "capacity": "46.54GiB",
        "available": "42.06GiB",
        "used_size": "33.81MiB",
        "leader_count": 0,
        "leader_weight": 1,
        "leader_score": 0,
        "leader_size": 0,
        "region_count": 2,
        "region_weight": 1,
        "region_score": 17.31060590187915,
        "region_size": 2,
        "start_ts": "2021-03-03T21:53:08-05:00",
        "last_heartbeat_ts": "2021-03-04T04:50:12.166475069-05:00",
        "uptime": "6h57m4.166475069s"
      }
    },
    {
      "store": {
        "id": 1,
        "address": "192.168.169.51:20160",
        "version": "5.0.0-rc",
        "status_address": "192.168.169.51:20180",
        "git_hash": "901f62d0ebe67db5d59402b31603b9aa903eb3e1",
        "start_timestamp": 1614826387,
        "deploy_path": "/data/tidb-deploy/tikv-20160/bin",
        "last_heartbeat": 1614851410934574688,
        "state_name": "Up"
      },
      "status": {
        "capacity": "49.69GiB",
        "available": "39.61GiB",
        "used_size": "33.78MiB",
        "leader_count": 2,
        "leader_weight": 1,
        "leader_score": 2,
        "leader_size": 2,
        "region_count": 2,
        "region_weight": 1,
        "region_score": 17.560142638796684,
        "region_size": 2,
        "start_ts": "2021-03-03T21:53:07-05:00",
        "last_heartbeat_ts": "2021-03-04T04:50:10.934574688-05:00",
        "uptime": "6h57m3.934574688s"
      }
    }
  ]
}
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








