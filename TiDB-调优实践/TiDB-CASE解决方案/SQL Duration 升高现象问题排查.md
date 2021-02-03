# SQL Duration 升高现象问题排查    
时间：2021-02-02  

## Summary

> - [问题现象](#问题现象)  
> - [排查过程](#排查过程)  
>   - [核心指标](#核心指标)   
> - [排查思路](#排查思路)   
>   - [网络延迟抖动性方向排查](#网络延迟抖动性方向排查)   
>   - [TOP_SQL方向排查](#TOP_SQL方向排查)   
>   - [集群组件性能问题排查方向](#集群组件性能问题排查方向)   
> - [排查细节](#排查细节)   
>   - [TiDB部分组件排查](#TiDB部分组件排查)   
>     - [TiDB-Executer](#TiDB-Executer)   
>   - [TiDB部分组件排查](#TiDB部分组件排查)  
>     - [TiDB-KV](#TiDB-KV)   
>     - [TiDB-gRPC](#TiDB-gRPC)   
>     - [TiDB-Scheduler](#TiDB-Scheduler)   
> - [问题解决](#问题解决)  
> - [归纳总结](#归纳总结)  
> - [参考文章](#参考文章)  

## 问题现象
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;在客户 TiDB 生产库进行巡检，发现 SQL Duration 存在突然小幅度升高后又回落的现象，需分析导致此现象的具体原因，以规避潜在风险。

 - Metrics 中反映的问题现象  
 ![0](./check-report-pic/0.png)   



## 排查过程   


#### 核心指标
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;本次仅介绍在排查问题过程中涉及到的指标    

 - Duration  
 - QPS  
 - Statement QPS
 - Slow Query


## 排查思路  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;依据 TiDB 各组件间关系、SQL 执行流程等体系知识，把握 Promethus 核心监控指标，自定向下逐层深挖各组件影响性能最大的因素。  

 - 案例排查思路  
   1. 网络延迟抖动性升高，导致 Duration 上升；
   2. 慢 SQL 导致的 Duration 上升   
   3. 集群组件性能问题导致的 Duration 上升


#### 网络延迟抖动性方向排查  
   - 排查思路  


   - 排查结果  

   - 案例 Top SQL 截图  
   ![11](./check-report-pic/11.png)   

#### TOP_SQL方向排查
   - 排查思路   
     1. 通过 slow_query 系统信息表相应字段分组排序，查出巡检时间内所需的 Top SQL 信息；   
     2. 如果断定 SQL 是引起 Duration 升高的主要原因，可通过 Slow Query File 进一步分析；  
       - 查询 SQL 慢的阶段，如：Parse_time、Compile_time 等等，详细信息参考-[慢查询日志字段含义说明](https://docs.pingcap.com/zh/tidb/stable/identify-slow-queries#%E5%AD%97%E6%AE%B5%E5%90%AB%E4%B9%89%E8%AF%B4%E6%98%8E) 
       - 查询 SQL 历史执行计划，如：select tidb_decode_plan(...)，优化对性能瓶颈起决定性作用的执行计划，详细信息参考-[查看 Plan](https://docs.pingcap.com/zh/tidb/stable/identify-slow-queries#%E7%9B%B8%E5%85%B3%E7%B3%BB%E7%BB%9F%E5%8F%98%E9%87%8F)
       - 定位原因后通过 Hint 或 Index 优化慢 SQL

   - 排查结果  
     &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;案例中 TiDB 集群共有4台 TiDB 实例，分别是 IP88、IP89、IP91、IP93，在四个台 TiDB 实例上分别取问题时间段半小时的 Slow Query 情况，发现并没有慢 SQL 执行次数多到足够影响整个集群的 Duration 升高。
     &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;因此，慢 SQL 导致 Duration 的方向锁定问题原因的思路被排除。
  
   - 案例 Top SQL 截图  
     - IP88  
     ![2](./check-report-pic/2.png)   
  
     - IP89  
     ![3](./check-report-pic/3.png)   

     - IP91  
     ![4](./check-report-pic/4.png)   

     - IP93  
     ![5](./check-report-pic/5.png)  
   


#### 集群组件性能问题排查方向
   - 排查思路   
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;导致 SQL Duration 的原因也可能是集群组件出现问题导致的，排查思路为依据集群组件关系、Metrics 监控项排查瓶颈点
     - 组件关系图
    ![组件关系图](./check-report-pic/ComponentsOverview.png)  
    
  
   - 排查结果  
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;SQL Duration 升高的原因，从 Metrics 中推断是 INSERT 或 SELECT 导致的
  
   - 案例 Metrics  
   ![1](./check-report-pic/1.png)


 - 集群中某节点组件存在性能问题    
     
   - 排查思路：
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;SELECT、INSERT、UPDATE、DELETE 中任何类型 SQL 的任何一种都有可能导致 Duration 升高，应该通过 Statement OPS 找出其中占比重比较大的 SQL 操作。因为 SQL 占比重较小的 SQL 即使很慢，也很小概率会出现在 99% 分位数的视图中，所以应先对 SQL 操作分类排查;
    
  
   - 排查结果  
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;SQL Duration 升高的原因，从 Metrics 中推断是 INSERT 或 SELECT 导致的; 
  
   - 案例 Metrics  
   ![6](./check-report-pic/6.png) 



## 排查细节



&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;通过在三个方向的探索发现，极有可能是因为集群组件性能问题导致的 Duration 上升；

### TiDB 部分组件排查

#### TiDB-Executer  

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Distsql Duration 主要并行处理 SQL 命令，将 Coprocessor 方面的聚合需求交给 TiKV Client 去执行；  
 - **DistSQL Duration 有小幅度升高**，说明此时可能存在汇总查询类的慢 SQL，在 TOP SQL 方向排查过程中也可以看到 IP91 节点存在一条执行两次的平均执行时间 SQL 达 26s 的慢SQL；   
 - **Coprocessor Seconds 0.999 分位数**，四台 TiDB 实例均幅度不等升高；  

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;综上所述，基本排除 TiDB 层组件瓶颈问题导致的 SQL Duration 升高;

 - 案例 Metrics   
 ![7](./check-report-pic/7.png)   


### TiKV 部分组件排查

#### TiDB-KV  

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

 - KV Request OPS  

 - KV Request Duration 99 by store  

 - KV Request Duration 99 by type  



 - 案例 Metrics   
 ![8](./check-report-pic/8.png)   
 ![9](./check-report-pic/9.png)   

#### TiKV-gRPC  

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

 - 案例 Metrics   
 ![10](./check-report-pic/10.png)   


#### TiKV-Secheduler  

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

 - 案例 Metrics   
 ![12](./check-report-pic/12.png)   

![13](./check-report-pic/13.png)   

![14](./check-report-pic/14.png)   

![15](./check-report-pic/15.png)   

![16](./check-report-pic/16.png)   

![17](./check-report-pic/17.png)   

![18](./check-report-pic/18.png)   

![19](./check-report-pic/19.png)   




## 问题解决



## 归纳总结





## 参考文章  



