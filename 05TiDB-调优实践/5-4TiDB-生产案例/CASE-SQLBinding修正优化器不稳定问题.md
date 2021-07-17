# SQL Binding 修正 CBO 优化器不稳定情况
时间:2021-02-06   

## Summary
> - [SQL_BINDING用法](#SQL_BINDING用法)   
> - [生产案例](#生产案例)   

## SQL_BINDING用法
```sql

show global binding;

```


## 生产案例  

 - 错误执行计划  
 ![1](./images/sql-binding-pic/02.png)


 - binding_SQL
   ```sql
    CREATE GLOBAL BINDING FOR 
    SELECT  * FROM md_meter_plan_record_info mpri
    WHERE mpri.  meter_code_id='88aae1be19614cafa3a87dbb01445301'
        AND mpri.del_flag=0
        AND mpri.meter_read_reason != '09'
        AND mpri.city_id=241
        AND mpri.city_code=350800
    ORDER BY mpri.create_time DESC LIMIT 1
    USING 
    SELECT  * FROM md_meter_plan_record_info mpri use   index (idx_mmpri_mcid)
    WHERE mpri.  meter_code_id='88aae1be19614cafa3a87dbb01445301'
        AND mpri.del_flag=0
        AND mpri.meter_read_reason != '09'
        AND mpri.city_id=241
        AND mpri.city_code=350800
    ORDER BY mpri.create_time DESC LIMIT 1;
   ```

 - 修正执行计划  
 ![1](./images/sql-binding-pic/01.png)






## 参考文章









