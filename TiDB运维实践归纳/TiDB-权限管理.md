# TiDB 权限管理




## 权限管理

```
MySQL [jan]> create role reader@'%';
Query OK, 0 rows affected (0.11 sec)

MySQL [jan]> grant select on mysql.role_edges to reader'%';
ERROR 1064 (42000): You have an error in your SQL syntax; check the manual that corresponds to your TiDB version for the right syntax to use line 1 column 45 near "'%'" 
MySQL [jan]> grant select on mysql.role_edges to reader@'%';
Query OK, 0 rows affected (0.33 sec)

MySQL [jan]> create user bi_user@'%';
Query OK, 0 rows affected (0.06 sec)

MySQL [jan]> grant reader to bi_user@'%';
Query OK, 0 rows affected (0.06 sec)

MySQL [jan]> exit
Bye
[tidb@tiup-tidb41 conf]$ mysql -ureader -P4000 -h192.168.169.41
ERROR 1045 (28000): Access denied for user 'reader'@'192.168.169.41' (using password: NO)
[tidb@tiup-tidb41 conf]$ mysql -ureader -P4000 -h192.168.169.41
ERROR 1045 (28000): Access denied for user 'reader'@'192.168.169.41' (using password: NO)
[tidb@tiup-tidb41 conf]$ mysql -ureader -P4000 -h192.168.169.41 -p
Enter password: 
ERROR 1045 (28000): Access denied for user 'reader'@'192.168.169.41' (using password: YES)
[tidb@tiup-tidb41 conf]$ mysql -ureader -P4000 -h192.168.169.41 -p
Enter password: 
ERROR 1045 (28000): Access denied for user 'reader'@'192.168.169.41' (using password: NO)
[tidb@tiup-tidb41 conf]$ mysql -uroot -P4000 -h192.168.169.41
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 23
Server version: 5.7.25-TiDB-v4.0.9 TiDB Server (Apache License 2.0) Community Edition, MySQL 5.7 compatible

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MySQL [(none)]> et password for reader@'%' = password('123123');
ERROR 1064 (42000): You have an error in your SQL syntax; check the manual that corresponds to your TiDB version for the right syntax to use line 1 column 2 near "et password for reader@'%' = password('123123')" 
MySQL [(none)]> set password for reader@'%' = password('123123');
Query OK, 0 rows affected (0.13 sec)

MySQL [(none)]> exit
Bye
[tidb@tiup-tidb41 conf]$ mysql -ureader -P4000 -h192.168.169.41 -p123123
ERROR 1045 (28000): Access denied for user 'reader'@'192.168.169.41' (using password: YES)
[tidb@tiup-tidb41 conf]$ mysql -ureader -P4000 -h192.168.169.41 -p
Enter password: 
ERROR 1045 (28000): Access denied for user 'reader'@'192.168.169.41' (using password: YES)
[tidb@tiup-tidb41 conf]$ mysql -ureader -P4000 -h192.168.169.41
ERROR 1045 (28000): Access denied for user 'reader'@'192.168.169.41' (using password: NO)
[tidb@tiup-tidb41 conf]$ 
[tidb@tiup-tidb41 conf]$ 
[tidb@tiup-tidb41 conf]$ 
[tidb@tiup-tidb41 conf]$ 
[tidb@tiup-tidb41 conf]$ mysql -uroot -P4000 -h192.168.169.41
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 27
Server version: 5.7.25-TiDB-v4.0.9 TiDB Server (Apache License 2.0) Community Edition, MySQL 5.7 compatible

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MySQL [(none)]> set password for bi_user@'%' = password('123123');
Query OK, 0 rows affected (0.05 sec)

MySQL [(none)]> exit
Bye
[tidb@tiup-tidb41 conf]$ mysql -ubi_user -P4000 -h192.168.169.41
ERROR 1045 (28000): Access denied for user 'bi_user'@'192.168.169.41' (using password: NO)
[tidb@tiup-tidb41 conf]$ mysql -ubi_user -P4000 -h192.168.169.41 -p123123
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 29
Server version: 5.7.25-TiDB-v4.0.9 TiDB Server (Apache License 2.0) Community Edition, MySQL 5.7 compatible

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MySQL [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| INFORMATION_SCHEMA |
+--------------------+
1 row in set (0.00 sec)

MySQL [(none)]> SELECT CURRENT_ROLE();
+----------------+
| CURRENT_ROLE() |
+----------------+
|                |
+----------------+
1 row in set (0.00 sec)

MySQL [(none)]> set role reader;
Query OK, 0 rows affected (0.00 sec)

MySQL [(none)]> SELECT CURRENT_ROLE();
+----------------+
| CURRENT_ROLE() |
+----------------+
| `reader`@`%`   |
+----------------+
1 row in set (0.00 sec)

MySQL [(none)]> select * from role_edges;
ERROR 1046 (3D000): No database selected
MySQL [(none)]> select * from mysql.role_edges;
+-----------+-----------+---------+---------+-------------------+
| FROM_HOST | FROM_USER | TO_HOST | TO_USER | WITH_ADMIN_OPTION |
+-----------+-----------+---------+---------+-------------------+
| %         | reader    | %       | bi_user | N                 |
+-----------+-----------+---------+---------+-------------------+
1 row in set (0.01 sec)


MySQL [(none)]> use mysql
Database changed

MySQL [mysql]> exit
Bye
[tidb@tiup-tidb41 conf]$ mysql -ubi_user -P4000 -h192.168.169.41 -p123123
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 30
Server version: 5.7.25-TiDB-v4.0.9 TiDB Server (Apache License 2.0) Community Edition, MySQL 5.7 compatible

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MySQL [(none)]> use mysql
ERROR 1044 (42000): Access denied for user 'bi_user'@'%' to database 'mysql'
MySQL [(none)]> 

MySQL [(none)]> SHOW GRANTS FOR 'bi_user'@'%' USING 'reader';
+---------------------------------------------------+
| Grants for bi_user@%                              |
+---------------------------------------------------+
| GRANT USAGE ON *.* TO 'bi_user'@'%'               |
| GRANT Select ON mysql.role_edges TO 'bi_user'@'%' |
| GRANT 'reader'@'%' TO 'bi_user'@'%'               |
+---------------------------------------------------+
3 rows in set (0.03 sec)


MySQL [(none)]> REVOKE 'reader' FROM 'bi_user'@'%';
Query OK, 0 rows affected (0.06 sec)

MySQL [(none)]> SHOW GRANTS FOR 'bi_user'@'%' USING 'reader';
ERROR 3530 (HY000): `reader`@`%` is is not granted to bi_user@%
MySQL [(none)]> select * from mysql.role_edges;
Empty set (0.01 sec)

```

