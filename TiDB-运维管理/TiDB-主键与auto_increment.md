# TiDB-主键与auto_increment  
时间: 2021-03-09  

[开启 alter-primary-key](https://docs.pingcap.com/zh/tidb/stable/tidb-configuration-file#alter-primary-key)  


增删主键
TiDB 3.0.6 Release 开始支持 alter primary key,   
[Feature PR #13522](https://github.com/pingcap/tidb/pull/13522)
[SQL 语法图 alter-table](https://docs.pingcap.com/zh/tidb/stable/sql-statement-alter-table#alter-table)   
```sql
MySQL [jan]> create table jan_test_id (id int,name varchar(20));

MySQL [jan]> alter table jan_test_id add constraint primary key(id);

MySQL [jan]> show create table jan_test_id;
+-------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Table       | Create Table                                                                                                                                                              |
+-------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| jan_test_id | CREATE TABLE `jan_test_id` (
  `id` int(11) NOT NULL,
  `name` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin |
+-------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

MySQL [jan]> alter table jan_test_id drop primary key;

MySQL [jan]> show create table jan_test_id;
+-------------+-----------------------------------------------------------------------------------------------------------------------------------------------------+
| Table       | Create Table                                                                                                                                        |
+-------------+-----------------------------------------------------------------------------------------------------------------------------------------------------+
| jan_test_id | CREATE TABLE `jan_test_id` (
  `id` int(11) NOT NULL,
  `name` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin |
+-------------+-----------------------------------------------------------------------------------------------------------------------------------------------------+
1 row in set (0.00 sec)

```


自增主键限制：   
[不保证自动分配的值的连续性](https://docs.pingcap.com/zh/tidb/stable/mysql-compatibility#%E8%87%AA%E5%A2%9E-id)   

tidb_allow_remove_auto_inc 系统变量开启或者关闭允许移除列的 AUTO_INCREMENT 属性   
TiDB 不支持添加列的 AUTO_INCREMENT 属性，移除该属性后不可恢复   




[AUTO_INCREMENT 使用限制](https://docs.pingcap.com/zh/tidb/stable/auto-increment#%E4%BD%BF%E7%94%A8%E9%99%90%E5%88%B6)  
必须定义在主键或者唯一索引的列上。
只能定义在类型为整数、FLOAT 或 DOUBLE 的列上。
不支持与列的默认值 DEFAULT 同时指定在同一列上。
不支持使用 ALTER TABLE 来添加 AUTO_INCREMENT 属性。
支持使用 ALTER TABLE 来移除 AUTO_INCREMENT 属性。但从 TiDB 2.1.18 和 3.0.4 版本开始，TiDB 通过 session 变量 @@tidb_allow_remove_auto_inc 控制是否允许通过 ALTER TABLE MODIFY 或 ALTER TABLE CHANGE 来移除列的 AUTO_INCREMENT 属性，默认是不允许移除。