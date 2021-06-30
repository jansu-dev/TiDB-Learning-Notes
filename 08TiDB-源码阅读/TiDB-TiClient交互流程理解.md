# TiDB-TiClient交互流程理解
时间: 2021-02-13   
TiDB 版本：4.0.9

## Summary  

> - [Txn方法](#Txn方法)   
>   - [Txn方法](#Txn方法)   
> - [Txn方法](#Txn方法)   
> - [Txn方法](#Txn方法)   


package kv 定义了一些接口，package tikv 实现了 package kv 中的一些接口，这么着的目的是为了更好的扩展性；    


## Txn方法  

txn 应该是支持事务的一些键值对的处理方法   

```go
// Transaction defines the interface for operations inside a Transaction.
// This is not thread safe.
type Transaction interface {
	RetrieverMutator
	// Size returns sum of keys and values length.
	Size() int
	// Len returns the number of entries in the DB.
	Len() int
	// Reset reset the Transaction to initial states.
	Reset()
	// Commit commits the transaction operations to KV store.
	Commit(context.Context) error
	// Rollback undoes the transaction operations to KV store.
	Rollback() error
	// String implements fmt.Stringer interface.
	String() string
	// LockKeys tries to lock the entries with the keys in KV store.
	LockKeys(ctx context.Context, lockCtx *LockCtx, keys ...Key) error
	// SetOption sets an option with a value, when val is nil, uses the default
	// value of this option.
	SetOption(opt Option, val interface{})
	// DelOption deletes an option.
	DelOption(opt Option)
	// IsReadOnly checks if the transaction has only performed read operations.
	IsReadOnly() bool
	// StartTS returns the transaction start timestamp.
	StartTS() uint64
	// Valid returns if the transaction is valid.
	// A transaction become invalid after commit or rollback.
	Valid() bool
	// GetMemBuffer return the MemBuffer binding to this transaction.
	GetMemBuffer() MemBuffer
	// GetSnapshot returns the Snapshot binding to this transaction.
	GetSnapshot() Snapshot
	// GetUnionStore returns the UnionStore binding to this transaction.
	GetUnionStore() UnionStore
	// SetVars sets variables to the transaction.
	SetVars(vars *Variables)
	// GetVars gets variables from the transaction.
	GetVars() *Variables
	// BatchGet gets kv from the memory buffer of statement and transaction, and the kv storage.
	// Do not use len(value) == 0 or value == nil to represent non-exist.
	// If a key doesn't exist, there shouldn't be any corresponding entry in the result map.
	BatchGet(ctx context.Context, keys []Key) (map[string][]byte, error)
	IsPessimistic() bool
}
```

LockKeys 只有在提交的时候才去进行加锁操作   

#### MemBuffer  

Membuffer 
SnapShot 

txn 在需要获取kv数据的时候会先去 US(Union Store)中找，寻找的顺序是先从Membuffer中找，如果Membuffer中没有再去SnapShot中找；   

SnapShot 相当于一个只读的客户端，实现了三个方法 Get/Seek/BatchGet 

SnapShot 接口是由 tikvSnapshot 实现的 

Storage 接口是对 Storeage 的一个抽象，只要定义了 Begin()、GetSnapshot(ver)、GetClient() Client、Close()、CurrentVersion()、GetOracle()等方法；  
GetClient() Client 是 Coprocessor 的 Client，专门为 Coprocessor 服务   


```go
// MemBuffer is an in-memory kv collection, can be used to buffer write operations.
type MemBuffer interface {
	RetrieverMutator

	// RLock locks the MemBuffer for shared read.
	// In the most case, MemBuffer will only used by single goroutine,
	// but it will be read by multiple goroutine when combined with executor.UnionScanExec.
	// To avoid race introduced by executor.UnionScanExec, MemBuffer expose read lock for it.
	RLock()
	// RUnlock unlocks the MemBuffer.
	RUnlock()

	// GetFlags returns the latest flags associated with key.
	GetFlags(Key) (KeyFlags, error)
	// IterWithFlags returns a MemBufferIterator.
	IterWithFlags(k Key, upperBound Key) MemBufferIterator
	// IterReverseWithFlags returns a reversed MemBufferIterator.
	IterReverseWithFlags(k Key) MemBufferIterator
	// SetWithFlags put key-value into the last active staging buffer with the given KeyFlags.
	SetWithFlags(Key, []byte, ...FlagsOp) error
	// UpdateFlags update the flags associated with key.
	UpdateFlags(Key, ...FlagsOp)

	// Reset reset the MemBuffer to initial states.
	Reset()
	// DiscardValues releases the memory used by all values.
	// NOTE: any operation need value will panic after this function.
	DiscardValues()

	// Staging create a new staging buffer inside the MemBuffer.
	// Subsequent writes will be temporarily stored in this new staging buffer.
	// When you think all modifications looks good, you can call `Release` to public all of them to the upper level buffer.
	Staging() StagingHandle
	// Release publish all modifications in the latest staging buffer to upper level.
	Release(StagingHandle)
	// Cleanup cleanup the resources referenced by the StagingHandle.
	// If the changes are not published by `Release`, they will be discarded.
	Cleanup(StagingHandle)
	// InspectStage used to inspect the value updates in the given stage.
	InspectStage(StagingHandle, func(Key, KeyFlags, []byte))

	// SelectValueHistory select the latest value which makes `predicate` returns true from the modification history.
	SelectValueHistory(key Key, predicate func(value []byte) bool) ([]byte, error)
	// SnapshotGetter returns a Getter for a snapshot of MemBuffer.
	SnapshotGetter() Getter
	// SnapshotIter returns a Iterator for a snapshot of MemBuffer.
	SnapshotIter(k, upperbound Key) Iterator

	// Size returns sum of keys and values length.
	Size() int
	// Len returns the number of entries in the DB.
	Len() int
	// Dirty returns whether the root staging buffer is updated.
	Dirty() bool
}
```


## Snapshot   

```go
// Snapshot defines the interface for the snapshot fetched from KV store.
type Snapshot interface {
	Retriever
	// BatchGet gets a batch of values from snapshot.
	BatchGet(ctx context.Context, keys []Key) (map[string][]byte, error)
	// SetOption sets an option with a value, when val is nil, uses the default
	// value of this option. Only ReplicaRead is supported for snapshot
	SetOption(opt Option, val interface{})
	// DelOption deletes an option.
	DelOption(opt Option)
}

```