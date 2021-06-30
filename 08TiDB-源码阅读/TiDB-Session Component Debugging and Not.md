# TiDB-Session Component Debugging and Notes  
time:2021-02-06   
TiDB 版本：4.0.9

## Session_Interface

[Session Interface Loaction in TiDB Source](https://github.com/pingcap/tidb/blob/27db39b4807809b65c39c66f72799571eb89a138/session/session.go#L120)


```go
type Session interface {
	sessionctx.Context    // Context 方法是事务和可执行环境的接口
	Status() uint16       // 返回如 autocommit 一样的TiDB状态的方法，不过在 TiDB 4.0.9 中没有看到实现方法    
	LastInsertID() uint64 // 返回最新插入行的 auto_increment ID.
	LastMessage() string  // 返回由最后一条由命令产生的消息   
	AffectedRows() uint64 // Affected rows by latest executed stmt.
	// Execute is deprecated, and only used by plugins. Use ExecuteStmt() instead.
	Execute(context.Context, string) ([]sqlexec.RecordSet, error) // Execute a sql statement.
	// ExecuteStmt executes a parsed statement.
	ExecuteStmt(context.Context, ast.StmtNode) (sqlexec.RecordSet, error)
	// Parse is deprecated, use ParseWithParams() instead.
	Parse(ctx context.Context, sql string) ([]ast.StmtNode, error)
	// ExecuteInternal is a helper around ParseWithParams() and ExecuteStmt(). It is not allowed to execute multiple statements.
	ExecuteInternal(context.Context, string, ...interface{}) (sqlexec.RecordSet, error)
	String() string // String is used to debug.
	CommitTxn(context.Context) error
	RollbackTxn(context.Context)
	// PrepareStmt executes prepare statement in binary protocol.
	PrepareStmt(sql string) (stmtID uint32, paramCount int, fields []*ast.ResultField, err error)
	// ExecutePreparedStmt executes a prepared statement.
	ExecutePreparedStmt(ctx context.Context, stmtID uint32, param []types.Datum) (sqlexec.RecordSet, error)
	DropPreparedStmt(stmtID uint32) error
	SetClientCapability(uint32) // Set client capability flags.
	SetConnectionID(uint64)
	SetCommandValue(byte)
	SetProcessInfo(string, time.Time, byte, uint64)
	SetTLSState(*tls.ConnectionState)
	SetCollation(coID int) error
	SetSessionManager(util.SessionManager)
	Close()
	Auth(user *auth.UserIdentity, auth []byte, salt []byte) bool
	AuthWithoutVerification(user *auth.UserIdentity) bool
	ShowProcess() *util.ProcessInfo
	// PrepareTxnCtx is exported for test.
	PrepareTxnCtx(context.Context)
	// FieldList returns fields list of a table.
	FieldList(tableName string) (fields []*ast.ResultField, err error)
}

```


## sessionctx

Context 是事务和可执行参数环境的接口，

```go
type Context interface {
	// NewTxn 方法开启新事务，以便 Follow 给更深层组件提供环境
	// If old transaction is valid, it is committed first.
	// It's used in BEGIN statement and DDL statements to commit old transaction.
	NewTxn(context.Context) error

	// Txn returns the current transaction which is created before executing a statement.
	// The returned kv.Transaction is not nil, but it maybe pending or invalid.
	// If the active parameter is true, call this function will wait for the pending txn
	// to become valid.
	Txn(active bool) (kv.Transaction, error)

	// GetClient gets a kv.Client.
	GetClient() kv.Client

	// SetValue saves a value associated with this context for key.
	SetValue(key fmt.Stringer, value interface{})

	// Value returns the value associated with this context for key.
	Value(key fmt.Stringer) interface{}

	// ClearValue clears the value associated with this context for key.
	ClearValue(key fmt.Stringer)

	GetSessionVars() *variable.SessionVars

	GetSessionManager() util.SessionManager

	// RefreshTxnCtx commits old transaction without retry,
	// and creates a new transaction.
	// now just for load data and batch insert.
	RefreshTxnCtx(context.Context) error

	// RefreshVars refreshes modified global variable to current session.
	// only used to daemon session like `statsHandle` to detect global variable change.
	RefreshVars(context.Context) error

	// InitTxnWithStartTS initializes a transaction with startTS.
	// It should be called right before we builds an executor.
	InitTxnWithStartTS(startTS uint64) error

	// GetStore returns the store of session.
	GetStore() kv.Storage

	// PreparedPlanCache returns the cache of the physical plan
	PreparedPlanCache() *kvcache.SimpleLRUCache

	// StoreQueryFeedback stores the query feedback.
	StoreQueryFeedback(feedback interface{})

	// HasDirtyContent checks whether there's dirty update on the given table.
	HasDirtyContent(tid int64) bool

	// StmtCommit flush all changes by the statement to the underlying transaction.
	StmtCommit()
	// StmtRollback provides statement level rollback.
	StmtRollback()
	// StmtGetMutation gets the binlog mutation for current statement.
	StmtGetMutation(int64) *binlog.TableMutation
	// DDLOwnerChecker returns owner.DDLOwnerChecker.
	DDLOwnerChecker() owner.DDLOwnerChecker
	// AddTableLock adds table lock to the session lock map.
	AddTableLock([]model.TableLockTpInfo)
	// ReleaseTableLocks releases table locks in the session lock map.
	ReleaseTableLocks(locks []model.TableLockTpInfo)
	// ReleaseTableLockByTableID releases table locks in the session lock map by table ID.
	ReleaseTableLockByTableIDs(tableIDs []int64)
	// CheckTableLocked checks the table lock.
	CheckTableLocked(tblID int64) (bool, model.TableLockType)
	// GetAllTableLocks gets all table locks table id and db id hold by the session.
	GetAllTableLocks() []model.TableLockTpInfo
	// ReleaseAllTableLocks releases all table locks hold by the session.
	ReleaseAllTableLocks()
	// HasLockedTables uses to check whether this session locked any tables.
	HasLockedTables() bool
	// PrepareTSFuture uses to prepare timestamp by future.
	PrepareTSFuture(ctx context.Context)
}
```