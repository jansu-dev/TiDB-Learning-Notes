# SQL 语句专项  
时间：2020-01-31

 - SQL相关系统表  
> - [slow_query](#slow_query)  
> - [cluster_slow_query](#cluster_slow_query)  
> - [statements_summary](#statements_summary)  
> - [cluster_statement_summary](#cluster_statement_summary)  
> - [statements_summary_history](#statements_summary_history)  
 - 实用SQL传送门  
> - [SQL_Order_by_Eplased_Time](#SQL_Order_by_Eplased_Time)  
> - [查询前十条延时SQL](#查询前十条延时SQL)  
> - [查询某QUERY的平均延时](#查询某QUERY的平均延时)  
> - [查询是否存在多个执行计划SQL](#查询是否存在多个执行计划SQL)  
> - [查询某用户的TOP_SQL](#查询某用户的TOP_SQL)  
> - [查询统计信息过期的慢查询](#查询统计信息过期的慢查询)  
> - [查询执行计划变更导致的慢查询](#查询执行计划变更导致的慢查询)  
> - [查询仅在特定时间段存在的慢查询](#查询仅在特定时间段存在的慢查询)  

### SQL相关系统表

#### statements_summary  
作用：通过指纹信息汇总，用于保存历史执行 SQL 的汇总信息     
保留时间：默认保持30min     


#### cluster_statement_summary  
作用：与 statement_summary 作用一致，但可查询整个 TiDB 集群的 statement_summary 信息   
保留时间：   

#### cluster_slow_query  
作用：与 slow_query 作用一致，但可查询整个 TiDB 集群的 slow_query 信息   
保留时间：   

#### slow_query
作用：是 TiDB 内部的系统表，内容源自于 sql-query-file 文件      
更改慢日志文件：
```
MySQL [(none)]> set tidb_slow_query_file = 'log/tidb_slow_query.log';  

MySQL [(none)]> show variables like '%tidb_slow_query_file%';
+----------------------+-------------------------+
| Variable_name        | Value                   |
+----------------------+-------------------------+
| tidb_slow_query_file | log/tidb_slow_query.log |
+----------------------+-------------------------+
```


#### statements_summary_history
作用：与statements_history功能相同     
保留时间：   


### 实用SQL传送门

#### SQL_Order_by_Eplased_Time
```sql
select query sql_text,
       sum_query_time,
       mnt as executions,
       avg_query_time,
       avg_proc_time,
       avg_wait_time,
       max_query_time,
       avg_backoff_time,
       (case
         when avg_proc_time = 0 then
          'point_get or commit'
         when (avg_proc_time > avg_wait_time and
              avg_proc_time > avg_backoff_time) then
          'coprocessor_process'
         when (avg_backoff_time > avg_wait_time and
              avg_proc_time < avg_backoff_time) then
          'backoff'
         else
          'coprocessor_wait'
       end) as type
  from (select substr(query, 1, 100) query,
               count(*) mnt,
               avg(query_time) avg_query_time,
               avg(process_time) avg_proc_time,
               avg(wait_time) avg_wait_time,
               max(query_time) max_query_time,
               sum(query_time) sum_query_time,
               avg(backoff_time) avg_backoff_time
          from information_schema.slow_query
         where time >= '2021-01-22 06:00:00'
           and time <= '2021-01-22 20:00:00'
           and (lower(query) not like 'analyze%' or
               lower(query) not like 'alter%')
         group by substr(query, 1, 100)) t
 order by sum_query_time desc,
          executions     desc,
          avg_query_time desc limit 20;
```



#### 查询前十条延时SQL  
  ```sql
   select sum_latency, avg_latency, exec_count, query_sample_text
     from information_schema.statements_summary
    order by sum_lentcy desc limit 10;
  ```  


#### 查询某QUERY的平均延时  
  ```sql
   select sum_latency, avg_latency, exec_count, query_sample_text
     from information_schema.statements_summary
    where digest_text like 'select sum%';
  ```  


#### 查询是否存在多个执行计划SQL  
  ```sql
   select digest,count(*) plan_num,min(query_sample_text),min(plan),max(plan) from information_schema.statements_summary group by digest having plan_num >= 1;  
  ```  


#### 查询某用户的TOP_SQL  
  ```sql
   select query_time, query, user
     from information_schema.cluster_slow_query
    where user like 'root%'
     order by query_time desc limit 10;
  ```  

#### 查询统计信息过期的慢查询  
  ```sql
   select query, query_time, stats
     from information_schema.cluster_slow_query
    where is_internal = false
      and stats like '%pseudo%';
  ```  

#### 查询执行计划变更导致的慢查询  
  ```sql
   select count(distinct plan_digest) as count, digest, min(query)
      from information_schema.cluster_slow_query
     group by digest
    having count > 1 limit 3;
  ```  

#### 查询仅在特定时间段存在的慢查询  
  ```sql
   select *
   from (select count(*),
                min(time),
                sum(query_time) as sum_query_time,
                sum(Process_time) as sum_process_time,
                sum(wait_time) as sum_wait_time,
                sum(commit_time),
                min(query),
                digest
           from information_schema.cluster_slow_query
          where time >= '2021-01-31 03:13:59'
            and time < '2021-01-31 03:14:01'
            and is_internal = false
          group by digest) as t1
    where t1.digest not in (select digest
                            from information_schema.cluster_slow_query
                           where time >= '2021-01-31 03:17:20'
                             and time < '2021-01-31 03:17:28'
                           group by digest)
    group by t1.sum_query_time desc limit 10\G  
  ```  

