# TiDB-5.0.0-rc 新特性  
时间：2021-02-16   
版本：5.0.0-rc   


## Summary  

> - [5版本关键特性](#5版本关键特性)    
> - [开启聚簇索引功能](#开启聚簇索引功能)    
> - [开启异步提交事务功能](#开启异步提交事务功能)    
> - [优化EXPLAIN功能](#优化EXPLAIN功能)    
> - [引入不可见索引功能](#引入不可见索引功能)    
> - [备份文件到S3与GCS并恢复](#备份文件到S3与GCS并恢复)    
> - [过提升优化器的稳定性及限制系统任务对资源的占用，降低系统的抖动](#过提升优化器的稳定性及限制系统任务对资源的占用，降低系统的抖动)    
> - [引入Raft_Joint_Consensus算法，确保Region成员变更时系统的可用性](#引入Raft_Joint_Consensus算法，确保Region成员变更时系统的可用性)    
> - [参考文章](#参考文章)    

## 5版本关键特性   

功能特性：  

1. 开启聚簇索引功能
2. 开启异步提交事务功能  
3. 优化EXPLAIN功能    
4. 引入不可见索引功能    
5. 备份文件到S3与GCS并恢复   

内部特性：    

1. 过提升优化器的稳定性及限制系统任务对资源的占用，降低系统的抖动
2. 引入Raft_Joint_Consensus算法，确保Region成员变更时系统的可用性     


## 开启聚簇索引功能   

| v5.0 之前限制 | v5.0.0-rc限制 |
| - | - |
| 表设置主键 | 无 |
| 主键类型为 INTEGER 或 BIGINT | 无 |
| 主键只有一列 | 无 |

```sql
MySQL [jan]> create database jan;

MySQL [jan]> CREATE TABLE t1(id bigint not null primary key auto_increment,
    b char(100),
    index(b));


MySQL [jan]> INSERT INTO t1 VALUES (1, 'aaa'), (2, 'bbb');

MySQL [jan]> EXPLAIN SELECT * FROM t1 WHERE id = 1;
+-------------+---------+------+---------------+---------------+
| id          | estRows | task | access object | operator info |
+-------------+---------+------+---------------+---------------+
| Point_Get_1 | 1.00    | root | table:t1      | handle:1      |
+-------------+---------+------+---------------+---------------+
1 row in set (0.00 sec)


```  




## 开启异步提交事务功能  


## 优化EXPLAIN功能


## 引入不可见索引功能  


## 备份文件到S3与GCS并恢复


## 过提升优化器的稳定性及限制系统任务对资源的占用，降低系统的抖动

## 引入Raft_Joint_Consensus算法，确保Region成员变更时系统的可用性


## 参考文章   

 - [官方文档-TiDB 5.0 RC Release Notes](https://docs.pingcap.com/zh/tidb/v5.0/release-5.0.0-rc)  
 
 - [官方文档-聚簇索引使用方法](https://docs.pingcap.com/zh/tidb/v5.0/clustered-indexes#tidb-v50-%E5%89%8D%E6%94%AF%E6%8C%81%E9%83%A8%E5%88%86%E4%B8%BB%E9%94%AE%E4%BD%9C%E4%B8%BA%E8%81%9A%E7%B0%87%E7%B4%A2%E5%BC%95)  
