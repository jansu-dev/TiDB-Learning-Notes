# TiDB-启动流程之注册 KV驱动与 Store 

时间：2021-02-13   
TiDB 版本：4.0.9


## TiDB-Package-main


层注册store启动入口  

[main() 源代码路径](https://github.com/pingcap/tidb/blob/d6a2b9a372edd3638c0ed88e1d2a5e6b702a69ed/tidb-server/main.go#L166)

```go  

func main() {
 ......
	registerStores()
 ......
}
```

[registerStores() 源代码路径](https://github.com/pingcap/tidb/blob/d6a2b9a372edd3638c0ed88e1d2a5e6b702a69ed/tidb-server/main.go#L249)
```go
func registerStores() {
	err := kvstore.Register("tikv", kvstore.TiKVDriver{})
	terror.MustNil(err)
	gcworker.NewGCHandlerFunc = gcworker.NewGCWorker
	err = kvstore.Register("mocktikv", mockstore.MockTiKVDriver{})
	terror.MustNil(err)
	err = kvstore.Register("unistore", mockstore.EmbedUnistoreDriver{})
	terror.MustNil(err)
}
```

tikv.Driver{} 结构体属于 github.com/pingcap/tidb/store/tikv，tikv 包提供到 tcp 链接 store 的一系列方法；       
kvstore.Register 方法属于 github.com/pingcap/tidb/store，store 是对 TiKV 中 store 抽象概念的封装实现，store 子目录下含有 tikv 包；    
在 registerStores() 中将 tikv 层内容注册给 kvstore 


## TiKV-Package-store


层注册驱动


[源代码路径](https://github.com/pingcap/tidb/blob/d6a2b9a372edd3638c0ed88e1d2a5e6b702a69ed/store/store.go#L30)

```go
var stores = make(map[string]kv.Driver)
```
kv.Driver 属于 github.com/pingcap/tidb/kv，用于处理从存储层得到的数据，本身是一个结构体，含有、、等方法   

```go
func Register(name string, driver kv.Driver) error {
	name = strings.ToLower(name)

	if _, ok := stores[name]; ok {
		return errors.Errorf("%s is already registered", name)
	}

	stores[name] = driver
	return nil
}
```
Register 函数为每一个 KV 存储（store）注册一个唯一的名字及相关驱动   



## TiDB-Package-kv 
[源代码路径](https://github.com/pingcap/tidb/blob/d6a2b9a372edd3638c0ed88e1d2a5e6b702a69ed/kv/kv.go#L457)
```go
type Driver interface {
	Open(path string) (Storage, error)
}

type Storage interface {
	Begin() (Transaction, error)
	BeginWithStartTS(startTS uint64) (Transaction, error)
	GetSnapshot(ver Version) (Snapshot, error)
	GetClient() Client
	Close() error
	UUID() string
	CurrentVersion() (Version, error)
	GetOracle() oracle.Oracle
	SupportDeleteRange() (supported bool)
	Name() string
	Describe() string
	ShowStatus(ctx context.Context, key string) (interface{}, error)
}
```
Driver interface 是一个必须被实现的接口定义  
path 定义了连接路径的指定格式    
Storage interface 定义了隔离级别至少为 SI 快照隔离界别存储模式的接口  


## TiDB-Package-tikv  

[源代码路径：store/tikv/kv.go](https://github.com/pingcap/tidb/blob/631dbfdc3215a6c448b3e50ed57952f072681cb3/store/tikv/kv.go#L54)


```go
// Open opens or creates an TiKV storage with given path.
// Path example: tikv://etcd-node1:port,etcd-node2:port?cluster=1&disableGC=false
func (d Driver) Open(path string) (kv.Storage, error) {
	mc.Lock()
	defer mc.Unlock()

	security := config.GetGlobalConfig().Security
	tikvConfig := config.GetGlobalConfig().TiKVClient
	txnLocalLatches := config.GetGlobalConfig().TxnLocalLatches
	etcdAddrs, disableGC, err := config.ParsePath(path)
	if err != nil {
		return nil, errors.Trace(err)
	}

	pdCli, err := pd.NewClient(etcdAddrs, pd.SecurityOption{
		CAPath:   security.ClusterSSLCA,
		CertPath: security.ClusterSSLCert,
		KeyPath:  security.ClusterSSLKey,
	}, pd.WithGRPCDialOptions(
		grpc.WithKeepaliveParams(keepalive.ClientParameters{
			Time:    time.Duration(tikvConfig.GrpcKeepAliveTime) * time.Second,
			Timeout: time.Duration(tikvConfig.GrpcKeepAliveTimeout) * time.Second,
		}),
	))
	pdCli = execdetails.InterceptedPDClient{Client: pdCli}

	if err != nil {
		return nil, errors.Trace(err)
	}

	// FIXME: uuid will be a very long and ugly string, simplify it.
	uuid := fmt.Sprintf("tikv-%v", pdCli.GetClusterID(context.TODO()))
	if store, ok := mc.cache[uuid]; ok {
		return store, nil
	}

	tlsConfig, err := security.ToTLSConfig()
	if err != nil {
		return nil, errors.Trace(err)
	}

	spkv, err := NewEtcdSafePointKV(etcdAddrs, tlsConfig)
	if err != nil {
		return nil, errors.Trace(err)
	}

	coprCacheConfig := &config.GetGlobalConfig().TiKVClient.CoprCache
	s, err := newTikvStore(uuid, &codecPDClient{pdCli}, spkv, newRPCClient(security), !disableGC, coprCacheConfig)
	if err != nil {
		return nil, errors.Trace(err)
	}
	if txnLocalLatches.Enabled {
		s.EnableTxnLocalLatches(txnLocalLatches.Capacity)
	}
	s.etcdAddrs = etcdAddrs
	s.tlsConfig = tlsConfig

	mc.cache[uuid] = s
	return s, nil
}

// EtcdBackend is used for judging a storage is a real TiKV.
type EtcdBackend interface {
	EtcdAddrs() ([]string, error)
	TLSConfig() *tls.Config
	StartGCWorker() error
}
```
Open opens or creates an TiKV storage with given path.
Path example: tikv://etcd-node1:port,etcd-node2:port?cluster=1&disableGC=false


