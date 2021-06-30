# TiDB启动流程与运行源码概览  
时间: 2021-02-01  
TiDB 版本：4.0.9

```go
func main() {
	flag.Parse()      // 解析命令行输入选项
  ......
	registerStores()  // 注册 Store 信息
	registerMetrics() // 注册度量信息
	config.InitializeConfig(*configPath, *configCheck, *configStrict, reloadConfig, overrideConfig)  // 初始化配置信息
	if config.GetGlobalConfig().OOMUseTmpStorage {
		config.GetGlobalConfig().UpdateTempStoragePath()
		err := disk.InitializeTempDir()
		terror.MustNil(err)
		checkTempStorageQuota()
	}                              // 检验全局配置信息，如果有误则报错
	setGlobalVars()                // 设置全局变量
	setCPUAffinity()               // CPU 亲和性设置，将进程绑定到指定 vCore 上
	setupLog()                     // 初始化日志配置
	setHeapProfileTracker()        // 初始化内存配置信息
  setupTracing() // Should before createServer and after setup config.
                                 // 启动内存追踪进程
	printInfo()                    // 打印日志信息
	setupBinlogClient()            // 读取 binlog 配置，如果 binlog.enable 配置参数为 True 会开启
	setupMetrics()                 // 依据 config 配置信息，并行启动度量追踪进程
	createStoreAndDomain()         // 依据配置信息注册 Store 信息，并加载 information_schema 对应 session
	createServer()                 // 在此处注册一个 Driver ，启动 Expensive 语句处理 session 管理进程 
	signal.SetupSignalHandler(serverShutdown)               // 注册信号量
	runServer()                    // 使用 for 循环开启一个套接字监听，当有新连接请求时 调用 server.go 中 onConn(conn *clientConn) 方法并行的交给内部线程处理
	cleanup()                      // 调用相关方法关闭 TiDB 服务进程
	syncLog()                      // 落盘日志信息
}
```



```go
// Domain represents a storage space. Different domains can use the same database name.
// Multiple domains can be used in parallel without synchronization.
type Domain struct {
	store                kv.Storage
	infoHandle           *infoschema.Handle
	privHandle           *privileges.Handle
	bindHandle           *bindinfo.BindHandle
	statsHandle          unsafe.Pointer
	statsLease           time.Duration
	ddl                  ddl.DDL
	info                 *infosync.InfoSyncer
	m                    sync.Mutex
	SchemaValidator      SchemaValidator
	sysSessionPool       *sessionPool
	exit                 chan struct{}
	etcdClient           *clientv3.Client
	gvc                  GlobalVariableCache
	slowQuery            *topNSlowQueries
	expensiveQueryHandle *expensivequery.Handle
	wg                   sync.WaitGroup
	statsUpdating        sync2.AtomicInt32
	cancel               context.CancelFunc
	indexUsageSyncLease  time.Duration
}

```




## Blog_Recommand
 - [TiDB源码阅读（二） 简单理解一下 Lex & Yacc](https://segmentfault.com/a/1190000023464340)   

 - [TIDB Salparse源码解析 -1](https://www.cnblogs.com/ivy-blogs/p/13032292.html)   
 - [tidb源码学习之auto_increment](https://mccxj.github.io/blog/20171030_tidb-auto-increment.html)    

 - [tidb源码学习之ast包](https://mccxj.github.io/blog/20171004_tidb-ast-source.html)  

 - [tidb源码学习之错误管理](https://mccxj.github.io/blog/20170927_tidb-errors.html)  

  - [tidb源码学习之测试框架](https://mccxj.github.io/blog/20170921_tidb-testcase.html)  

  - [TiDB的入口-Mysql协议](https://segmentfault.com/a/1190000023464293)      

  - [TiDB show processlist命令源码分析](https://www.cnblogs.com/mantu/p/10721122.html)    

  - [TiDB源码阅读笔记（三） TiDB 的在线 DDL](https://segmentfault.com/a/1190000023514267)   

  - [TiDB 源码阅读（二.1）TiDB 中 的 Kill Query](https://segmentfault.com/a/1190000023464409)   
 