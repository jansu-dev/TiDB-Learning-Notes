# TiDB-Index专项  
时间：2020-01-31

 - 索引相关系统表  
> - [tidb_indexes](#tidb_indexes)  
 - 索引Hint  
> - [use_index](#use_index)  
> - [force_index](#force_index)  
> - [ignore_index](#ignore_index)  


### 索引相关系统表  

#### tidb_indexes  
effect: show the information about index of all the database
example:   
```
select * from information_schema.tidb_indexes where table_schema
='test' and table_name="t";
```

### 索引Hint  

#### use_index   
syntax: use index([index__name],[index_name])   
example:    
  ```sql
   select * from t use index(t1);
  ```
#### force_index    
syntax: force index([index__name],[index_name])    
example:    
  ```sql
   select * from t force index(t1);
  ```

#### ignore_index    
syntax: ignore index([index__name],[index_name])   
example:    
  ```sql
   select * from t ignore index(t1);
   select * from t use index();
  ```