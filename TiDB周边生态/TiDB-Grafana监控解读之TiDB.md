# TiDB-Grafana监控解读之TiDB



> - [Query-Summary](#Query-Summary)
> - [Query-Detail](#Query-Detail)
> - [Server](#Server)
> - [Transaction](#Transaction)
> - [Executer](#Executer)
> - [DistSQL](#DistSQL)
> - [KV-Errors](#KV-Errors)
> - [KV-request](#KV-request)
> - [PC-Client](#PC-Client)
> - [Schema-Load](#Schema-Load)
> - [DDL](#DDL)
> - [Statics](#Statics)
> - [Owner](#Owner)
> - [Meta](#Meta)
> - [GC](#GC)
> - [Batch-Client](#Batch-Client)

## Query-Summary

Duration  
涵义: 百分之99.9%、99%、95%、80%的SQL执行时间在纵轴时间以下；  
作用: 

![image.png](http://cdn.lifemini.cn/dbblog/20210115/fa2ebda3f2c44f83a03b8a2e4ec786bb.png)

Statements
涵义: SQL 每秒的select、update、insert、show等不同类型SQL语句的执行数量；  
作用: 判断写多，还是都多，便于处理性能问题  

![image.png](http://cdn.lifemini.cn/dbblog/20210115/16975bf0779742b899a90ef9127208f5.png)

Faild Query OPM  
涵义：不同 TiDB 节点的失败 SQL 的统计，例如语法错误、主键冲突等   
作用：如果出现每秒成败上前的失败 SQL 情况，就有必要追寻一下原因了，看看是否十是预期之内的失败 SQL，以免影响业务。    



## Server

Connection Count  
涵义： 不同的 TiDB 节点当前连接数是多少   
作用：TiDB没有连接数限制，但是会出现排队现象，有利于再次相互排查   

![image.png](http://cdn.lifemini.cn/dbblog/20210115/ad385004e7cd41f78ef3af6d462054c5.png)

## Transaction

## Executer

## DistSQL

## KV-Errors

## KV-request

## PC-Client

## Schema-Load

## DDL

## Statics

## Owner

## Meta

## GC

## Batch-Client







