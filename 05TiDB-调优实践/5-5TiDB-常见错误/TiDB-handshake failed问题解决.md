# TiDB-handshake failed问题解决



## tiup scale-out报错
```
[tidb@tiup-tidb01 pump]$  tiup cluster scale-out tidb-test binglog-scale-out.yaml --wait-timeout 10000000
Starting component `cluster`: /home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster scale-out tidb-test binglog-scale-out.yaml --wait-timeout 10000000
Please confirm your topology:
Cluster type:    tidb
Cluster name:    tidb-test
Cluster version: v4.0.9
......
......
Error: Failed to initialize TiDB environment on remote host '192.168.169.45' (task.env_init.failed)
  caused by: Failed to create '~/.ssh' directory for user 'tidb'
    caused by: Failed to execute command over SSH for 'tidb@192.168.169.45:22'
      caused by: ssh: handshake failed: ssh: unable to authenticate, attempted methods [none publickey], no supported methods remain

Verbose debug logs has been written to /home/tidb/.tiup/logs/tiup-cluster-debug-2021-01-19-22-50-47.log.
Error: run `/home/tidb/.tiup/components/cluster/v1.3.1/tiup-cluster` (wd:/home/tidb/.tiup/data/SMbQrXK) failed: exit status 1
```


```
[tidb@tiup-tidb01 pump]$ ssh-copy-id -i ~/.ssh/id_rsa.pub 192.168.169.45
/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/tidb/.ssh/id_rsa.pub"
/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
tidb@192.168.169.45's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh '192.168.169.45'"
and check to make sure that only the key(s) you wanted were added.


```


## 参考文章

[tidb集群无法安装成功](https://asktug.com/t/topic/66239)