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

 - 关闭 clustered_index 特性（同 4.0.x 部分主键聚簇索引特性一样）：   
 仅支持主键为 INTEGER 或 BIGINT、主键只有一列的聚簇索引，当条件不满足时，便采用一个 64 位 handle 值代替主键组织数据，也就是 _row_id；  
 下列 demo 中 t1 表的查询行为表现为从 TiKV 获取解压的 KV 数据在 TiDB 中直接筛选过滤便获得结果；    
 而 t2 表的查询行为表现为 TiDB 先从 TiKV 中获得主键索引页子节点中 guid 列的 _row_id 值，再从 TiKV 中获取改行数据对应数据；    
    - 非主键列查询  
      ```sql
      -- 表 t1 为索引组织表、表 t2 为普通表   
      -- 聚簇索引组织表
      MySQL [jan]> create database jan;
      
      MySQL [jan]> CREATE TABLE t1(id bigint not null primary key       auto_increment,
        b char(100),
        index(b));
      
      
      MySQL [jan]> INSERT INTO t1 VALUES (1, 'aaa'), (2, 'bbb');
      
      MySQL [jan]> EXPLAIN SELECT * FROM t1 WHERE id = 1;
      +-------------+---------+------+---------------+---------------+
      | id          | estRows | task | access object | operator info |
      +-------------+---------+------+---------------+---------------+
      | Point_Get_1 | 1.00    | root | table:t1      | handle:1      |
      +-------------+---------+------+---------------+---------------+

      
      -- 非聚簇索引组织表
      MySQL [jan]> CREATE TABLE t2 (
       guid CHAR(32) NOT NULL PRIMARY KEY,
       b CHAR(100),
       INDEX(b)
      );
      
      MySQL [jan]> INSERT INTO t2 VALUES ('02dd050a978756da0aff6b1d1d7c8aef', 'aaa'), ('35bfbc09cb3c93d8ef032642521ac042', 'bbb');
      
      MySQL [jan]> EXPLAIN SELECT * FROM t2 WHERE guid = '02dd050a978756da0aff6b1d1d7c8aef';
      +-------------+---------+------+-------------------------------+---------------+
      | id          | estRows | task | access object                 | operator info |
      +-------------+---------+------+-------------------------------+---------------+
      | Point_Get_1 | 1.00    | root | table:t2, index:PRIMARY(guid) |               |
      +-------------+---------+------+-------------------------------+---------------+

      ```  
      - 主键列查询    
      对于索引组织表 t1 中非主键列查询，执行计划为在 TiKV 中扫描索引获取结果，在 TiDB 中过滤直接获得数据；    
      而在非索引组织表 t2 中，执行计划为在 TiKV 中全表扫描 t2 并过滤后符合条件的行，最后在 TiDB 中过滤索要查询的列数据返回给客户端；    
      可见因为是 5.0.0-rc（或5.0.0-rc关闭该特性） 之前不支持不符合条件的聚簇索引，因此 t2 表在建表时语句 INDEX(b) 被忽略。     
      ```sql
      MySQL [jan]> EXPLAIN SELECT id FROM t1 WHERE b = 'aaaa';
      +--------------------------+---------+-----------+----------------------+-------------------------------------------------------+
      | id                       | estRows | task      | access object        | operator info                                         |
      +--------------------------+---------+-----------+----------------------+-------------------------------------------------------+
      | Projection_4             | 0.00    | root      |                      | jan.t1.id                                             |
      | └─IndexReader_6          | 0.00    | root      |                      | index:IndexRangeScan_5                                |
      |   └─IndexRangeScan_5     | 0.00    | cop[tikv] | table:t1, index:b(b) | range:["aaaa","aaaa"], keep order:false, stats:pseudo |
      +--------------------------+---------+-----------+----------------------+-------------------------------------------------------+
      
      MySQL [jan]> EXPLAIN SELECT guid FROM t2  WHERE b = 'aaaa';
      +---------------------------+---------+-----------+---------------+--------------------------------+
      | id                        | estRows | task      | access object | operator info                  |
      +---------------------------+---------+-----------+---------------+--------------------------------+
      | Projection_4              | 0.00    | root      |               | jan.t2.guid                    |
      | └─TableReader_7           | 0.00    | root      |               | data:Selection_6               |
      |   └─Selection_6           | 0.00    | cop[tikv] |               | eq(jan.t2.b, "aaaa")           |
      |     └─TableFullScan_5     | 2.00    | cop[tikv] | table:t2      | keep order:false, stats:pseudo |
      +---------------------------+---------+-----------+---------------+--------------------------------+
      ```

 - 操作 clustered-index 特性
  ```sql  
   -- 查询表是否有聚簇索引，{tbl_name} 替换为所要查询的表名   
   select tidb_pk_type from information_schema.tables where table_name = '{tbl_name}';   

   -- 查看 clustered-index 特性是否开始   
   show session variables like 'tidb_enable_clustered_index';

   show global variables like 'tidb_enable_clustered_index';

   -- 打开 clustered-index 特性   
   set global tidb_enable_clustered_index = 1;

   -- 关闭 clustered-index 特性   
   set global tidb_enable_clustered_index = 0;
  ```

 - 开启 clustered-index 特性   
    - 非主键列查询    
    在开始 clustered-index 特性后的 5.0.0-rc TiDB 中，非主键列查询执行计划为一次从 TiKV 中查询符合主键索引组织表获取数据后，在 TiDB 端直接返回给客户端；   
      ```sql
       MySQL [jan]> CREATE TABLE t3 (
        key_a INT NOT NULL,
        key_b INT NOT NULL,
        b CHAR(100),
        PRIMARY KEY (key_a, key_b)
       );
       
       MySQL [jan]> INSERT INTO t3 VALUES (1, 1, 'aaa'), (2, 2, 'bbb');
       
       MySQL [jan]> EXPLAIN SELECT * FROM t3 WHERE key_a = 1 AND key_b = 2;
       +-------------+---------+------+---------------------------------------+---------------+
       | id          | estRows | task | access object                         | operator info |
       +-------------+---------+------+---------------------------------------+---------------+
       | Point_Get_1 | 1.00    | root | table:t3, index:PRIMARY(key_a, key_b) |               |
       +-------------+---------+------+---------------------------------------+---------------+
      ```
 - 聚簇索引的缺点   
 开启聚簇索引后，主键代替64 位的 handle 值 _row_id 代表每一行，可能会导致存储空间的上升，尤其是表中存在许多二级索引时；   
 如下表 demo 表 t1 主键的类型为 char(32)，那么索引大约需要 8+32 = 40 （b 列宽 + 主键列宽）个字节，如果是普通索引仅需 8 + 8 = 16 （b 列宽 + _row_id 列宽）个字节；   
    - demo
    ```sql
     CREATE TABLE t1 (
      guid CHAR(32) NOT NULL PRIMARY KEY,
      b BIGINT,
      INDEX(b)
     );
    ```
 - 聚簇索引的优点   
    - 插入数据时会减少一次从网络写入索引数据，因为主键索引就是表结构，与普通索引不同，减少了主键索引的写次数；   
    - 等值条件查询仅涉及主键时会减少一次从网络读取数据，因为主键代替了 _row_id 作为内部行指针，避免了二次回表的网络操作；      
    - 范围条件查询仅涉及主键时会减少多次从网络读取数据，同等值条件查询原理相同，范围条件查询减少了多次回表；   
    - 等值或范围条件查询涉及主键的前缀时会减少多次从网络读取数据，原理同范围条件查询；   


## 开启异步提交事务功能  


## 优化EXPLAIN功能


## 引入不可见索引功能  
DBA 调试和选择相对最优的索引时，可以通过 SQL 语句将某个索引设置成 Visible 或者 Invisible，修改后优化器会根据索引的可见性决定是否将此索引加入到索引列表中。    
 - 不可见索引注意事项   
    - “不可见” 是仅仅对优化器而言的，不可见索引仍然可以被修改或删除，也就是当插入删除数据时改索引也为同时维护着；  
    - 与 MySQL 类似，TiDB 不允许将主键索引设为不可见；   
    - MySQL 中提供的优化器开关 use_invisible_indexes=on 可将所有的不可见索引重新设为可见。该功能在 TiDB 中不可用；   
    ```sql
     MySQL [jan]> show variables like 'use_invisible_indexes';
     Empty set (0.00 sec)
     
     MySQL [jan]> set use_invisible_indexes=1;
     ERROR 1193 (HY000): Unknown system variable 'use_invisible_indexes'
    ``` 

 - 操作可见索引不可见    
 查询只能先走全报表扫描；  
 ```sql  
  MySQL [jan]> ALTER TABLE t1 ALTER INDEX idx_b1 INVISIBLE;  

  MySQL [jan]> SHOW CREATE TABLE t1\G
  *************************** 1. row ***************************
         Table: t1
  Create Table: CREATE TABLE `t1` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT,
    `b` char(100) DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `b` (`b`) /*!80000 INVISIBLE */
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin AUTO_INCREMENT=30002   

  MySQL [jan]> EXPLAIN SELECT id FROM t1 WHERE b = 'aaaa';
  +---------------------------+---------+-----------+---------------+--------------------------------+
  | id                        | estRows | task      | access object | operator info                  |
  +---------------------------+---------+-----------+---------------+--------------------------------+
  | Projection_4              | 0.00    | root      |               | jan.t1.id                      |
  | └─TableReader_7           | 0.00    | root      |               | data:Selection_6               |
  |   └─Selection_6           | 0.00    | cop[tikv] |               | eq(jan.t1.b, "aaaa")           |
  |     └─TableFullScan_5     | 2.00    | cop[tikv] | table:t1      | keep order:false, stats:pseudo |
  +---------------------------+---------+-----------+---------------+--------------------------------+
 ```

 - 操作不可见索引可见   
 查询可以先走索引扫描
 ```sql   
 MySQL [jan]> alter table t1 alter index b VISIBLE;

 MySQL [jan]> EXPLAIN SELECT id FROM t1 WHERE b = 'aaaa';
 +--------------------------+---------+-----------+----------------------+-------------------------------------------------------+
 | id                       | estRows | task      | access object        | operator info                                         |
 +--------------------------+---------+-----------+----------------------+-------------------------------------------------------+
 | Projection_4             | 0.00    | root      |                      | jan.t1.id                                             |
 | └─IndexReader_6          | 0.00    | root      |                      | index:IndexRangeScan_5                                |
 |   └─IndexRangeScan_5     | 0.00    | cop[tikv] | table:t1, index:b(b) | range:["aaaa","aaaa"], keep order:false, stats:pseudo |
 +--------------------------+---------+-----------+----------------------+-------------------------------------------------------+
 ```



## 备份文件到S3与GCS并恢复


## 过提升优化器的稳定性及限制系统任务对资源的占用，降低系统的抖动

## 引入Raft_Joint_Consensus算法，确保Region成员变更时系统的可用性


## 参考文章   

 - [官方文档-TiDB 5.0 RC Release Notes](https://docs.pingcap.com/zh/tidb/v5.0/release-5.0.0-rc)  
 
 - [官方文档-聚簇索引使用方法](https://docs.pingcap.com/zh/tidb/v5.0/clustered-indexes#tidb-v50-%E5%89%8D%E6%94%AF%E6%8C%81%E9%83%A8%E5%88%86%E4%B8%BB%E9%94%AE%E4%BD%9C%E4%B8%BA%E8%81%9A%E7%B0%87%E7%B4%A2%E5%BC%95)  
