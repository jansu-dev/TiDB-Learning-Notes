# TiDB-4.0.9版本开始tiflash组件弃用path警告问题
> - [报错提示](#报错提示)
> - [相关信息](#相关信息)
> - [解决办法](#解决办法)


## 报错提示
```
[root@tiup-tidb44 log]# pwd
/data/tidb-deploy/tiflash-9000/log

[root@tiup-tidb44 log]# less tiflash_error.log
......
......
2021.01.10 03:50:11.467565 [ 1 ] <Warning> Application: The configuration "path" is deprecated. Check [storage] section for new style.
```


## 相关信息

[官方文档：v4.0.9 及以下 tiflash 多盘部署](https://docs.pingcap.com/zh/tidb/stable/tiflash-configuration#tidb-%E9%9B%86%E7%BE%A4%E7%89%88%E6%9C%AC%E4%BD%8E%E4%BA%8E-v409)
[官方文档：v4.0.9 及以上 tiflash 多盘部署](https://docs.pingcap.com/zh/tidb/stable/tiflash-configuration#tidb-%E9%9B%86%E7%BE%A4%E7%89%88%E6%9C%AC%E4%B8%BA-v409-%E5%8F%8A%E4%BB%A5%E4%B8%8A)
[官方文档：v4.0.9 配置tiflash.toml文件参考](https://docs.pingcap.com/zh/tidb/stable/tiflash-configuration#%E9%85%8D%E7%BD%AE%E6%96%87%E4%BB%B6-tiflashtoml)


## 解决办法
参照相关信息中的提示信息，添加storage的新信息
，并注释掉path的旧信息

```
[root@tiup-tidb44 conf]# pwd
/data/tidb-deploy/tiflash-9000/conf

[root@tiup-tidb44 conf]# vi tiflash.toml

......
......
#path = "/data/tiflash1/data,/data/tiflash2/data"
......
......
[storage]
    [storage.main]
    dir = [ "/data/tiflash1/data", "/data/tiflash2/data" ]

    [storage.latest]
......
......
```

重启tiflash-9000服务
```
[root@tiup-tidb44 tidb-deploy]# pwd
/data/tidb-deploy


[root@tiup-tidb44 conf]# ps -ef|grep tiflash
tidb       1117      1  3 03:47 ?        00:01:18 bin/tiflash/tiflash server --config-file conf/tiflash.toml
root       6025   1670  0 04:21 pts/0    00:00:00 grep --color=auto tiflash


[root@tiup-tidb44 tidb-deploy]# ll
total 12
drwxr-xr-x 4 tidb tidb 4096 Jan 10 00:46 install
drwxr-xr-x 6 tidb tidb 4096 Jan  9 10:45 monitor-9100
drwxr-xr-x 7 tidb tidb 4096 Jan 10 00:56 tiflash-9000


[root@tiup-tidb44 tidb-deploy]# systemctl restart tiflash-9000


[root@tiup-tidb44 tidb-deploy]# ps -ef|grep tiflash
tidb       6117      1 16 04:21 ?        00:00:01 bin/tiflash/tiflash server --config-file conf/tiflash.toml
root       6332   1670  0 04:22 pts/0    00:00:00 grep --color=auto tiflash
```

可以看到在tiflash.log中出现CfgReloader的DEBUG信息，说明配置文件已经重载  
并且tiflash_error.log并没有报错，说明修改已经成功生效了
```
[root@tiup-tidb44 log]# pwd
/data/tidb-deploy/tiflash-9000/log


[root@tiup-tidb44 log]# ll
total 912
-rw-r--r-- 1 tidb tidb  50197 Jan 10 04:20 tiflash_cluster_manager.log
-rw-r--r-- 1 tidb tidb  30163 Jan 10 03:50 tiflash_error.log
-rw-r--r-- 1 tidb tidb 478129 Jan 10 04:22 tiflash.log
-rw-r--r-- 1 tidb tidb    540 Jan 10 04:21 tiflash_stderr.log
-rw-r--r-- 1 tidb tidb 347496 Jan 10 04:21 tiflash_tikv.log


[root@tiup-tidb44 log]# less tiflash.log
......
......
[2021/01/10 04:21:54.673 -05:00] [INFO] [<unknown>] ["Application: proxy is ready to serve, try to wake up all region leader by sending read index request"] [thread_id=1]
[2021/01/10 04:21:54.673 -05:00] [INFO] [<unknown>] ["Application: start to wait for terminal signal"] [thread_id=1]
[2021/01/10 04:21:56.270 -05:00] [DEBUG] [<unknown>] ["CfgReloader: Loading config `conf/tiflash.toml'"] [thread_id=6]
......
......
```