# TiDB-TiUP集成套件工具原理与使用笔记

> - [tiup.toml文件](#tiup.toml文件)
> - [TiUP目录结构](#TiUP目录结构)
>    - [bin](#bin目录)
>    - [components](#components目录)
>    - [data](#data目录)
>    - [logs](#logs目录)
>    - [manifests](#manifests目录)
>    - [storage](#storage目录)
>    - [telemetry](#telemetry目录)
>    - [tiup.toml](#tiup.toml目录)

## tiup.toml文件
在.tiup目录下，会存在一个tiup.toml文件，里面记录了tiup所要拉去的镜像路径；  
如果是联网环境下，可以把该路径改为 pingcap 官方网站的录取路径；   
如果是离线环境下，tiup 相关命令的拉去路径为自己上传的 tiup 压缩包解压的路径；

```
[tidb@tiup-tidb41 .tiup]$ cat tiup.toml 
mirror = "/home/tidb/tidb-community-server-v4.0.9-linux-amd64"
```

## TiUP目录结构
```shell
# tiup 目录位置
[tidb@tiup-tidb41 .tiup]$ pwd
/home/tidb/.tiup

# tiup 目录结构
[tidb@tiup-tidb41 .tiup]$ tree -L 1
.
├── bin          # 存放二进制 tiup 可执行文件、安全通信的公私钥信息
├── components   # 存放使用 tiup 下载的组件的启动文件和依赖文件
├── data
├── logs         # 存放使用 TiUP 过程中产生的日志信息
├── manifests    # 存放 TiUP 各个组件不同版本的信息（版本号、hash值、拉取路径等）
├── storage      # 存放使用各组件的镜像压缩包解压内容
├── telemetry    # 存放遥测控制信息
└── tiup.toml     

7 directories, 1 file
```

#### bin目录
在 bin 目录下，

```shell
[tidb@tiup-tidb41 bin]$ ll
total 24952
-rw-r--r-- 1 tidb tidb     5221 Jan 10 00:54 root.json
-rwxr-xr-x 1 tidb tidb 25542656 Dec 31 04:39 tiup
```
 - root.json 主要存放一些签名信息，rsa 加密算法信息等
```json
[tidb@tiup-tidb41 bin]$ cat root.json
{
    "signatures":[
        {
            "keyid":"34c12305009799580e8a9ef681561858dabadce758644e07303bbe5000e36398",
            "sig":"M/0YF18jfrezjUxP0+g......"
        },
        Object{...},
        Object{...}
    ],
    "signed":{
        "_type":"root",
        "expires":"2070-12-28T02:40:40-05:00",
        "roles":{
            "index":{
                "keys":{
                    "6b41f6015fdb441edac3aee45f047281de3a749579d3e9d61330bd6f1fd47bc9":{
                        "keytype":"rsa",
                        "keyval":Object{...},
                        "scheme":"rsassa-pss-sha256"
                    }
                },
                "threshold":1,
                "url":"/index.json"
            },
            "root":{
                "keys":{
                    "231c93b183d187d4f8ecd8a48bb235d25b7b3ebf6f30ec48d313d8747f1217d4":{
                        "keytype":"rsa",
                        "keyval":Object{...},
                        "scheme":"rsassa-pss-sha256"
                    },
                    "34c12305009799580e8a9ef681561858dabadce758644e07303bbe5000e36398":{
                        "keytype":"rsa",
                        "keyval":Object{...},
                        "scheme":"rsassa-pss-sha256"
                    },
                    "89d3a1fff58e75a8a4eb8625e94372774087384cab9573652c8f5993438511e5":{
                        "keytype":"rsa",
                        "keyval":Object{...},
                        "scheme":"rsassa-pss-sha256"
                    }
                },
                "threshold":3,
                "url":"/root.json"
            },
            "snapshot":{
                "keys":Object{...},
                "threshold":1,
                "url":"/snapshot.json"
            },
            "timestamp":{
                "keys":Object{...},
                "threshold":1,
                "url":"/timestamp.json"
            }
        },
        "spec_version":"0.1.0",
        "version":1
    }
}
```


#### components目录
 - 该目录用于存放已经安装的组件的启动命令的二进制启动文件  
 - 也会存放一些依赖文件，如：jar包、库文件等...
```
[tidb@tiup-tidb41 components]$ tree -L 3
.
├── br
│   └── v4.0.9
│       └── br
├── cluster
│   └── v1.3.1
│       └── tiup-cluster
├── ctl
│   ├── v4.0.2
│   │   ├── binlogctl
│   │   ├── cdc
│   │   ├── ctl
......
......
```

#### data目录 

SLa... 等信息会在TiUP出现错误时出现
```
[tidb@tiup-tidb41 data]$ ll
total 0
drwxr-xr-x. 2 tidb tidb 6 Jan  9 06:18 SLavikg
drwxr-xr-x. 2 tidb tidb 6 Jan  9 06:18 SLavrCu
drwxr-xr-x. 2 tidb tidb 6 Jan  9 06:34 SLazrZB
drwxr-xr-x. 2 tidb tidb 6 Jan  9 06:35 SLb00ns
drwxr-xr-x. 2 tidb tidb 6 Jan  9 06:36 SLb0Dsk
drwxr-xr-x. 2 tidb tidb 6 Jan  9 06:36 SLb0P1O
drwxr-xr-x  2 tidb tidb 6 Jan 11 07:51 SLn0MdO
```

#### logs目录
存放了一些 tiup 部署过程中的日志信息
```
[tidb@tiup-tidb41 logs]$ ll -lrt|more |tail -4
-rw-r--r--  1 tidb tidb   3604 Jan 14 05:36 tiup-dm-debug-2021-01-14-05-36-59.log
-rw-r--r--  1 tidb tidb   2726 Jan 14 05:55 tiup-dm-debug-2021-01-14-05-55-19.log
-rw-r--r--  1 tidb tidb   2726 Jan 14 05:55 tiup-dm-debug-2021-01-14-05-55-31.log
-rw-r--r--  1 tidb tidb 122088 Jan 15 01:58 tiup-cluster-debug-2021-01-15-01-58-49.log
```

#### manifests目录

manifests 中记录了不同组件版本信息，以 json 格式存在，如：alertmanager（告警组件）、bench（基准测试组件）、（集群组件）的信息。
```shell
[tidb@tiup-tidb41 manifests]$ ll
total 396
-rw-r--r-- 1 tidb tidb   929 Jan 10 00:55 alertmanager.json  # alertmanager 组件的版本信息，及获取路径
-rw-r--r-- 1 tidb tidb  7678 Jan 11 07:51 bench.json         # bench 组件的版本信息，及获取路径
-rw-r--r-- 1 tidb tidb 20236 Jan 10 00:54 cluster.json       # cluster 组件的版本信息，及获取路径
............
............
```


```json
{
    "signatures":[
        {
            "keyid":"015f84e19bab02a9c......", 
            "sig":"bfCZLbPgKvC+49uL0zX......"
        }
    ],
    "signed":{
        "_type":"component",                   # 组件类型是 component
        "description":"tispark",               # 组件的描述是 tiSpark
        "expires":"2070-12-28T02:40:40-05:00", # 这个json文件的过期时间
        "id":"tispark", 
        "nightly":"",                          # 是否为 nightly（夜晚发布） 版本一般包含文件的最新功能，可能存在测试不足的情况
        "platforms":{
            "linux/amd64":{                    # 软件平台
                "v2.3.1":{                     # 版本号
                    "dependencies":null,       # 依赖信息
                    "entry":"tispark-assembly-2.3.1.jar",  # 组件包含的子包（条目)信息
                    "hashes":{
                        "sha256":"9df4d469ad......"        # 组件的 hash 值，防止伪造和串改
                    },
                    "length":22617157,                     # 该版本总长度（单位/bytes）
                    "released":"2020-07-09T15:59:03+08:00",# 该版本发布的时间
                    "url":"/tispark-v2.3.1-any-any.tar.gz",# 获取 tar 包的url子路径
                    "yanked":true                          # 是否允许被下载
                },
                "v2.3.10":Object{...},
                "v2.3.11":Object{...},
                "v2.3.2":Object{...},
                "v2.3.3":Object{...},
                "v2.3.4":Object{...},
                "v2.3.5":Object{...},
                "v2.3.6":Object{...},
                "v2.3.7":Object{...},
                "v2.3.8":Object{...},
                "v2.3.9":Object{...}
            }
        },
        "spec_version":"0.1.0",
        "version":12
    }
}
```


#### storage目录

 - 一些组件可能非常大，组件镜相包解压之后会有一些文件存于这个目录下，然后转发给其他节点  
 - 也会存放一些组件安装过程中的审计信息等...
```shell
[tidb@tiup-tidb41 storage]$ tree -L 2
.
├── br
├── cluster
│   ├── audit
│   ├── clusters
│   └── packages
├── ctl
├── dm
│   ├── audit
│   ├── clusters
│   └── packages
├── dmctl
├── dumpling
├── tidb-lightning
├── tiflash
├── tikv-importer
└── tispark

```

#### telemetry目录

用于存放 TiUP 遥测相关信息，TiDB 官方用于软件改进的信息搜集
```shell
[tidb@tiup-tidb41 .tiup]$ cd telemetry/

[tidb@tiup-tidb41 telemetry]$ ll
total 4
-rw-r--r--. 1 tidb tidb 58 Jan  9 00:50 meta.yaml

[tidb@tiup-tidb41 telemetry]$ cat meta.yaml 
uuid: 4eae5f76-ed60-4fb2-b651-5a3f53309859
status: enable
```

## 参考文件

[TiDB - TiUP 官方开源文档:https://gitee.com/mirrors/TiUP/tree/master/doc/design](https://gitee.com/mirrors/TiUP/tree/master/doc/design)
