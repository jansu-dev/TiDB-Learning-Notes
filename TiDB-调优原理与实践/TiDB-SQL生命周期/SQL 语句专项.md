# SQL 语句专项  

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