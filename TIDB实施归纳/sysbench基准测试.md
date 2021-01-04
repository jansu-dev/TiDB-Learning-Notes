# 基准测试简介与操作流程

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

[**sysbench project link** :https://github.com/akopytov/sysbench](https://github.com/akopytov/sysbench)


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

2台服务器CPU性能对比基本方法：

当素数上限和线程数一致时：
相同时间，比较event谁更多
相同event，比较时间谁更少
时间和event都相同，比较stddev(标准差)谁更低


### 测试线程性能



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
```

```


### 测试内存性能


### 测试mutex


### 测试OLTP性能




## 参考文章

[美团tech：https://tech.meituan.com/2017/07/14/sysbench-meituan.html](https://tech.meituan.com/2017/07/14/sysbench-meituan.html)

[老叶茶馆：https://yq.aliyun.com/articles/640848](https://yq.aliyun.com/articles/640848)