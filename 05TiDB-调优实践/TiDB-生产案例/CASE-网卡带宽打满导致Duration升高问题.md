# CASE-网卡带宽打满导致Duration升高问题
时间：2021-05-07


<!-- TOC -->

- [CASE-网卡带宽打满导致Duration升高问题](#case-网卡带宽打满导致duration升高问题)
    - [一、问题现象](#一问题现象)
    - [二、定位原因](#二定位原因)
    - [三、解决方案](#三解决方案)

<!-- /TOC -->

## 一、问题现象
1.1 客户反馈问题
据客户反馈，在 13:30 左右出现 SQL 整体变慢的现象，询问原因及解决方案。
1.2 Grafana 监控
首先，一句观察确实存在 Duration 整体升高的现象；    
  ![01.jpg](./images/CASE-网卡带宽打满导致Duration升高问题/01.jpg)      
但是，该时段的 SQL OPS 却未升高，说明此时段并未出现应用暴增大量 SQL 情况；  
  ![02.jpg](./images/CASE-网卡带宽打满导致Duration升高问题/02.jpg)    
观察内存变化，发现 TIDB 节点（IP15、IP16）中，IP15 节点内存使用明显升高，可能问题出在传送到该节点的 SQL 出现异常；  
  ![03.jpg](./images/CASE-网卡带宽打满导致Duration升高问题/03.jpg)    
同时，观察到 TiKV CPU 使用率整体升高，不太可能由于 TiKV 性能抖动、网络抖动等原因；   
  ![04.jpg](./images/CASE-网卡带宽打满导致Duration升高问题/04.jpg)    
观察网络流量，发现 IP15 节点的 Inbound 达到 1G，同时其他 TiKV 节点的 Outbound 升高，说明IP15 可能被打满，进而影响整个集群性能。
  ![05.jpg](./images/CASE-网卡带宽打满导致Duration升高问题/05.jpg)    
1.3 网卡带宽
该生产集群为万兆网卡；

```Shell
[tidb@ip-9-23-3-15 log]$ ethtool bond0 
Settings for bond0: 
        ......
        Speed: 10000Mb/s
        ......
```

## 二、定位原因

2.1 检查语句

```SQL
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
         where time >= '2021-05-07 13:20:00'
           and time <= '2021-05-07 13:35:00'
           and (lower(query) not like 'analyze%' or
               lower(query) not like 'alter%')
         group by substr(query, 1, 100)) t
 order by sum_query_time desc,
          executions     desc,
          avg_query_time desc limit 20;
```
2.2 输出结果

```SQL
*************************** 1. row *************************** 
        sql_text: SELECT  id AS id, code AS code, relationNo AS relationNo, proposalNo AS proposalNo, ssProposalNo AS  
  sum_query_time: 904.0470936730003 
      executions: 1040 
  avg_query_time: 0.8692760516086542 
   avg_proc_time: 0.00001153846153846154 
   avg_wait_time: 0.00000576923076923077 
  max_query_time: 4.691674843 
avg_backoff_time: 0 
            type: coprocessor_process 
*************************** 2. row *************************** 
        sql_text: SELECT  id AS id, orderId AS orderId, type AS type, insuredType AS insuredType, changeInsuredType AS 
  sum_query_time: 399.65042316099994 
      executions: 437 
  avg_query_time: 0.9145318607803202 
   avg_proc_time: 0.00043935926773455404 
   avg_wait_time: 0.001796338672768879 
  max_query_time: 3.965649058 
avg_backoff_time: 0.000004576659038901602 
            type: coprocessor_wait 
*************************** 3. row *************************** 
        sql_text: SELECT  id AS id, orderId AS orderId, orderType AS orderType, funNo AS funNo, funUrl AS funUrl, isCo 
  sum_query_time: 286.730882666 
      executions: 255 
  avg_query_time: 1.1244348339843138 
   avg_proc_time: 0.0003490196078431374 
   avg_wait_time: 0.0027568627450980394 
  max_query_time: 5.012617706 
avg_backoff_time: 0 
            type: coprocessor_wait 
*************************** 4. row *************************** 
        sql_text: select id, product_model_id,message_template_id,         relation_list,product_statement_title,fixed 
  sum_query_time: 218.80345473799997 
      executions: 193 
  avg_query_time: 1.1336966566735749 
   avg_proc_time: 0.00021761658031088085 
   avg_wait_time: 0 
  max_query_time: 5.437438295 
avg_backoff_time: 0 
            type: coprocessor_process 
*************************** 5. row *************************** 
        sql_text: INSERT INTO insurance_order_to_org  (id, orderId, orderType, funNo, funUrl, isCompleted, sort, creat 
  sum_query_time: 213.487945341 
      executions: 173 
  avg_query_time: 1.234034366132948 
   avg_proc_time: 0 
   avg_wait_time: 0 
  max_query_time: 5.538053322 
avg_backoff_time: 0 
            type: point_get or commit 
*************************** 6. row *************************** 
        sql_text: SELECT  id AS id, orderId AS orderId, pdfType AS pdfType, createDate AS createDate, updateDate AS up 
  sum_query_time: 185.341252661 
      executions: 188 
  avg_query_time: 0.9858577269202128 
   avg_proc_time: 0.0002553191489361702 
   avg_wait_time: 0.002398936170212766 
  max_query_time: 3.783315653 
avg_backoff_time: 0 
            type: coprocessor_wait 
*************************** 7. row *************************** 
        sql_text: commit; 
  sum_query_time: 169.47936289400002 
      executions: 155 
  avg_query_time: 1.0934152444774194 
   avg_proc_time: 0 
   avg_wait_time: 0 
  max_query_time: 2.877081402 
avg_backoff_time: 0 
            type: point_get or commit 
*************************** 8. row *************************** 
        sql_text: select id, product_id,main_clause_code,main_clause_name,clause_type, liability_type,clause_code,medi 
  sum_query_time: 157.704614038 
      executions: 144 
  avg_query_time: 1.0951709308194444 
   avg_proc_time: 0.0004097222222222223 
   avg_wait_time: 0.0001388888888888889 
  max_query_time: 4.499073241 
avg_backoff_time: 0 
            type: coprocessor_process 
*************************** 9. row *************************** 
        sql_text: INSERT IGNORE  INTO rabbitmq_consume_record  (id, orderId, pdfType, createDate, updateDate, consumeS 
  sum_query_time: 137.144392501 
      executions: 112 
  avg_query_time: 1.2245035044732142 
   avg_proc_time: 0 
   avg_wait_time: 0 
  max_query_time: 4.619352579 
avg_backoff_time: 0 
            type: point_get or commit 
*************************** 10. row *************************** 
        sql_text: SELECT * FROM `ncisp_orders` LIMIT 8729000, 1000; 
  sum_query_time: 136.27416871 
      executions: 1 
  avg_query_time: 136.27416871 
   avg_proc_time: 630.249 
   avg_wait_time: 20.584 
  max_query_time: 136.27416871 
avg_backoff_time: 0 
            type: coprocessor_process 
10 rows in set (1.23 sec) 
```
2.3 执行计划

```SQL
[ogg33@9.23.3.9:4000] [ncisp]> explain SELECT * FROM `ncisp_orders` LIMIT 8729000, 1000; 
+----------------------------+------------+-----------+--------------------+----------------------------+ 
| id                         | estRows    | task      | access object      | operator info              | 
+----------------------------+------------+-----------+--------------------+----------------------------+ 
| Limit_7                    | 1000.00    | root      |                    | offset:8729000, count:1000 | 
| ©∏©§TableReader_12           | 8730000.00 | root      |                    | data:Limit_11              | 
|   ©∏©§Limit_11               | 8730000.00 | cop[tikv] |                    | offset:0, count:8730000    | 
|     ©∏©§TableFullScan_10     | 8730000.00 | cop[tikv] | table:ncisp_orders | keep order:false           | 
+----------------------------+------------+-----------+--------------------+----------------------------+ 
4 rows in set (0.00 sec) 
 

[ogg33@9.23.3.9:4000] [ncisp]> select count(*) from ncisp_orders; 
+----------+ 
| count(*) | 
+----------+ 
|  8789461 | 
+----------+ 
1 row in set (0.83 sec) 
```

2.4 估算数据量

```SQL
[ogg33@9.23.3.9:4000] [ncisp]> show table status like '%ncisp_orders'\G  
*************************** 1. row *************************** 
           Name: ncisp_orders 
         Engine: InnoDB 
        Version: 10 
     Row_format: Compact 
           Rows: 8788191 
 Avg_row_length: 16710 
    Data_length: 146854445481 
Max_data_length: 0 
   Index_length: 1678429127 
      Data_free: 0 
 Auto_increment: NULL 
    Create_time: 2021-04-26 21:05:17 
    Update_time: NULL 
     Check_time: NULL 
      Collation: utf8mb4_bin 
       Checksum:  
 Create_options:  
        Comment: ∂©µ•±Ì 
1 row in set (0.09 sec) 
```


平均行长 16710 bytes（16K），执行计划该条 SQL 的物理执行中包含“全表扫描”，在 TiKV 层扫描出 8730000 行，换算后接近 8730000 * 16K = 133G；
万兆网卡 10000M bit/s 换算后约为 120G Bytes/s，可见，此时 IP15 节点的网卡因这条 SELECT 被打满。


## 三、解决方案
需向应用查明该条 SQL 的执行目的，如非必要，尽力规避或将该 SQL 拆分为多批次小数据量查询。

