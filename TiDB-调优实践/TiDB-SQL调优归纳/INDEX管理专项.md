# TiDB-Index专项  
时间：2020-01-31  


 - 索引创建使用
> - [multiColumn_index](#multiColumn_index)  
> - [expersion_index](#cluster_index)  
> - [cluster_index](#cluster_index)  
 - 索引相关系统表  
> - [tidb_indexes](#tidb_indexes)  
 - 索引Hint  
> - [use_index](#use_index)  
> - [force_index](#force_index)  
> - [ignore_index](#ignore_index)  


### 索引创建使用

#### multiColumn_index
Effect: Most of them called Cover_Index which contain all needed column in select statement are used to save second select data by row_id   
Limit:   
Example:   
```sql
create table multi_t(a char(10) primary key,b int,c int);  

insert into multi_t values ("str1",1,2),("str2",3,4);

alter table multi_t add index multi_key (a,b);

explain select * from jan.multi_t where a = "str1" and b = "1";
+-------------------+---------+------+---------------------------------+----------------------+
| id                | estRows | task | access object                   | operator info        |
+-------------------+---------+------+---------------------------------+----------------------+
| Selection_6       | 0.00    | root |                                 | eq(jan.multi_t.b, 1) |
| └─Point_Get_5     | 1.00    | root | table:multi_t, index:PRIMARY(a) |                      |
+-------------------+---------+------+---------------------------------+----------------------+ 

explain select * from jan.multi_t use index(multi_key) where a = "str1" and b = "1";
+-------------------------------+---------+-----------+--------------------------------------+-----------------------------------------------------------+
| id                            | estRows | task      | access object                        | operator info                                             |
+-------------------------------+---------+-----------+--------------------------------------+-----------------------------------------------------------+
| IndexLookUp_7                 | 0.00    | root      |                                      |                                                           |
| ├─IndexRangeScan_5(Build)     | 0.00    | cop[tikv] | table:multi_t, index:multi_key(a, b) | range:["str1" 1,"str1" 1], keep order:false, stats:pseudo |
| └─TableRowIDScan_6(Probe)     | 0.00    | cop[tikv] | table:multi_t                        | keep order:false, stats:pseudo                            |
+-------------------------------+---------+-----------+--------------------------------------+-----------------------------------------------------------+
```


#### expersion_index
Effect: That omit _row_id from Key_Value String in TiKV means omit one step to select real data by _row_id,accelerating select speed   
Limit:    
Example:   
```sql
tiup cluster edit-config tidb-test

......
server_configs:
  tidb:
    allow-expression-index: true
......

tiup cluster reload tidb-test -R tidb

create table expersion_t(a char(10) primary key,b int,c int);  

insert into expersion_t values ("str1",1,2),("str2",3,4);

alter table expersion_t add index expersion_key ((a like "%t%"));  

explain select * from jan.expersion_t use index(expersion_key) where a like '%t%';
+------------------------------+---------+-----------+-------------------------------------------------------------+------------------------------------+
| id                           | estRows | task      | access object                                               | operator info                      |
+------------------------------+---------+-----------+-------------------------------------------------------------+------------------------------------+
| IndexLookUp_8                | 1.60    | root      |                                                             |                                    |
| ├─IndexFullScan_5(Build)     | 2.00    | cop[tikv] | table:expersion_t, index:expersion_key(`a` like _utf8'%t%') | keep order:false, stats:pseudo     |
| └─Selection_7(Probe)         | 1.60    | cop[tikv] |                                                             | like(jan.expersion_t.a, "%t%", 92) |
|   └─TableRowIDScan_6         | 2.00    | cop[tikv] | table:expersion_t                                           | keep order:false, stats:pseudo     |
+------------------------------+---------+-----------+-------------------------------------------------------------+------------------------------------+
```



#### cluster_index
Effect: That omit _row_id from Key_Value String in TiKV means omit one step to select real data by _row_id,accelerating select speed   
Limit:   
  1. alter-primary-key = false 
  2. primary key must be a single integer column (TiDB 4.0)
  3. primary key maybe support char and decimal column (TiDB 5.0)    
Example:   
```sql
create table cluster_t(a char(10) primary key,b int,c int);  
insert into cluster_t values ("str1",1,2),("str2",3,4);
explain select * from jan.cluster_t where a = "str1";
+-------------+---------+------+-----------------------------------+---------------+
| id          | estRows | task | access object                     | operator info |
+-------------+---------+------+-----------------------------------+---------------+
| Point_Get_1 | 1.00    | root | table:cluster_t, index:PRIMARY(a) |               |
+-------------+---------+------+-----------------------------------+---------------+
```


### 索引相关系统表  

#### tidb_indexes  
Effect: show the information about index of all the database    
Limit:    
Example:   
```sql
select * from information_schema.tidb_indexes where table_schema
='test' and table_name="t";
```

### 索引Hint  

#### use_index   
syntax: use index([index__name],[index_name])   
Limit:   
Example:    
  ```sql
   select * from t use index(t1);
  ```
#### force_index    
syntax: force index([index__name],[index_name])    
Limit:   
Example:      
  ```sql
   select * from t force index(t1);
  ```

#### ignore_index    
syntax: ignore index([index__name],[index_name])   
Limit:   
Example:    
  ```sql
   select * from t ignore index(t1);
   select * from t use index();
  ```