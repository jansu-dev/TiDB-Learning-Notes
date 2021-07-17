# TiDB-TiDB集群参数归纳整理  
时间:2021-03-12


server_configs:
  tidb:
    binlog.enable: true
    log.level: info
    log.slow-threshold: 300
    lower-case-table-names: 1
    max-index-length: 6144
    mem-quota-query: 68719476736
    oom-action: cancel
    performance.max-procs: 0
    performance.max-txn-ttl: 7200000
    performance.stats-lease: 3s
    performance.stmt-count-limit: 50000
    performance.txn-total-size-limit: 2147483648
    pessimistic-txn.enable: true
    pessimistic-txn.max-retry-count: 256
    prepared-plan-cache.capacity: 100
    prepared-plan-cache.enabled: false
    prepared-plan-cache.memory-guard-ratio: 0.1
    token-limit: 3000
  tikv:
    log-level: info
    pessimistic-txn.enabled: true
    raftdb.defaultcf.dynamic-level-bytes: true
    readpool.coprocessor.high-concurrency: 8
    readpool.coprocessor.low-concurrency: 8
    readpool.coprocessor.normal-concurrency: 8
    readpool.storage.high-concurrency: 4
    readpool.storage.low-concurrency: 4
    readpool.storage.normal-concurrency: 4
    readpool.unified.max-thread-count: 25
    rocksdb.lockcf.dynamic-level-bytes: true
    rocksdb.writecf.dynamic-level-bytes: true
    server.grpc-concurrency: 4
    storage.block-cache.capacity: 256GB
  pd:
    replication.location-labels:


    
## 压测(xyy)

```
raftdb.use-direct-io-for-flush-and-compaction: true
raftstore.hibernate-regions: false
rocksdb.use-direct-io-for-flush-and-compaction: true

gc.compaction-filter-skip-version-check: true
gc.enable-compaction-filter: true

readpool.storage.use-unified-pool: true
readpool.unified.max-thread-count: 4

raftdb.max-background-jobs: 3
raftdb.max-sub-compactions: 1

raftdb.defaultcf.max-bytes-for-level-base: 4 GB
raftdb.defaultcf.max-write-buffer-number: 32
raftdb.defaultcf.write-buffer-size: 128 MB
raftdb.defaultcf.level0-file-num-compaction-trigger: 40
raftdb.defaultcf.level0-slowdown-writes-trigger: 65
raftdb.defaultcf.level0-stop-writes-trigger: 96

rocksdb.rate-bytes-per-sec: 50MB
rocksdb.max-background-jobs: 3
rocksdb.max-sub-compactions: 2

rocksdb.defaultcf.max-bytes-for-level-base: 4 GB
rocksdb.defaultcf.max-write-buffer-number: 32
rocksdb.defaultcf.write-buffer-size: 131MB
rocksdb.defaultcf.level0-file-num-compaction-trigger: 40
rocksdb.defaultcf.level0-slowdown-writes-trigger: 64
rocksdb.defaultcf.level0-stop-writes-trigger: 96

rocksdb.writecf.max-bytes-for-level-base: 4 GB
rocksdb.writecf.max-write-buffer-number: 32
rocksdb.writecf.write-buffer-size: 128 MB
rocksdb.writecf.level0-file-num-compaction-trigger: 40
rocksdb.writecf.level0-slowdown-writes-trigger: 64
rocksdb.writecf.level0-stop-writes-trigger: 96

rocksdb.lockcf.max-bytes-for-level-base: 4 GB
rocksdb.lockcf.max-write-buffer-number: 32
rocksdb.lockcf.write-buffer-size: 128 MB
rocksdb.lockcf.level0-file-num-compaction-trigger: 40
rocksdb.lockcf.level0-slowdown-writes-trigger: 64
rocksdb.lockcf.level0-stop-writes-trigger: 96
```