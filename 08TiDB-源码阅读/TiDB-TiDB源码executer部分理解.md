# TiDB-TiDB源码executer部分理解  


TiDB 版本：4.0.9

## Executer 接口  

每一个接口都会实现一个 Executer 的接口，   
Open() 开启一个 executer 算子  
Next() 用于处理数据  
Close() 用于关闭 executer 算子  

```go  
// location : executor\executor.go 

type Executor interface {
	base() *baseExecutor
	Open(context.Context) error
	Next(ctx context.Context, req *chunk.Chunk) error
	Close() error
	Schema() *expression.Schema
}
```  

## 算子分类 

![Executer.png](http://cdn.lifemini.cn/dbblog/20210124/41c44fb6d1214b6abf6dc1cd468a87e6.png)   



## handleQuery 接口   

step1 : stmts, err := cc.ctx.Parse(ctx, sql) 就是把相应的 SQL 语句转换为 AST 的语法树

```go
func (cc *clientConn) handleQuery(ctx context.Context, sql string) (err error) {
	defer trace.StartRegion(ctx, "handleQuery").End()
	sc := cc.ctx.GetSessionVars().StmtCtx
	prevWarns := sc.GetWarnings()
	stmts, err := cc.ctx.Parse(ctx, sql)
	if err != nil {
		metrics.ExecuteErrorCounter.WithLabelValues(metrics.ExecuteErrorToLabel(err)).Inc()
		return err
	}

	if len(stmts) == 0 {
		return cc.writeOK(ctx)
	}

	warns := sc.GetWarnings()
	parserWarns := warns[len(prevWarns):]

	var pointPlans []plannercore.Plan
	if len(stmts) > 1 {
		// Only pre-build point plans for multi-statement query
		pointPlans, err = cc.prefetchPointPlanKeys(ctx, stmts)
		if err != nil {
			return err
		}
	}
	if len(pointPlans) > 0 {
		defer cc.ctx.ClearValue(plannercore.PointPlanKey)
	}
	for i, stmt := range stmts {
		if len(pointPlans) > 0 {
			// Save the point plan in Session so we don't need to build the point plan again.
			cc.ctx.SetValue(plannercore.PointPlanKey, plannercore.PointPlanVal{Plan: pointPlans[i]})
		}
		err = cc.handleStmt(ctx, stmt, parserWarns, i == len(stmts)-1)
		if err != nil {
			break
		}
	}
	if err != nil {
		metrics.ExecuteErrorCounter.WithLabelValues(metrics.ExecuteErrorToLabel(err)).Inc()
	}
	return err
}
```




```go 
// location : session\session.go

func (s *session) Execute(ctx context.Context, sql string) (recordSets []sqlexec.RecordSet, err error) {
	if span := opentracing.SpanFromContext(ctx); span != nil && span.Tracer() != nil {
		span1 := span.Tracer().StartSpan("session.Execute", opentracing.ChildOf(span.Context()))
		defer span1.Finish()
		ctx = opentracing.ContextWithSpan(ctx, span1)
		logutil.Eventf(ctx, "execute: %s", sql)
	}

```


转换逻辑执行计划到物理执行计划
```go
	// Transform abstract syntax tree to a physical plan(stored in executor.ExecStmt).
	compiler := executor.Compiler{Ctx: s}
	stmt, err := compiler.Compile(ctx, stmtNode)
```


## Insert 语句的执行流程  

![image.png](http://cdn.lifemini.cn/dbblog/20210124/7fccd765fc5642f985564fdd658c88fa.png)
