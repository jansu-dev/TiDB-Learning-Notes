# OGG数据库系统oracle到TiDB异地灾备方案

## 目录  

> - [概述](#概述)  
>   - [方案背景](#方案背景)  
>   - [需求分析](#需求分析)  
>   - [系统现状](#系统现状)  
>   - [灾备要求](#灾备要求)  
> - [解决方案](#解决方案)  
>   - [方案概述](#方案概述)  
>   - [技术方案](#技术方案)  
>     - [整体架构](#整体架构)  
>     - [环境说明](#环境说明)  
>     - [源端条件检查](#源端条件检查)  
>     - [源端OGG安装](#源端ogg安装)  
>     - [目标端TiDB配置](#目标端TiDB配置)  
>     - [源端对象获取](#源端对象获取)
>     - [目标端对象建立](#目标端对象建立)  
>     - [目标端OGG安装](#目标端OGG安装)  
>     - [配置增量同步](#配置增量同步)
>     - [源端检查归档日志](#源端检查归档日志)
>     - [配置全量同步](#配置全量同步)  
>     - [启动全量同步](#启动全量同步)   
>     - [启动增量同步](#启动增量同步)  
> - [正确性验证](#正确性验证)  


## 概述

### 方案背景

### 需求分析

### 系统现状

### 灾备要求

## 解决方案

### 方案概述

为满足异地灾备中心尽可能少的丢失数据（RPO）并提供快速业务可用的需求（RTO），上海灾备搭建采取实时同步方式，将北京数据中心数据同步到上海数据中心，实时同步采取 OGG 工具进行同步。

### 技术方案

#### 整体架构
源端数据中心 Oracle 通过 OGG 工具实时抽取日志同步到下游 TiDB。

#### 环境说明


| 位置 | 软件	| 版本 | 部署路径 |
| --- | --- | --- | ---|
| 目标端 | TiDB-Cluster | 4.0.8 |  |
| 目标端 | OGG_for_MySQL | 19.1.0.0.3 | /data/ogg_for_mysql |
| 源端 | Oracle | 19.0.0.0 | /home/oracle/ogg_for_oracle |
| 源端 | OGG_for_Oracle | 19.1.0.0.4 |  |

### 前置检查

无主键表梳理
```sql
select owner,table_name
  from DBA_TABLES a
 where not exists (select *
          from DBA_constraints b
         where b.constraint_type = 'P'
           and a.table_name = b.table_name)
   and a.owner in (upper('scott'), upper('scott'));
    -- upper 内填入所需要查询的 schema 名，可填写多个；
```

### 源端条件检查


1. 归档模式确认
```sql
 SQL> archive log list
 Database log mode	       Archive Mode
 Automatic archival      	Enabled
 Archive destination     	USE_DB_RECOVERY_FILE_DEST
 Oldest online log sequence 	6731
 Next log sequence to archive   6742
 Current log sequence  	6742
```
 
2. 回收站关闭
```sql
 SQL> show parameter recyclebin
  
 NAME         	 	TYPE  VALUE
 ------------------------------------ ----------- ------------------------------
 recyclebin       	     string   on
 
 SQL> alter system set recyclebin=off
```
 
3. force logging
```sql
SQL> select force_logging from v$database;
 
FORCE_LOGGING
---------------------------------------
YES
```
 
4. supplemental log
```sql
SQL> select supplemental_log_data_min from v$database;
 
SUPPLEME
--------
YES
```

 
5. 源端字符集查看
```
select (select PROPERTY_VALUE from DATABASE_PROPERTIES where PROPERTY_NAME = 'NLS_LANGUAGE')||'_'||
    	(select PROPERTY_VALUE from DATABASE_PROPERTIES where PROPERTY_NAME = 'NLS_TERRITORY')||'.'||
    	(select PROPERTY_VALUE from DATABASE_PROPERTIES where PROPERTY_NAME = 'NLS_CHARACTERSET') characters
   from dual;
 
CHARACTERS
------------------------------------------------------------
AMERICAN_AMERICA.AL32UTF8
```
 
### 源端OGG安装

1. 上传 19c OGG for oracle on linux安装包



2. 配置响应文件  

```sql
vi /home/oracle/ogg/fbo_ggs_Linux_x64_shiphome/Disk1/response/oggcore.rsp

修改以下配置
INSTALL_OPTION=ORA19c
SOFTWARE_LOCATION=/home/oracle/ogg_for_oracle
```
 
3. 静默安装
```sql
cd /home/oracle/ogg/fbo_ggs_Linux_x64_shiphome/Disk1
./runInstaller -silent -responseFile /home/oracle/ogg/fbo_ggs_Linux_x64_shiphome/Disk1/response/oggcore.rsp
```
 
4. 创建 ogg 目录
```sql
./ggsic
create subdirs
```
 
5. 配置 mgr
```sql
edit param mgr
 
PORT 8809         	
DYNAMICPORTLIST 8810-8889
AUTOSTART ER *
AUTORESTART EXTRACT *,RETRIES 5,WAITMINUTES 3
ACCESSRULE, PROG *, IPADDR *, ALLOW
PURGEOLDEXTRACTS ./dirdat/*,usecheckpoints, minkeepdays 7
--PURGEDDLHISTORY MINKEEPDAYS 3, MAXKEEPDAYS 5, FREQUENCYMINUTES 30
--PURGEMARKERHISTORY MINKEEPDAYS 3, MAXKEEPDAYS 5, FREQUENCYMINUTES 30
LAGREPORTHOURS 1
LAGINFOMINUTES 30
LAGCRITICALMINUTES 45
```
 
6. 生成 defgen 文件 

（1）编辑 defgen 参数文件
```sql
edit param defgen
defsfile /home/oracle/ogg_for_oracle/dirdef/MES.def
userid goldengate, password Go2d_g8t
table MESCARDUSER.MES_CAR_CODE;
table MESCARDUSER.QK_POSITION;
table MESORDERUSER.MES_CLAUSE_BASE_INFO;
table MESORDERUSER.MES_CLAUSE_BASE_INFO_SELECTED;
table MESORDERUSER.MES_ELECTRIC_CODE;
table MESSALESUSER.SALES_APP_CODE;
table MESSALESUSER.SALES_APP_CODE_ELEC;
table MESSALESUSER.SALES_AREA_COMCODE;
table MESSALESUSER.SALES_CHANNEL;
table MESSALESUSER.SALES_COMPANY_COMMISSIONER;
table MESSALESUSER.SALES_IMG_TYPE;
table MESSALESUSER.SALES_IMG_TYPE_ELEC;
table MESSALESUSER.SALES_INTERACTION_COMMISSIONER;
table MESSALESUSER.SALES_MECHANISM_STAFF;
table MESSALESUSER.SALES_SYSTEM_SOURCE;
```
 
（2）生成 defgen 文件

```shell
./defgen paramfile ./dirprm/defgen.prm
```
 
（3）传输 defgen 至 TiDB 端 ogg


7. 添加表级附加日志

```shell
./ggsci
dblogin userid goldengate,password Go2d_g8t
 
add trandata MESORDERUSER.*
add trandata MESCARDUSER.*
add trandata MESCUSTOMERUSER.*
add trandata MESSALESUSER.*
 
sqlplus / as sysdba
Select * from dba_log_groups where owner in ('MESORDERUSER','MESCARDUSER','MESCUSTOMERUSER','MESSALESUSER');
```


### 目标端TiDB配置

1. 配置 TiDB 参数，edit-config 修改并重启 TiDB 生效
```yml
binlog.enable: true
log.level: info
log.slow-threshold: 300
lower-case-table-names: 1
max-index-length: 6144
mem-quota-query: 68719476736
oom-action: cancel
performance.max-procs: 0
performance.max-txn-ttl: 7200000
performance.stats-lease: 3s
performance.stmt-count-limit: 50000
performance.txn-total-size-limit: 2147483648
pessimistic-txn.enable: true
pessimistic-txn.max-retry-count: 256
prepared-plan-cache.capacity: 100
prepared-plan-cache.enabled: false
prepared-plan-cache.memory-guard-ratio: 0.1
token-limit: 3000
```


2. 创建 ogg 同步用户

```sql
create user ogg33 identified by 'ogg';
grant all privileges on *.*  to ' ogg33'@'%' identified by 'ogg';
```


 
3. 配置 tidb_constraint_check_in_place 环境变量

```sql
set global tidb_constraint_check_in_place = 1;
```


#### 源端对象获取
 
1. 源端用户确认

```sql
MESORDERUSER,MESCARDUSER,MESCUSTOMERUSER,MESSALESUSER
SELECT username FROM dba_users where username in ('MESORDERUSER','MESCARDUSER','MESCUSTOMERUSER','MESSALESUSER');
 
USERNAME
--------------------------------------------------------------------------------
MESSALESUSER
MESORDERUSER
MESCUSTOMERUSER
MESCARDUSER
```




2. 对象梳理  

（1）对象整体情况，有 table,index,sequence
```sql
select owner,object_type,count(*) from dba_objects where owner in ('MESORDERUSER','MESCARDUSER','MESCUSTOMERUSER','MESSALESUSER') group by owner,object_type;
MESORDERUSER                     	 INDEX                        	 86
MESCARDUSER                              INDEX                        	 20
MESORDERUSER                     	 SEQUENCE                	  1
MESCUSTOMERUSER           	         TABLE                        	  5
MESCARDUSER                              LOB                     	  7
MESORDERUSER                     	 TABLE                        	 25
MESORDERUSER                     	 LOB                     	 11
MESORDERUSER                     	 TABLE PARTITION         	106
MESCARDUSER                              TABLE                        	  7
MESCUSTOMERUSER           	         INDEX                        	  6
MESORDERUSER                     	 INDEX PARTITION         	156
MESORDERUSER                     	 LOB PARTITION              	 95
MESCARDUSER                              SEQUENCE                	  1
MESSALESUSER                      	 TABLE                        	 15
MESSALESUSER                      	 INDEX                        	 18
```
（2）索引及表数量检查
```sql
col owner for a20
select owner,object_type,count(*) from dba_objects where owner in ('MESORDERUSER','MESCARDUSER','MESCUSTOMERUSER','MESSALESUSER') and object_type in('TABLE','INDEX')  group by owner,object_type order by owner,object_type;
 
OWNER            	OBJECT_TYPE           	COUNT(*)
-------------------- ----------------------- ----------
MESCARDUSER      	INDEX                       	22
MESCARDUSER      	TABLE                        	8
MESCUSTOMERUSER  	INDEX                       	6
MESCUSTOMERUSER  	TABLE                        	5
MESORDERUSER     	INDEX                       	86
MESORDERUSER     	TABLE                       	25
MESSALESUSER     	INDEX                       	18
MESSALESUSER     	TABLE                           15
```
 
（3）表结构获取
① 导出 Oracle 表结构元信息
```sql
expdp \"/ as sysdba\" directory=EXP_DIR dumpfile=metadata.dump logfile=metadata.log schemas=MESCARDUSER,MESORDERUSER,MESCUSTOMERUSER,MESSALESUSER CONTENT=METADATA_ONLY
```
② 搭建测试库 Oracle 并导入 dump 文件
```sql
impdp \"/ as sysdba\" directory=expdp_dir dumpfile=metadata.dump logfile=impdp.log
```
③ 从测试库使用 navicat 导出表定义


同步生产文件

（4）普通索引梳理
```sql
set long 1000000 pagesize 0 linesize 10000
spool create_index.sql;

select
'ALTER TABLE '||'`'||t1.owner||'`.`'||t1.table_name||'` ADD INDEX `'||t1.index_name||'`('||listagg('`'||t2.column_name||'`',',') WITHIN GROUP (ORDER BY t2.COLUMN_POSITION)||');'
from dba_indexes t1, dba_ind_columns t2
where t1.owner in ('MESORDERUSER','MESCARDUSER','MESCUSTOMERUSER','MESSALESUSER')
and t1.index_type ='NORMAL'
and t1.UNIQUENESS='NONUNIQUE'
and t2.table_owner=t1.owner
and t2.index_name=t1.index_name
and (t1.owner,t1.index_name) not in (select owner,index_name from dba_constraints where constraint_type='P')
group by t1.owner,t1.table_name,t1.index_name
union
select
'ALTER TABLE '||'`'||t1.owner||'`.`'||t1.table_name||'` ADD UNIQUE INDEX `'||t1.index_name||'`('||listagg('`'||t2.column_name||'`',',') WITHIN GROUP (ORDER BY t2.COLUMN_POSITION)||');'
from dba_indexes t1, dba_ind_columns t2

```
（5）函数索引梳理
```sql
EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SEGMENT_ATTRIBUTES',false);
select owner,table_name,index_name,dbms_metadata.get_ddl('INDEX',index_name,owner) DDL from dba_indexes where owner in  ('MESORDERUSER','MESCARDUSER','MESCUSTOMERUSER','MESSALESUSER')
and index_type='FUNCTION-BASED NORMAL';
 
CREATE UNIQUEINDEX "MESORDERUSER"."COMCODECLAUSE" ON "ME SORDERUSER"."MES_CLAUSE_BASE_INFO_SELECTED" ("COM_CODE", "PR ODUCT_CODE","CLAUSE_CODE",DECODE(TO_NUMBER("SOURCE_TYPE"),1,"SOURCE_TYPE","SET _MEAL_NO"));
CREATE UNIQUE INDEX "MESORDERUSER"."USERDEFAULTCLAUSE" ON "MESORDERUSER"."MES_CLAUSE_BASE_INFO_SELECTED" ("USER_CODE" , "PRODUCT_CODE", "CLAUSE_CODE", DECODE( TO_NUMBER("USER_DEFA ULT_FLAG"),1,"USER_D EFAULT_FLAG","SET_ME AL_NO"));
```
（5）位图索引梳理
```sql
EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SEGMENT_ATTRIBUTES',false);
select owner,table_name,index_name,dbms_metadata.get_ddl('INDEX',index_name,owner) DDL from dba_indexes where owner in  ('MESORDERUSER','MESCARDUSER','MESCUSTOMERUSER','MESSALESUSER')
and index_type='BITMAP';
```
（6）sequence 定义获取
```sql
select dbms_metadata.get_ddl('SEQUENCE',SEQUENCE_NAME,sequence_owner) from dba_sequences where sequence_owner in ('MESORDERUSER','MESCARDUSER','MESCUSTOMERUSER','MESSALESUSER');
 
CREATE SEQUENCE  `MESCARDUSER`.`SEQ_MES_CAR_CODE_ID`  MINVALUE 1 MAXVALUE 99999999 INCREMENT BY 1 START WITH 1 NOCYCLE;
 
CREATE SEQUENCE  `MESORDERUSER`.`SEQ_MES_ELECTRIC_CODE_ID`  MINVALUE 1 MAXVALUE 99999999 INCREMENT BY 1 START WITH 1  NOCYCLE;
```
（7）comments 定义获取


3. 表对象梳理   

（1）数据量梳理
```sql
select * from (select sum(bytes/1024/1024/1024),owner,segment_name,segment_type from dba_segments where owner in ('MESORDERUSER','MESCARDUSER','MESCUSTOMERUSER','MESSALESUSER') group by owner,segment_name,segment_type order by sum(bytes/1024/1024/1024) desc) where rownum<11;
 
 
SUM(BYTES/1024/1024/1024) OWNER            	SEGMENT_NAME                           	                                                                                      SEGMENT_TYPE
------------------------- -------------------- -------------------------------------------------------------------------------------------------------------------------------- ------------------
           	301.903992 MESORDERUSER     	MES_CLAUSE_INFO                                                                                                                  TABLE PARTITION
           	153.866333 MESCARDUSER      	SYS_LOB0000073399C00002$$                                                                                                        LOBSEGMENT
           	92.6340942 MESORDERUSER     	PK_MES_CLAUSE_INFO12_NEW                    	                                                                                 INDEX
           	80.0906372 MESORDERUSER     	IDX_MES_CLAUSE_INFO__ORDER_NO12                                                                                                  INDEX PARTITION
           	76.2442017 MESORDERUSER     	MES_CLAUSE_INFO11                                                                                                                TABLE PARTITION

```
（2）需要同步数据表梳理
```sql
select owner,segment_name,sum(bytes/1024/1024/1024) from dba_segments where (owner='MESCARDUSER' and segment_name in ('MES_CAR_CODE','QK_POSITION'))
or (owner='MESORDERUSER' and segment_name in ('MES_CLAUSE_BASE_INFO','MES_CLAUSE_BASE_INFO_SELECTED','MES_ELECTRIC_CODE'))
or (owner='MESSALESUSER' and segment_name in ('SALES_APP_CODE','SALES_APP_CODE_ELEC','SALES_AREA_COMCODE','SALES_CHANNEL','SALES_COMPANY_COMMISSIONER',
'SALES_IMG_TYPE','SALES_IMG_TYPE_ELEC','SALES_INTERACTION_COMMISSIONER','SALES_MECHANISM_STAFF','SALES_SYSTEM_SOURCE'))
group by owner,segment_name order by sum(bytes/1024/1024/1024) desc;
 
OWNER            	SEGMENT_NAME                                                                                                                     SUM(BYTES/1024/1024/1024)
-------------------- -------------------------------------------------------------------------------------------------------------------------------- -------------------------
MESORDERUSER     	MES_CLAUSE_BASE_INFO_SELECTED                                                                                                                   .026367188
MESSALESUSER     	SALES_INTERACTION_COMMISSIONER                                                                                                                  .001953125
MESCARDUSER      	MES_CAR_CODE
```
 
### 目标端对象建立
 
1. 建库
```sql
create database MESORDERUSER;
create database MESCARDUSER;
create database MESCUSTOMERUSER;
create database MESSALESUSER;
```
2. 建用户授权
```sql
create user MESCARDUSER@'%' identified by "Mescard!3435Yonghu";
create user MESORDERUSER@'%' identified by "Mesorder!3435Yonghu";
create user MESCUSTOMERUSER@'%' identified by "Mescustomer!3435Yonghu";
create user MESSALESUSER@'%' identified by "Messales!3435Yonghu";
 
grant all on MESCARDUSER.* to MESCARDUSER@'%';
grant all on MESORDERUSER.* to MESORDERUSER@'%';
grant all on MESCUSTOMERUSER.* to MESCUSTOMERUSER@'%';
grant all on MESSALESUSER.* to MESSALESUSER@'%';
```
3. 修改Oracle 整理的表结构脚本，参考以下规则，建议使用 UE 替换  

（1）列映射规则
```sql
number -> decimal
varchar2 -> varchar
clob -> longtext
date -> datetime
number(10,3) -> decimal(10,3)
number(4) -> bigint
decimal（65,30）根据业务需求修改为 bigint
text 需要特殊注意
模糊替换 decimal([0-9], 0) 或者 decimal([0-9][1-9], 0) 为 bigint
```
（2）pk int -> unique key
（3）增加 shard_row_id_bits=4 pre_split_regions=3 打散属性。
（4）全部字符转换为大写。
4. 建立表和相关索引
```sql
use mescarduser;
source mescarduser.sql;
use mesorderuser;
source mesorderuser.sql;
use mescustomeruser;
source mescustomeruser.sql;
use messalesuser;
source messalesuser.sql;
source create_index.txt
```
5. 验证表创建
```sql
select count(distinct table_name) from information_schema.tables where schema = 'MESORDERUSER';
 
select count(distinct table_name) from information_schema.tables where schema = 'MESCARDUSER';
 
select count(distinct table_name) from information_schema.tables where schema = 'MESCUSTOMERUSER';
 
select count(distinct table_name) from information_schema.tables where schema = 'MESSALESUSER';
```
 
6. 建立 sequence
```sql
CREATE SEQUENCE  `MESCARDUSER`.`SEQ_MES_CAR_CODE_ID`  MINVALUE 1 MAXVALUE 99999999 INCREMENT BY 1 START WITH 1 NOCYCLE;
 
CREATE SEQUENCE  `MESORDERUSER`.`SEQ_MES_ELECTRIC_CODE_ID`  MINVALUE 1 MAXVALUE 99999999 INCREMENT BY 1 START WITH 1  NOCYCLE;
```
<span style="color: red">注意：切换时需要在TiDB备库端修改sequence当前值；
SELECT setval(SEQ_MES_CAR_CODE_ID, Oracle );
SELECT setval(SEQ_MES_ELECTRIC_CODE_ID, 10);
<span>



7.同步表大小确认，总共 260MB。

```sql
MESORDERUSER                                                                                                  	 MES_CLAUSE_BASE_INFO_SELECTED                                      	   	   .0234375
MESSALESUSER                                                                                                   	 SALES_INTERACTION_COMMISSIONER                                 	 .001953125
MESCARDUSER                                                                                                    	 MES_CAR_CODE                                                        	 .000366211
MESORDERUSER                                                                                                  	 MES_CLAUSE_BASE_INFO                                                    	 .000183105
MESSALESUSER                                                                                                   	 SALES_MECHANISM_STAFF                                                 	  .00012207
MESSALESUSER                                                                                                   	 SALES_COMPANY_COMMISSIONER                                          	 .000061035
MESSALESUSER                                                                                                   	 SALES_IMG_TYPE                                                    	 .000061035
MESSALESUSER                                                                                                   	 SALES_AREA_COMCODE                                                	 .000061035
MESCARDUSER                                                                                                    	 QK_POSITION                                                      	 .000061035
MESSALESUSER                                                                                                   	 SALES_APP_CODE_ELEC   
```
 
#### 目标端OGG安装
1.创建目录、上传 19c OGG for oracle on linux安装包
```shell
su - tidb
mkdir -p /data/ogg_for_mysql
cd /data/ogg_for_mysql
./ggsci
```
 
2. 配置 mgr
```sql
edit params mgr
 
PORT 7809  	
DYNAMICPORTLIST 7810-7889
AUTOSTART ER *
AUTORESTART EXTRACT *,RETRIES 5,WAITMINUTES 3
ACCESSRULE, PROG *, IPADDR *, ALLOW
PURGEOLDEXTRACTS ./dirdat/*,usecheckpoints, minkeepdays 7
--PURGEDDLHISTORY MINKEEPDAYS 3, MAXKEEPDAYS 5, FREQUENCYMINUTES 30
--PURGEMARKERHISTORY MINKEEPDAYS 3, MAXKEEPDAYS 5, FREQUENCYMINUTES 30
LAGREPORTHOURS 1
LAGINFOMINUTES 30
LAGCRITICALMINUTES 45
```
3. 配置GLOBALS
```sql
edit params ./GLOBALS
checkpointtable ogg.ggs_checkpoint
ALLOWOUTPUTDIR /data/ogg_for_mysql
 
dblogin sourcedb MESCARDUSER@9.23.3.17:4000,userid ogg33,password ogg
 
add checkpointtable ogg33.ggs_checkpoint
```
4. 创建目录
```sql
./ggsic
create subdirs
```
 
#### 配置增量同步
1. 源端配置增量extract

```sql
./ggsci
 
ADD EXTRACT extcx INTEGRATED TRANLOG, BEGIN NOW
add exttrail ./dirdat/cx,extract extcx,MEGABYTES 100
 
register extract extcx database
 
edit params extcx
 
extract extcx
setenv (NLS_LANG=AMERICAN_AMERICA.AL32UTF8)
userid goldengate, password Go2d_g8t
--tranlogoptions excludeuser ogg
--TRANLOGOPTIONS INTEGRATEDPARAMS (max_sga_size 15000, parallelism 6)
exttrail ./dirdat/cx
DISCARDFILE ./dirrpt/cx.dsc,APPEND,MEGABYTES 10
NOCOMPRESSUPDATES
--ThreadOptions MaxCommitPropagationDelay 10000 IOLatency 3000
CACHEMGR CACHESIZE 16G
BR BROFF
```
 
2. 源端配置pump投递进程

```sql
./ggsci
add extract pumpcx ,exttrailsource ./dirdat/cx,begin now
 
add rmttrail /data/ogg_for_mysql/dirdat/rd ,extract pumpcx
 
edit params pumpcx
 
extract pumpcx
setenv (NLS_LANG=AMERICAN_AMERICA.AL32UTF8)
dynamicresolution
passthru
userid goldengate, password Go2d_g8t
rmthost 9.23.3.17,mgrport 7809,TCPBUFSIZE 120000, TCPFLUSHBYTES 120000
rmttrail /data/ogg_for_mysql/dirdat/rd
table MESCARDUSER.MES_CAR_CODE;
table MESCARDUSER.QK_POSITION;
table MESORDERUSER.MES_CLAUSE_BASE_INFO;
table MESORDERUSER.MES_CLAUSE_BASE_INFO_SELECTED;
table MESORDERUSER.MES_ELECTRIC_CODE;
table MESSALESUSER.SALES_APP_CODE;

```
3. TiDB 获取 replicate 端 COLMAP
```sql
MySQL [(none)]> set session group_concat_max_len='4096';
 
MySQL [(none)]> show variables like '%concat%';
+----------------------+-------+
| Variable_name    	| Value |
+----------------------+-------+
| group_concat_max_len | 4096  |
+----------------------+-------+


select table_name,
       concat('MAP ',upper(TABLE_SCHEMA),'.',upper(TABLE_NAME),', TARGET ',upper(TABLE_SCHEMA),'.',upper(TABLE_NAME),',COLMAP ( usedefaults,',
              group_concat(concat(column_name,
                                  '=@IF(@COLTEST(',
                                  column_name,
                                  ',PRESENT),',
                                  column_name,
                                  ',@COLSTAT(MISSING))') separator ','),
              ');')
  from information_schema.columns
 where IS_NULLABLE = 'YES'
   and (table_schema = 'kcwl_aggregate' and table_name in ('app_aggregate_rule', 'app_api_info')) 
   -- fill information of the first schema and tables
   or (table_schema='MESORDERUSER' and table_name in ('MES_CLAUSE_BASE_INFO','MES_CLAUSE_BASE_INFO_SELECTED','MES_ELECTRIC_CODE')) 
   -- fill information of the secondß schema and tables
 group by TABLE_SCHEMA,table_name
 order by table_name;
```
 
### 目标端配置增量replicate  

1.增加增量 replicate 配置
```sql
add replicat repcx ,exttrail /data/ogg_for_mysql/dirdat/rd,checkpointtable ogg33.ggs_checkpoint,begin now
 
edit params repcx
 
replicat repcx
SETENV(NLS_LANG=AMERICAN_AMERICA.ZHS16GBK)
handlecollisions
sourcecharset AL32UTF8
reperror(default,discard)
DISCARDFILE ./dirrpt/repcx.dsc, APPEND, MEGABYTES 100
targetdb ogg@9.23.3.17:4000 userid ogg password ogg
sourcedefs /data/ogg/dirdef/MES.def
MAP MESCARDUSER.MES_CAR_CODE, TARGET MESCARDUSER.MES_CAR_CODE,COLMAP ( usedefaults,PARENT_KIND=@IF(@COLTEST(PARENT_KIND,PRESENT),PARENT_KIND,@COLSTAT(MISSING)),NAME=@IF(@COLTEST(NAME,PRESENT),NAME,@COLSTAT(MISSING)),TYPE=@IF(@COLTEST(TYPE,PRESENT),TYPE,@COLSTAT(MISSING)),LEVELS=@IF(@COLTEST(LEVELS,PRESENT),LEVELS,@COLSTAT(MISSING))); 
```
 
### 源端检查归档日志  

确保增量抽取进程的时间点，所在区间的归档日志没有被删除；
```sql
select * from (select FIRST_TIME,DELETED from v$archived_log
where first_time>=to_date('2021-03-17 18:00:00','yyyy-mm-dd hh24:mi:ss') order by first_time asc) where rownum<10;
 
strings archived.log|less  第一行数就是scn，如34607271
 
select to_char(scn_to_timestamp(34607271), 'yyyy-mm-dd hh24:mi:ss')  from dual;
```
 
### 配置全量同步

1.源端增加全量抽取 extract 进程
```sql
add extract initext,sourceistable
 
edit params initext
 
extract initext
userid goldengate, password Go2d_g8t
rmthost 9.23.3.17, mgrport 8809
rmttask replicat,group initrep
table MESCARDUSER.MES_CAR_CODE;
table MESCARDUSER.QK_POSITION;
table MESORDERUSER.MES_CLAUSE_BASE_INFO;
table MESORDERUSER.MES_CLAUSE_BASE_INFO_SELECTED;
table MESORDERUSER.MES_ELECTRIC_CODE;
table MESSALESUSER.SALES_APP_CODE;
table MESSALESUSER.SALES_APP_CODE_ELEC;
table MESSALESUSER.SALES_AREA_COMCODE;
table MESSALESUSER.SALES_CHANNEL;
table MESSALESUSER.SALES_COMPANY_COMMISSIONER;
table MESSALESUSER.SALES_IMG_TYPE;
table MESSALESUSER.SALES_IMG_TYPE_ELEC;

```
2.目标端增加全量复制 replicate进程
```sql
add replicat initrep,specialrun
 
edit params initrep
 
replicat initrep
SETENV(NLS_LANG=SIMPLIFIED CHINESE_CHINA.ZHS16GBK)
handlecollisions
reperror(default,discard)
SOURCECHARSET AL32UTF8
DISCARDFILE ./dirrpt/repint.dsc, APPEND, MEGABYTES 100
targetdb ogg33@9.23.3.17:4000 userid ogg33 password ogg
sourcedefs /mdata/ogg_for_mysql/dirdef/MES.def
MAP MESCARDUSER.MES_CAR_CODE, TARGET MESCARDUSER.MES_CAR_CODE,COLMAP ( usedefaults,PARENT_KIND=@IF(@COLTEST(PARENT_KIND,PRESENT),PARENT_KIND,@COLSTAT(MISSING)),NAME=@IF(@COLTEST(NAME,PRESENT),NAME,@COLSTAT(MISSING)),TYPE=@IF(@COLTEST(TYPE,PRESENT),TYPE,@COLSTAT(MISSING)),LEVELS=@IF(@COLTEST(LEVELS,PRESENT),LEVELS,@COLSTAT(MISSING)));
```
 
#### 启动全量同步
1. 源端启动 extinit
```sql
./ggsci
start initext
stats initext
 
info initext
EXTRACT	INITEXT   Last Started 2020-12-17 19:18   Status STOPPED
......
......
```

2. 观察至全量结束
```sql
./ggsci
Info initext
 
Info initrep
```


#### 启动增量同步

1. 确定全量同步起始点
```sql
info initext
 
EXTRACT	INITEXT   Last Started 2020-12-17 19:18   Status STOPPED
Checkpoint Lag   	Not Available
Log Read Checkpoint  Table XXX
                 	2020-12-18 00:18:04  Record 174812
Task             	SOURCEISTABLE
```
2. 修改源端目标端增量进程开始时间
```sql
ALTER EXTRACT extcx  ,begin 2021-03-17 22:00:00
ALTER EXTRACT pumpcx ,begin 2021-03-17 22:00:00
ALTER replicat repcx ,begin 2021-03-18 01:20:00
```
 

3. 源端启动 extract 和 pump 进程

```sql
start extcx
start pumpcx
```
 
4. 目标端启动 replicate 应用进程

```sql
start repcx
```
 

5. 检查同步进度和状态
```sql
stats repcx
info repcx
```
 
## 正确性验证   



1. 数据库验证


 - 索引验证
```sql
Select table_schema,table_name,KEY_NAME from information_schema.TiDB_INDEXES  where  table_name in ('MES_CAR_CODE','QK_POSITION','MES_CLAUSE_BASE_INFO',   'MES_CLAUSE_BASE_INFO_SELECTED','MES_ELECTRIC_CODE','SALES_APP_CODE',   'SALES_APP_CODE_ELEC','SALES_AREA_COMCODE','SALES_CHANNEL',   'SALES_COMPANY_COMMISSIONER','SALES_IMG_TYPE','SALES_IMG_TYPE_ELEC',   'SALES_INTERACTION_COMMISSIONER','SALES_MECHANISM_STAFF','SALES_SYSTEM_SOURCE')  group by table_schema,table_name,KEY_NAME;
```
 
 - 数据量验证
```sql
 # 源端 目标端 分别验证
 select count(*) from MESCARDUSER.MES_CAR_CODE;
 select count(*) from MESORDERUSER.MES_CLAUSE_BASE_INFO;
 select count(*) from MESORDERUSER.MES_CLAUSE_BASE_INFO_SELECTED;
 select count(*) from MESORDERUSER.MES_ELECTRIC_CODE;
 select count(*) from MESCARDUSER.QK_POSITION;
 select count(*) from MESSALESUSER.SALES_APP_CODE;
 select count(*) from MESSALESUSER.SALES_APP_CODE_ELEC;
 select count(*) from MESSALESUSER.SALES_AREA_COMCODE;
 select count(*) from MESSALESUSER.SALES_CHANNEL;
 select count(*) from MESSALESUSER.SALES_COMPANY_COMMISSIONER;
 select count(*) from MESSALESUSER.SALES_IMG_TYPE;
 select count(*) from MESSALESUSER.SALES_IMG_TYPE_ELEC;
 select count(*) from MESSALESUSER.SALES_INTERACTION_COMMISSIONER;
 select count(*) from MESSALESUSER.SALES_MECHANISM_STAFF;
 select count(*) from MESSALESUSER.SALES_SYSTEM_SOURCE;
```

2. OGG验证
 - ogg进程验证
```sql
./ggsci
info all
```

 - 查看日志
```shell
  tail -100f ggserr.log
```

3. 业务验证流程架构

 - 业务验证内容

 





