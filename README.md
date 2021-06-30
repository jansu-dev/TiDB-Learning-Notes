# TiDB-Learning-Notes

![image.png](http://cdn.lifemini.cn/dbblog/20210123/5dae983117ea487aafc60162651b254d.png)

That the repository was build is aim to log process of mysql TiDB Learning.

<!-- TOC -->

- [TiDB-Learning-Notes](#tidb-learning-notes)
    - [01 TiDB-原理总结](#01-tidb-原理总结)
        - [1-1 论文阅读](#1-1-论文阅读)
        - [1-2 特性摘要](#1-2-特性摘要)
        - [1-3 组件原理](#1-3-组件原理)
        - [1-4 存储引擎](#1-4-存储引擎)
    - [02 TiDB-部署实践](#02-tidb-部署实践)
        - [2-1 软硬件环境监测](#2-1-软硬件环境监测)
        - [2-2 Ansible部署实践](#2-2-ansible部署实践)
        - [2-3 TiUP部署实践](#2-3-tiup部署实践)
    - [03 TiDB-运维管理](#03-tidb-运维管理)
        - [3-1 基础运维管理](#3-1-基础运维管理)
        - [3-2 常规备份恢复](#3-2-常规备份恢复)
        - [3-3 非常规恢复](#3-3-非常规恢复)
    - [04 TiDB-版本特性](#04-tidb-版本特性)
    - [05 TiDB-调优实践](#05-tidb-调优实践)
        - [5-1 SQL调优](#5-1-sql调优)
        - [5-2 常见错误](#5-2-常见错误)
        - [5-3 监控信息](#5-3-监控信息)
        - [5-4 生产案例](#5-4-生产案例)
    - [06 TiDB-生态工具](#06-tidb-生态工具)
        - [6-1 TiDB-Binlog](#6-1-tidb-binlog)
        - [6-2 TiDB-DM](#6-2-tidb-dm)
        - [6-3 TiDB-Dumpling](#6-3-tidb-dumpling)
        - [6-4 TiDB-Lightning](#6-4-tidb-lightning)
        - [6-5 TiSpark](#6-5-tispark)
    - [07 TiDB-解决方案](#07-tidb-解决方案)
        - [7-1 TiDB-Binlog读写分离方案](#7-1-tidb-binlog读写分离方案)
        - [7-2 两地三中心高可用方案](#7-2-两地三中心高可用方案)
        - [7-3 迁移MyCat至TiDB方案](#7-3-迁移mycat至tidb方案)
        - [7-4 迁移Oracle至TiDB方案](#7-4-迁移oracle至tidb方案)
        - [7-5 Oracle 下迁 TiDB 或 MySQL 工具](#7-5-oracle-下迁-tidb-或-mysql-工具)
    - [08 TiDB-源码阅读](#08-tidb-源码阅读)

<!-- /TOC -->



## 01 TiDB-原理总结

### 1-1 论文阅读

[Paper Percolator 学习笔记](./01TiDB-原理总结/1-1论文阅读/PaperPercolator学习笔记.md)    
[Paper Spanner 学习笔记](./01TiDB-原理总结/1-1论文阅读/PaperSpanner学习笔记.md)    
[Paper Isolation Levels 学习笔记](./01TiDB-原理总结/1-1论文阅读/PaperIsolationLevels学习笔记.md)  
[Paper Raft 学习笔记](./01TiDB-原理总结/1-1论文阅读/PaperRaft学习笔记.md)  
[Paper LSM Tree 学习笔记](./01TiDB-原理总结/1-1论文阅读/PaperLSMTree学习笔记.md)

### 1-2 特性摘要

[TiDB存储引擎下MPP优劣](./01TiDB-原理总结/1-2特性摘要/TiDB存储引擎下MPP优劣.md)   
[TiDB存储模型的实现](01TiDB-原理总结/1-2特性摘要/TiDB存储模型的实现.md)  
[TiDB悲观锁实现原理](01TiDB-原理总结/1-2特性摘要/TiDB悲观锁实现原理.md)  
[TiKVRegion实现原理](01TiDB-原理总结/1-2特性摘要/TiKVRegion实现原理.md)  


### 1-3 组件原理
[Component-Etcd原理与使用](./01TiDB-原理总结/1-3组件原理/Component-Etcd原理与使用.md)  
[gRPC协议原理](./01TiDB-原理总结/1-3组件原理/gRPC协议原理.md)  

### 1-4 存储引擎


## 02 TiDB-部署实践

### 2-1 软硬件环境监测
[TiDB 集群部署前环境检测](./02TIDB-部署实践/2-1软硬件环境检测/TiDB-集群部署前环境检测.md)

### 2-2 Ansible部署实践

[Ansible 工具介绍与 TiDB 集群部署](./02TIDB-部署实践/2-1Ansible部署实践/TiDB-Ansible部署工具简介与TiDB集群部署.md)  
[Ansible TiDB 集群扩缩容及注意事项](./02TIDB-部署实践/2-1Ansible部署实践/TiDB-Ansible部署工具简介与TiDB集群部署.md)   
 

### 2-3 TiUP部署实践  

[Tiup 工具原理与目录结构解析](./02TIDB-部署实践/2-1Ansible部署实践/TiDB-Ansible部署工具简介与TiDB集群部署.md)   
[Tiup 工具扩缩容及升级操作流程与注意事项](./02TIDB-部署实践/2-1Ansible部署实践/TiDB-Ansible部署工具简介与TiDB集群部署.md)  

## 03 TiDB-运维管理

### 3-1 基础运维管理

[TiDB TLS 加密传输安全协议原理与应用](./03TiDB-运维管理/3-1基础运维管理/TiDB-TLS加密传输安全协议原理与应用.md)    
[TiDB 基于 RBAC 的权限管理](./03TiDB-运维管理/3-1基础运维管理/TiDB-基于RBAC的权限管理.md)  
[TiDB 字符集相关信息摘要](./03TiDB-运维管理/3-1基础运维管理/TiDB-基于RBAC的权限管理.md)  

### 3-2 常规备份恢复

### 3-3 非常规恢复

## 04 TiDB-版本特性 

[TiDB v4.0.0 大事务处理机制改变原理]()   
[TiDB v5.0.0 新特性 MPP 原理与使用]()   
[TiDB v5.0.0 新特性 LOCAL TSO 原理与使用]()   

## 05 TiDB-调优实践

[TiDB v4.0.0 大事务处理机制改变原理]()   
[TiDB v5.0.0 新特性 MPP 原理与使用]()   
[TiDB v5.0.0 新特性 LOCAL TSO 原理与使用]()   


### 5-1 SQL调优

### 5-2 常见错误

### 5-3 监控信息

### 5-4 生产案例  
[SQLBinding修正优化器不稳定问题](./05TiDB-调优实践/TiDB-生产案例/CASE-SQLBinding修正优化器不稳定问题.md)  
[导入100万左右数据中断问题](05TiDB-调优实践/TiDB-生产案例/CASE-导入100万左右数据中断问题.md)  
[TiDB 热点问题识别与解决方案](./05TiDB-调优实践/TiDB-生产案例/CASE-热点问题识别与解决方案.md)  
[磁盘抖动导致 Duration 抖动现象问题](./05TiDB-调优实践/TiDB-生产案例/CASE-磁盘抖动导致Duration抖动现象问题.md)  
[网卡带宽打满导致 Duration 升高问题](./05TiDB-调优实践/TiDB-生产案例/CASE-网卡带宽打满导致Duration升高问题.md)  
[非SSD磁盘性能引发 txnLockNotFound 问题](./05TiDB-调优实践/TiDB-生产案例/CASE-非SSD磁盘性能引发txnLockNotFound问题.md)

## 06 TiDB-生态工具



### 6-1 TiDB-Binlog

### 6-2 TiDB-DM

### 6-3 TiDB-Dumpling

### 6-4 TiDB-Lightning

### 6-5 TiSpark

## 07 TiDB-解决方案

### 7-1 TiDB-Binlog读写分离方案

[TiDB Binlog 潜在风险](./07TiDB-解决方案/TiDB-Binlog读写分离方案/binlog潜在风险.md)

### 7-2 两地三中心高可用方案

[TiDB 容灾部署知识点归纳](./07TiDB-解决方案/两地三中心高可用方案/TiDB-容灾部署知识点归纳.md)

### 7-3 迁移MyCat至TiDB方案

[某 OLAP 为主 OLTP 为辅的 MyCAT 系统下迁 TiDB](./07TiDB-解决方案/迁移MyCat至TiDB方案/某系统OLAP为主OLTP为辅系统下迁TiDB.md)   

### 7-4 迁移Oracle至TiDB方案

[Oracle 到 TiDB 的 OGG 部署方案](./07TiDB-解决方案/迁移Oracle至TiDB方案/Oracle到TiDB的OGG部署方案.md)

### 7-5 Oracle 下迁 TiDB 或 MySQL 工具

[KWC](https://github.com/jansu-dev/kwc)  
[Kettle](https://github.com/jansu-dev/kwc)  
[Oracle GoldenGate](https://github.com/jansu-dev/kwc)  

## 08 TiDB-源码阅读

