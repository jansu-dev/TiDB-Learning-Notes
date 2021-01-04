# 基准测试简介与操作流程

## summary
> - [sysbench](#sysbench)
> - [测试CPU性能](#测试CPU性能)
> - [测试IO性能](#测试IO性能)
> - [测试内存性能](#测试内存性能)
> - [测试OLTP性能](#测试OLTP性能)


## sysbench

* **sysbench是什么？**
在sysbench主要支持 MySQL,pgsql,oracle 这3种数据库



* **sysbench部署**
sysbench安装步骤如下所示，主要分为依赖安装、软件部署、验证安装三个部分。
```shell

# 安装相关依赖
yum -y install  make automake libtool pkgconfig libaio-devel vim-common

# sysbench安装
yum list
yum install sysbench

# 验证sysbench正确安装，并查看sysbench版本
sysbench --version
```

* [**sysbench project link** :https://github.com/akopytov/sysbench](https://github.com/akopytov/sysbench)


### 测试CPU性能

* **CPU基准测试参数**

| 参数名 | 参数值 | 参数涵义 |
| --- | --- | --- |
| cpu-max-prime | 2000 | 素数生成数量的上限。若设置为3，则表示2、3、5(这样要计算1-5共5次),若设置为10，则表示2、3 ~ 23、29(这样要计算1-29共29次)默认值为10000 |
| threads | 线程数 | 若设置为1，则sysbench仅启动1个线程进行素数的计算,若设置为2，则sysbench会启动2个线程，同时分别进行素数的计算,默认值为1 |
| time | 运算时长(秒) | 若设置为5，则sysbench会在5秒内循环往复进行素数计算，从输出结果可以看到在5秒内完成了几次，比如配合--cpu-max-prime=3，则表示第一轮算得3个素数，如果时间还有剩就再进行一轮素数计算，直到时间耗尽。每完成一轮就叫一个event，默认值为10，相同时间，比较的是谁完成的event多 |
| event | 上限次数 | 默认值为0，则表示不限event次数,若设置为100，则表示当完成100次event后，即使时间还有剩，也停止运行,相同event次数，比较的是谁用时更少 |

* **CPU基准测试讲解**
```shell
[tidb@tidb01-41 tidb-ansible]$ sysbench cpu --cpu-max-prime=20000 --threads=2 run
sysbench 1.0.17 (using system LuaJIT 2.0.4)

Running the test with following options:
Number of threads: 2    # 指定用来计算素数的线程数量
Initializing random number generator from current time


Prime numbers limit: 20000 # 每个线程查安生的素数上限均为20000个

Initializing worker threads...

Threads started!

CPU speed:
    events per second:  1005.43 # 所有线程平均计算每秒完成1005次event

General statistics:
    total time:                          10.0014s  # 完成的event总耗时
    total number of events:              10057     # 完成的event总次数

Latency (ms):
         min:                                    1.85 # 时间维度：完成1次event的最小耗时
         avg:                                    1.99 # 时间维度：所有envet完成的平均耗时
         max:                                   24.43 # 时间维度：所有event中的最大耗时
         95th percentile:                        2.18 # 时间维度：95%分布位置的时间耗时
         sum:                                19992.32 # 时间维度：所有event的耗时总计

Threads fairness:  # 线程平均维度
    events (avg/stddev):           5028.5000/5.50 # 线程平均维度：平均每个线程执行的event数/所有线程执行event的标准差
    execution time (avg/stddev):   9.9962/0.00 # # 线程平均维度：每个线程平均耗时时间/所有线程执行event的耗时标准差
```

* **2台服务器CPU性能对比基本方法**

当素数上限和线程数一致时：
相同时间，比较event谁更多
相同event，比较时间谁更少
时间和event都相同，比较stddev(标准差)谁更低


### 测试IO性能

* **I/O基准测试参数**

| 参数名 | 参数翻译 | 参数涵义 |
| --- | --- | --- |
| file-num=N | 文件数量 | 创建测试文件的数量。默认是128 |
| file-block-size=N | 测试时文件块大小 |  默认是16384(16K) |
| file-total-size=SIZE | 测试文件总大小| 默认是2G。 |
| file-test-mode=STRING | 文件测试模式 | 文件测试模式{seqwr(顺序写), seqrewr(顺序读写), seqrd(顺序读), rndrd(随机读), rndwr(随机写), rndrw(随机读写)} |
| file-io-mode=STRING | 文件I/O模式 | 文件操作模式{sync(同步),async(异步),fastmmap(快速map映射),slowmmap(慢map映射)}。默认是sync |
| file-extra-flags=STRING | 使用额外的标志来打开文件 | {sync,dsync,direct} ，默认为空 |
| file-fsync-freq=N | fsync频率 | 执行fsync()的频率。(0 – 不使用fsync())。默认是100 |
| file-fsync-all[=on/off] | 每执行完一次写操作就执行一次fsync | 默认是off。|
| file-fsync-end[=on/off] | 测试结束时才执行fsync |  默认是on。|
| file-fsync-mode=STRING | 同步模式 | 使用哪种方法进行同步{fsync, fdatasync}。默认是fsync。 |
| file-merged-requests=N | 合并I/O次数 | 如果可以，合并最多的IO请求数(0 – 表示不合并)。默认是0。 |
| file-rw-ratio=N | 测试时读写比例 |  默认是1.5。 |


* **I/O基准测试讲解**

prepare阶段：生成测试所需要的文件。
```shell
[tidb@tidb01-41 sysbench]$ sysbench --test=fileio --num-threads=16 --file-total-size=2G --file-test-mode=rndrw prepare
Creating file test_file.1

......
......

Creating file test_file.127
2147483648 bytes written in 43.20 seconds (47.41 MiB/sec).
```

run阶段：生成测试所需要的文件。
```shell
[tidb@tidb01-41 sysbench]$ sysbench --test=fileio --num-threads=20 --file-total-size=2G --file-test-mode=rndrw run
WARNING: the --test option is deprecated. You can pass a script name or path on the command line without any options.
WARNING: --num-threads is deprecated, use --threads instead
sysbench 1.0.17 (using system LuaJIT 2.0.4)

Running the test with following options:
Number of threads: 20  # 用来I/O文件的线程数
Initializing random number generator from current time


Extra file open flags: (none) # 是否使用其它符号打开文件
128 files, 16MiB each  # 文件总数量，每个文件的大小
2GiB total file size # 文件总大小
Block size 16KiB  # 单次I/O容量
Number of IO requests: 0
Read/Write ratio for combined random IO test: 1.50 # 读写比例
Periodic FSYNC enabled, calling fsync() each 100 requests. # 开启fsync，每100个请求进行一次fsync同步
Calling fsync() at the end of test, Enabled.  # 最后结束的时候进行fsync操作
Using synchronous I/O mode
Doing random r/w test
Initializing worker threads...

Threads started!


File operations:
    reads/s:                      5625.14 
    writes/s:                     3749.93
    fsyncs/s:                     12244.30

Throughput:
    read, MiB/s:                  87.89  # 吞吐量：平均每秒读取87MB/s
    written, MiB/s:               58.59  # 吞吐量：每秒每秒读取58MB/s

General statistics:
    total time:                          10.0147s  # 总好费时间
    total number of events:              213978    # 同执行event数量

Latency (ms):
         min:                                    0.00  # 时间维度：最小I/O请求耗费时间
         avg:                                    0.93  # 时间维度：平均每次I/O请求耗费时间
         max:                                  292.48  # 时间维度：最大I/O请求耗费时间
         95th percentile:                        2.91  # 时间维度：95%分位位置处的I/O请求耗费时间
         sum:                               199618.07  # 时间维度：总耗时

Threads fairness:
    events (avg/stddev):           10698.9000/647.23  # 线程均分维度：平均线程event执行数/标准差
    execution time (avg/stddev):   9.9809/0.01  # 线程均分维度：线程执行时间均数/标准差
```

cleanup阶段：清理测试文件。
```
[tidb@tidb01-41 sysbench]$ sysbench --test=fileio --num-threads=20 --file-total-size=2G --file-test-mode=rndrw cleanup

WARNING: the --test option is deprecated. You can pass a script name or path on the command line without any options.
WARNING: --num-threads is deprecated, use --threads instead
sysbench 1.0.17 (using system LuaJIT 2.0.4)

Removing test files...


[tidb@tidb01-41 sysbench]$ ll
total 0
```


### 测试内存性能

* **Memory基准测试参数**

| 参数名 | 参数翻译 | 参数涵义 |
| --- | --- | --- |
| memory-block-size=SIZE  | 测试时内存块大小 |  默认是1K |
| memory-total-size=SIZE | 传输数据的总大小 | 默认是100G |
| memory-scope=STRING | 内存访问范围 | {global,local}，默认是global |
| memory-oper=STRING | 内存操作类型 | {read, write, none} ，默认是write |
| memory-access-mode=STRING | 存储器存取方式 | {seq,rnd} 默认是seq |

* **Memory基准测试讲解**
```shell
[tidb@tidb01-41 sysbench]$ sysbench --num-threads=12 --max-requests=10000 --test=memory --memory-block-size=8K --memory-total-size=100G --memory-access-mode=seq run
WARNING: the --test option is deprecated. You can pass a script name or path on the command line without any options.
WARNING: --num-threads is deprecated, use --threads instead
WARNING: --max-requests is deprecated, use --events instead
sysbench 1.0.17 (using system LuaJIT 2.0.4)

Running the test with following options:
Number of threads: 12
Initializing random number generator from current time


Running memory speed test with the following options:
  block size: 8KiB
  total size: 102400MiB
  operation: write
  scope: global

Initializing worker threads...

Threads started!

Total operations: 13107192 (2675218.69 per second)

102399.94 MiB transferred (20900.15 MiB/sec)  # 总传送10G数据，平均每秒2G数据读取吞吐


General statistics:
    total time:                          4.8984s
    total number of events:              13107192

Latency (ms):
         min:                                    0.00
         avg:                                    0.00
         max:                                   81.91
         95th percentile:                        0.00
         sum:                                49597.31

Threads fairness:
    events (avg/stddev):           1092266.0000/0.00
    execution time (avg/stddev):   4.1331/0.25
```


* **内存基准测试比较** 不同块大小传输一定数量的数据吞吐量越大越好
```
sysbench --num-threads=12 --max-requests=10000 --test=memory --memory-block-size=8K --memory-total-size=100G --memory-access-mode=seq run #顺序读 8k
sysbench --num-threads=12 --max-requests=10000 --test=memory --memory-block-size=8K --memory-total-size=100G --memory-access-mode=rnd run #随机读 8k
```


### 测试OLTP性能

* **OLTP基准测试参数**

| 参数名 | 参数翻译 | 参数涵义 |
| --- | --- | --- |
| --oltp-test-mode=STRING | 测试类型 |simple(简单select测试),complex(事务测试),nontrx(非事务测试),sp(存储过程) ；默认complex |
| --oltp-reconnect-mode=STRING | 连接类型 | session(每个线程到测试结束不重新连接),| transaction(执行每个事务重新连接),query(每一个查询重新连接),random(随机)；默认 [session] |
| --oltp-sp-name=STRING | 指定执行测试的存储过程名 |  |
| --oltp-read-only=[on\off] | 仅执行select测试 | 默认关闭 |
| --oltp-avoid-deadlocks=[on\off] | 更新过程中忽略死锁 |  默认[off] |
| --oltp-skip-trx=[on\off] | 语句以bigin/commit开始结尾 | 默认[off] |
| --oltp-range-size=N | 范围查询的范围大小 | 默认 [100]，例如begin 100 and 200 |
| --oltp-point-selects=N | 单个事务中select查询的数量 | 默认 [10] |
| --oltp-use-in-statement=N | 每个查询中主键查找(in 10个值)的数量 | 默认 [0] |
| --oltp-simple-ranges=N | 单个事务中执行范围查询的数量 |  (SELECT c FROM sbtest | WHERE id BETWEEN N AND M)，默认[1] |
| --oltp-sum-ranges=N | 单个事务中执行范围sum查询的数量 | 默认 [1] |
| --oltp-order-ranges=N | 单个事务中执行范围order by查询的数量 | 默认[1] |
| --oltp-distinct-ranges=N  | 单个事务中执行范围distinct查询的数量 | 默认[1] |
| --oltp-index-updates=N | 单个事务中执行索引更新的操作的数量 |  默认[1] |
| --oltp-non-index-updates=N | 单个事务中执行非索引更新操作的数量 | 默认[1] |
| --oltp-nontrx-mode=STRING | 指定单独非事务测试类型进行测试 | 默认select {select, | update_key, update_nokey, insert, delete} [select] |
| --oltp-auto-inc=[on\off] | id列默认自增 | 默认[on] |
| --oltp-connect-delay=N | 指定每一次重新连接延时的时长 | 默认1秒 [10000] |
| --oltp-user-delay-min=N | 请求后最小睡眠时间 | minimum time in microseconds to sleep after each request [0] |
| --oltp-user-delay-max=N | 请求后最大睡眠时间 |  maximum time in microseconds to sleep after each request [0] |
| --oltp-table-name=STRING | 指定测试的表名 | 默认[sbtest] |
| --oltp-table-size=N | 指定表的记录大小 | 默认[10000] |
| --oltp-dist-type=STRING | 随机数分布状态 | uniform(均匀分布)、gauss(高斯分布)、special(特殊分布)，默认 [special] | 
| --oltp-dist-iter=N |  | number of iterations used for numbers generation [12]
| --oltp-dist-pct=N | 启用百分比特殊分布 | 默认 [1] |
| --oltp-dist-res=N | special 百分比 | 百分比[75] |
| --oltp-point-select-mysql-handler=[on\off] |  |  Use MySQL HANDLER for point select [off] | 
| --oltp-point-select-all-cols=[on\off] | select查询测试时select所有列 | 默认[off] |
| --oltp-secondary=[on\off]  | 索引不是主键索引而是二级索引 | 默认[off] |
| --oltp-num-partitions=N | 指定表分区的数量 | 默认 [0] |
| --oltp-num-tables=N | 指定测试表的数量 | 默认[1] |


* **OLTP基准测试比较**
```

```


## 参考文章

[美团tech：https://tech.meituan.com/2017/07/14/sysbench-meituan.html](https://tech.meituan.com/2017/07/14/sysbench-meituan.html)

[老叶茶馆：https://yq.aliyun.com/articles/640848](https://yq.aliyun.com/articles/640848)