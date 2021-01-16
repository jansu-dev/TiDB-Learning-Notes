# TiDB-权限管理

> - [基于角色控制RBAC的权限管理](#基于角色控制RBAC的权限管理)
> - [创建角色和用户](#创建角色和用户)
> - [验证并使用角色权限](#验证并使用角色权限)
> - [用户查看角色拥有权限](#用户查看角色拥有权限)
> - [用户回收自身角色](#用户回收自身角色)

## 基于角色控制RBAC的权限管理

#### 创建角色和用户
 - 赋予 bi_user 用户 reader 角色，拥有 reader 角色所拥有的权限
```shell
# 创建 reader@'%' 角色
MySQL [jan]> create role reader@'%';

# 授权 reader@'%' 角色对 mysql.role_edges 表的读取权限
MySQL [jan]> grant select on mysql.role_edges to reader@'%';

# 创建 bi_user@'%' 用户
MySQL [jan]> create user bi_user@'%';

# 授予 bi_user@'%' 用户 reader 角色
MySQL [jan]> grant reader to bi_user@'%';


MySQL [jan]> exit
```

#### 验证并使用角色权限

 - 使用 bi_user 用户验证相关权限

```shell
# bi_user 用户登陆数据库
[tidb@tiup-tidb41 conf]$ mysql -ubi_user -P4000 -h192.168.169.41 -p123123

# bi_user 没有任何其他多余权限
MySQL [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| INFORMATION_SCHEMA |
+--------------------+

# 查看当前角色
MySQL [(none)]> SELECT CURRENT_ROLE();
+----------------+
| CURRENT_ROLE() |
+----------------+
|                |
+----------------+

# 查询 mysql.role_edges 会失败
MySQL [(none)]> select * from mysql.role_edges;

# 改变当前角色为 reader
MySQL [(none)]> set role reader;

# 查看当前角色
MySQL [(none)]> SELECT CURRENT_ROLE();
+----------------+
| CURRENT_ROLE() |
+----------------+
| `reader`@`%`   |
+----------------+

# 成功查询 mysql.role_edges
MySQL [(none)]> select * frommysql.role_edges;
+-----------+-----------+---------+---------+-------------------+
| FROM_HOST | FROM_USER | TO_HOST | TO_USER | WITH_ADMIN_OPTION |
+-----------+-----------+---------+---------+-------------------+
| %         | reader    | %       | bi_user | N                 |
+-----------+-----------+---------+---------+-------------------+
```

#### 用户查看角色拥有权限
 - bi_user 查看角色拥有权限
```
[tidb@tiup-tidb41 conf]$ mysql -ubi_user -P4000 -h192.168.169.41 -p123123

MySQL [(none)]> use mysql
ERROR 1044 (42000): Access denied for user 'bi_user'@'%' to database 'mysql'


MySQL [(none)]> SHOW GRANTS FOR 'bi_user'@'%' USING 'reader';
+---------------------------------------------------+
| Grants for bi_user@%                              |
+---------------------------------------------------+
| GRANT USAGE ON *.* TO 'bi_user'@'%'               |
| GRANT Select ON mysql.role_edges TO 'bi_user'@'%' |
| GRANT 'reader'@'%' TO 'bi_user'@'%'               |
+---------------------------------------------------+
3 rows in set (0.03 sec)
```

#### 用户回收自身角色
 - bi_user 用户收回 reader 角色

```shell
# bi_user 用户自己收回自身的角色
MySQL [(none)]> REVOKE 'reader' FROM 'bi_user'@'%';
Query OK, 0 rows affected (0.06 sec)

# 收回角色之后，不在具有角色权限
MySQL [(none)]> SHOW GRANTS FOR 'bi_user'@'%' USING 'reader';
ERROR 3530 (HY000): `reader`@`%` is is not granted to bi_user@%

# 收回权限后，还是拥有用户自身拥有的权限
MySQL [(none)]> select * from mysql.role_edges;
Empty set (0.01 sec)
```

