# Component-Etcd原理与使用 
时间：2021-03-03   



## Summary  

> - [etcd快速开始](#etcd快速开始)   
> - [etcdctl命令实践](#etcdctl命令实践)   
> - [etcdctl参数实践](#etcdctl参数实践)   
> - [参考文章](#参考文章)   

## etcd快速开始
详情参考 [Etcd Docs -- Download and build](https://etcd.io/docs/v3.4.0/dl-build/)

 - 单机版本
  ```shell
   yum install -y go  
   yum install -y git 
   git clone https://github.com/etcd-io/etcd.git
   go build . 
   cd ./bin
   ./etcd --name jan --data-dir test.etcd
  ```
 - 集群版本
  ```shell
   THIS_NAME=${NAME_1}
   THIS_IP=${HOST_1}
   etcd --data-dir=data.etcd --name ${THIS_NAME} \
	   --initial-advertise-peer-urls http://${THIS_IP}:2380 --listen-peer-urls http://${THIS_IP}:2380 \
	   --advertise-client-urls http://${THIS_IP}:2379 --listen-client-urls http://${THIS_IP}:2379 \
	   --initial-cluster ${CLUSTER} \
	   --initial-cluster-state ${CLUSTER_STATE} --initial-cluster-token ${TOKEN}
  ```

  - Config文件启动   
  [etcd.conf.yml.sample](https://github.com/etcd-io/etcd/blob/release-3.4/etcd.conf.yml.sample)   
  ```yml
   # This is the configuration file for the etcd server.
   # Human-readable name for this member.
   name: 'jan-1'
   
   # Path to the data directory.
   data-dir: /root/etcd/jan-1.data
   
   # List of comma separated URLs to listen on for peer traffic.
   listen-peer-urls: http://192.168.169.51:2380
   
   # List of comma separated URLs to listen on for client traffic.
   listen-client-urls: http://192.168.169.51:2379
   
   # List of this member's peer URLs to advertise to the rest of the cluster.
   # The URLs needed to be a comma-separated list.
   initial-advertise-peer-urls: http://192.168.169.51:2380
   
   # List of this member's client URLs to advertise to the public.
   # The URLs needed to be a comma-separated list.
   advertise-client-urls: http://192.168.169.51:2379
   
   # Initial cluster token for the etcd cluster during bootstrap.
   initial-cluster-token: 'etcd-cluster'
   
   # Initial cluster state ('new' or 'existing').
   initial-cluster-state: 'new'
   
   # Accept etcd V2 client requests
   enable-v2: true
  ```

## etcdctl命令实践  


 - put、del、get   
   ```shell
    # put
    [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 put jan1   jan_value_1
    OK
    # get
    [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 get jan1
    jan1
    jan_value_1
    # del 
    [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 del jan1
    1
    # get
    [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 get jan1
   ```
 - txn write
  ```shell
    [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 txn     --interactive
    compares:
    value("user1") = "bad"
    
    success requests (get, put, del):
    put user1 123
    
    failure requests (get, put, del):
    
    SUCCESS
    
    OK
    [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 get user1
    user1
    123
  ```
 
 - watch 
   监控某个 Key，如果该 Key 有变更操作，此监控操作将会得知操作信息；
   注意：watch 操作金辉监控 put、del 操作，对于 get 操作不会获取；
   ```shell
     Ts_1: [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 watch jan3

     Ts_2: [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 put jan3 jan_test3
     OK

     [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379      watch jan3
     PUT
     jan3
     jan_test3
   ```

 - Member
   ```shell
     [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 member list  
     f47ddac781ce3323, started, jan-1, http://192.168.169.51:2380, http://192.168.169.51:2379, false
   ```

 
 - Lease   
   ```shell
    [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379     lease grant 30
    lease 332377f87288321e granted with TTL(30s)
    [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379     put jan3 123 --lease=332377f87288321e
    OK
    [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379     get jan3
    jan3
    123
    
    # 30s 之后再次查看 key 为 jan3 的 value
    [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379     get jan3
   ```

 - locks   
   申请一个 name 独占锁后，如下 mutex1，其他 session 申请同 name 锁会被阻塞；
   ```shell
    Ts_1-session_1: [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 lock mutex1
    mutex1/332377f872883224
    
    Ts_2-session_2: [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 lock mutex1
    
    Ts_3-session_1: ^C[root@tidb-52-pd etcd]# 
    
    Ts_4-session_2: [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 lock mutex1
    mutex1/332377f872883228
   ```
  
 - Elections   
   ```shell
    Ts_1-session_1: [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 elect one p1
    one/332377f872883233
    
    Ts_2-session_2: [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 elect one p2
    
    Ts_3-session_1: ^C[root@tidb-52-pd etcd]# 
    
    Ts_4-session_2: [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 elect one p2
    one/332377f872883238
    p2
    
   ```
 
 - Cluster status    
   ```shell
    [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 endpoint status --write-out="table"
    +---------------------+------------------+---------------+---------+-----------+------------+-----------+------------+--------------------+--------+
    |      ENDPOINT       |        ID        |    VERSION    | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
    +---------------------+------------------+---------------+---------+-----------+------------+-----------+------------+--------------------+--------+
    | 192.168.169.51:2379 | f47ddac781ce3323 | 3.5.0-alpha.0 |   29 kB |      true |      false |         5 |         70 |                 70 |        |
    +---------------------+------------------+---------------+---------+-----------+------------+-----------+------------+--------------------+--------+
    [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 endpoint health --write-out="table"
    +---------------------+--------+------------+-------+
    |      ENDPOINT       | HEALTH |    TOOK    | ERROR |
    +---------------------+--------+------------+-------+
    | 192.168.169.51:2379 |   true | 2.453913ms |       |
    +---------------------+--------+------------+-------+
   ```

 - Snapshot
   ```shell
    [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 snapshot status jan.db     --write-out="table"
    +----------+----------+------------+------------+
    |   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
    +----------+----------+------------+------------+
    | 5b58e354 |       32 |         35 |      29 kB |
    +----------+----------+------------+------------+
   ```

 - Auth  
   开启etcd的权限控制
   ```shell
    [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 role add root
    Role root created

    [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 role grant-permission root readwrite     jan
    Role root updated

    [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 role get root
    Role root
    KV Read:
    	jan
    KV Write:
    	jan

    [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 user add root
    Password of root: 
    Type password of root again for confirmation: 
    User root created

    [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 user grant-role root root
    Role root is granted to user root

    [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 user get root
    User: root
    Roles: root

    [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 auth enable
    Authentication Enabled

    [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 --user=root:root put jan_key jan_value
    OK

    [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 --user=root:root get jan_key
    jan_key
    jan_value
   ```

## etcdctl参数实践 

 - --write-out="json"
   输出 raft 信息
   ```shell
    [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 get jan1 --write-out="json"
    {"header":{"cluster_id":15984406527205749544,"member_id":17617477867754369827, "revision":9,"raft_term":4}}
   ```
 - --prefix  
    前缀搜索
    ```shell
     [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 put jan1 jan_test_1
     OK
     [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 put jan2 jan_test_2
     OK
     [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 get jan --prefix  --print-value-only
     jan_test_1
     jan_test_2
    ```

 - --endpoints=$ENDPOINTS
    etcdctl 客户端要操作的链接终端
    ```shell
      [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 get jan1
      jan1
      jan_test_1
      [root@tidb-52-pd etcd]# ./etcdctl  get jan --prefix --print-value-only
      {"level":"warn","ts":"2021-03-03T06:00:48.853-0500","caller":"v3/retry_interceptor.go:62","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc0001188c0/#initially=[127.0.0.1:2379]","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = latest balancer error: last connection error: connection error: desc = \"transport: Error while dialing dial tcp 127.0.0.1:2379: connect: connection refused\""}
      Error: context deadline exceeded
    ```

 - --print-value-only
    ```shell
     [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 get jan1 
     jan1
     jan_test_1
     [root@tidb-52-pd etcd]# ./etcdctl --endpoints=192.168.169.51:2379 get jan1      --print-value-only
     jan_test_1
    ```



## 参考文章
 - [Etcd Docs](https://etcd.io/docs/v3.4.0/demo/)   
 - [ETCD 简介](https://gohalo.me/post/golang-raft-etcd-introduce.html)   






