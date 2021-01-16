# TiUP集成套件工具原理与使用笔记

> - [bin](#bin目录)
> - [components](#components目录)
> - [data](#data目录)
> - [logs](#logs目录)
> - [manifests](#manifests目录)
> - [storage](#storage目录)
> - [telemetry](#telemetry目录)
> - [tiup.toml](#tiup.toml目录)


## 目录结构
在.tiup目录下，会存在一个tiup.toml文件，里面记录了tiup所要拉去的镜像路径；  
如果是联网环境下，可以把该路径改为 pingcap 官方网站的录取路径；   
如果是离线环境下，tiup 相关命令的拉去路径为自己上传的 tiup 压缩包解压的路径；

```
[tidb@tiup-tidb41 .tiup]$ cat tiup.toml 
mirror = "/home/tidb/tidb-community-server-v4.0.9-linux-amd64"
```

#### bin目录
在 bin 目录下，
```
[tidb@tiup-tidb41 bin]$ ll
total 24952
-rw-r--r-- 1 tidb tidb     5221 Jan 10 00:54 root.json
-rwxr-xr-x 1 tidb tidb 25542656 Dec 31 04:39 tiup
```

```
{
    "signatures":[
        {
            "keyid":"34c12305009799580e8a9ef681561858dabadce758644e07303bbe5000e36398",
            "sig":"M/0YF18jfrezjUxP0+grLxVVP1bp41BG7kQ1EJQ1jc/H6zG3ND8vPxgVVdGpzTJABSHsy7DD3aSmwzJDuEyToTJFBERqWCIqYfezevCaW0h0+B3Z5cICo1VqoJOgp8jtw15vH+BPX9T9H1oM2fPV7eEJHmMqKJMDmiGq5R94GdZLatAz2eyXzUf8JRs9IY4YvQDcZhdeliBYppfIQ384k4KLpBLSMfZoD68SdQMsqVSHSjs1s9wdmisKwfiKqHdI2ZfAd/sa3UW8VbkFX7CVX/uNqJAAzeqQVqX1q8x7o0ph8ngbFU0Lxx+ne0xfo2z+apFmjHRDiEwhkNTP46rWBw=="
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
                        "keyval":{
                            "public":"-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAre8CBlA/SBwH74My3pXJ
fkeQ67H4hgP2Juib79ir5gMbIiS+xuhTzV6BlA7b3lbYEByq3YQo4qKp8ZkbqQb6
YyEh+oXA0VtXixeUKQOVk07A4qFZamicbycpr5snLp0XHUXlgwXkOzumW3B1Zzso
wpSC+EGRVFm0r9oESbBdiE1nrwV/VZ9IQ1UCiSkoBP1QdRXkPcoIA22rP8P+kpz1
ESsOl9f0M8FedXoubagwuFIfLH3abtZZYvWXtt/Xy01oefALarTL8AXIEzu0pndi
nyfxh/LA+gxXP4Gic07HxVsysMF7+sloRArj/sx9rQMH7tT2vXEDkVN/EzlE1yxt
EQIDAQAB
-----END PUBLIC KEY-----
"
                        },
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
                        "keyval":{
                            "public":"-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwbKgSL9L/20F76C2Ep3g
M5FY83yXwvpngisbpXRvXH2whrTUb3+sOr2G0DUFcupNOiC5hqk6RrAgYFhXWRYh
uu7629hXufuOqj7LPEv85cGBZiNP7f11RGrln+l5QahLSEUcLne+QVGCqpAtjCX1
j72+d9+kKX74e24dzDH4gc/4jl2HCzgQ9UcLo9g1Q3rRikoj57zlt10F7sYp/zS8
+qPychDCE0Xm0KQBVtg32TU4Ozrc8Zx9e6v+GymwYUM5iPp23lSJogD9NpfUCMOm
8R+1oUn30LmhZTc9V9lH+uNQahxUh0GFl6S9ZfYiyZZya37iVygD3gDIi7sEAV+I
nQIDAQAB
-----END PUBLIC KEY-----
"
                        },
                        "scheme":"rsassa-pss-sha256"
                    },
                    "34c12305009799580e8a9ef681561858dabadce758644e07303bbe5000e36398":{
                        "keytype":"rsa",
                        "keyval":{
                            "public":"-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsayz7nyKYFMYMvvnJxl/
jSlQPjhmBVArOGcunStNwufYdTkYnnzUMTCoOgvqBz96SDv0xriYL3WrRAsPvchb
7e3K4OIGeh9uTWy1FhaVo5PsSPdD9ytD9YKgb5FSLQbAE5R0B6aUgDhIyfC+OaM8
tmBWCMuOqacONBCvuLV0hWig3j31+ctUZNIlAdaBK7rukUyAzpo/XSvERhvDG/Wb
3O58NGzKGKy0j2r4dOp3OE4zDQ0UUulw072FaHBQOj+YlPkvXnl46ZQial8f//E2
Ni9JKVSk7vikba7YRZbRe4dg4yVzFLyIqFJ59RshE5isqSPL0VjTz7UdCwIpZJxd
8wIDAQAB
-----END PUBLIC KEY-----
"
                        },
                        "scheme":"rsassa-pss-sha256"
                    },
                    "89d3a1fff58e75a8a4eb8625e94372774087384cab9573652c8f5993438511e5":{
                        "keytype":"rsa",
                        "keyval":{
                            "public":"-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzmNXFbwAC2HsdBlx+uPg
ixqokwbnqTb/XYWFcsJKiLNAzv0iJ02UrXU6hX6SykjhDnnTujPCf6y/58/WdH8j
LOoKHN437azn39BgP0vI4q0fG9bvxJbzQYD6SAMJPqDFkituIHXqH7yy4UQcvdW3
wPiA6IRWvTl6boBliT5wwJDH39y8VARmKqryl8tA+JXJelLPd7t6fCQMVcphfKg3
sHRzORaHlAI/ot4/DXcr/ctlXhHG8dQ7kcdPpj8oErzkqww123jXH6Dsbl7zqwgA
wNrxHgVl0lCshliCxIE/lOmCQkC92NC06plnjIsmgjXVEKoq/FE/7u2G+JcJ36Mn
3wIDAQAB
-----END PUBLIC KEY-----
"
                        },
                        "scheme":"rsassa-pss-sha256"
                    }
                },
                "threshold":3,
                "url":"/root.json"
            },
            "snapshot":{
                "keys":{
                    "d5d0a867b9214000c56d32103a585fa50bcf2561877a725333f51cd81233eb95":{
                        "keytype":"rsa",
                        "keyval":{
                            "public":"-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAn+qTp8L2YeipQIJk2XAT
+rmX7fZ8sIphTSBPJDs0VzP2vMopzWJcd4Xto4SkiYBYjCKB0wV1XSqGaiuhK3LP
hyIxLC5RIx7lSmad6JfgGkJne5bt9G3p4FnsBFnbH5cdfHMUTyxKepUylK5Flprz
dX1X/7ntYUOFc6Di2EWJinYin2Jhg15yJRSvJVYxcPTKVIHPmXrNV+FtNcy8pcN/
PJhZCI8YE52vFTR6nf9l2H6lnA6sJloLGpUNJaKALNqLnOSuwVcJGYv3gcEQcSEy
0jJsO2qh+p2KIUX+7gZxvt6pWlXtIcYQVf1PEJhOd3NaeCw7dvd7PK5d1Z9gImQh
3wIDAQAB
-----END PUBLIC KEY-----
"
                        },
                        "scheme":"rsassa-pss-sha256"
                    }
                },
                "threshold":1,
                "url":"/snapshot.json"
            },
            "timestamp":{
                "keys":{
                    "c7c1dd913b399076243eb30b83beecb112b6ca9b2f448ade69247559546240dc":{
                        "keytype":"rsa",
                        "keyval":{
                            "public":"-----BEGIN PUBLIC KEY-----
MIIBIjANBg......
-----END PUBLIC KEY-----
"
                        },
                        "scheme":"rsassa-pss-sha256"
                    }
                },
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
#### data目录
#### logs目录


#### manifests目录

manifests 中记录了不同组件版本信息，以 json 格式存在，如：alertmanager（告警组件）、bench（基准测试组件）、（集群组件）的信息。
```
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


#### telemetry目录




