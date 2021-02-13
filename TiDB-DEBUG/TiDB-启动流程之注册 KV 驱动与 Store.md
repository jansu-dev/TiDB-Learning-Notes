# TiDB-启动流程之注册 KV驱动与 Store 

时间：2021-02-13   

## TiDB-main启动入口  

[源代码路径](https://github.com/pingcap/tidb/blob/d6a2b9a372edd3638c0ed88e1d2a5e6b702a69ed/tidb-server/main.go#L166)

[func registerStores() 源代码路径](https://github.com/pingcap/tidb/blob/d6a2b9a372edd3638c0ed88e1d2a5e6b702a69ed/tidb-server/main.go#L249)

```go  

func main() {
 ......
	registerStores()
 ......
}


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

## TiKV-store注册驱动

[源代码路径](https://github.com/pingcap/tidb/blob/d6a2b9a372edd3638c0ed88e1d2a5e6b702a69ed/store/store.go#L30)

```go
var stores = make(map[string]kv.Driver)

// Register registers a kv storage with unique name and its associated Driver.
func Register(name string, driver kv.Driver) error {
	name = strings.ToLower(name)

	if _, ok := stores[name]; ok {
		return errors.Errorf("%s is already registered", name)
	}

	stores[name] = driver
	return nil
}
```



## TiDB-store-tikv 


[源代码路径](https://github.com/pingcap/tidb/blob/631dbfdc3215a6c448b3e50ed57952f072681cb3/store/tikv/kv.go#L54)


## TiDB-tikv 
[源代码路径](https://github.com/pingcap/tidb/blob/d6a2b9a372edd3638c0ed88e1d2a5e6b702a69ed/kv/kv.go#L457)
```go
type Driver interface {
	// Open returns a new Storage.
	// The path is the string for storage specific format.
	Open(path string) (Storage, error)
}

// Storage defines the interface for storage.
// Isolation should be at least SI(SNAPSHOT ISOLATION)
type Storage interface {
	// Begin transaction
	Begin() (Transaction, error)
	// BeginWithStartTS begins transaction with startTS.
	BeginWithStartTS(startTS uint64) (Transaction, error)
	// GetSnapshot gets a snapshot that is able to read any data which data is <= ver.
	// if ver is MaxVersion or > current max committed version, we will use current version for this snapshot.
	GetSnapshot(ver Version) (Snapshot, error)
	// GetClient gets a client instance.
	GetClient() Client
	// Close store
	Close() error
	// UUID return a unique ID which represents a Storage.
	UUID() string
	// CurrentVersion returns current max committed version.
	CurrentVersion() (Version, error)
	// GetOracle gets a timestamp oracle client.
	GetOracle() oracle.Oracle
	// SupportDeleteRange gets the storage support delete range or not.
	SupportDeleteRange() (supported bool)
	// Name gets the name of the storage engine
	Name() string
	// Describe returns of brief introduction of the storage
	Describe() string
	// ShowStatus returns the specified status of the storage
	ShowStatus(ctx context.Context, key string) (interface{}, error)
}
```



