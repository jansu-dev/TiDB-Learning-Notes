# SQL Binding 修正 CBO 优化器不稳定情况
时间:2021-02-06   




```sql

show global binding;

CREATE GLOBAL BINDING FOR SELECT * FROM md_meter_plan_record_info mpri use index (idx_mmpri_mcid)   WHERE mpri.meter_code_id='88aae1be19614cafa3a87dbb01445301'   AND mpri.del_flag=0 AND mpri.meter_read_reason != '09'        AND mpri.city_id=241            AND mpri.city_code=350800           ORDER BY mpri.create_time DESC LIMIT 1;
```










## 参考文章









