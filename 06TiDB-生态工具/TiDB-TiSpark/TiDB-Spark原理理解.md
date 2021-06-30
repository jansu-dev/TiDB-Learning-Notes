# TiDB-Spark原理理解
时间:2021-03-25



一.ThriftServer介绍
ThriftServer是一个JDBC/ODBC接口，用户可以通过JDBC/ODBC连接ThriftServer来访问SparkSQL的数据。ThriftServer在启动的时候，会启动了一个sparkSQL的应用程序，而通过JDBC/ODBC连接进来的客户端共同分享这个sparkSQL应用程序的资源，也就是说不同的用户之间可以共享数据；ThriftServer启动时还开启一个侦听器，等待JDBC客户端的连接和提交查询。所以，在配置ThriftServer的时候，至少要配置ThriftServer的主机名和端口，如果要使用hive数据的话，还要提供hive metastore的uris。

二：spark application运行过程
大体分为三部分：（1）SparkConf创建；（2）SparkContext创建；（3）任务执行。
构建Spark Application的运行环境。创建SparkContext后，SparkContext向资源管理器注册并申请资源。这里说的资源管理器有Standalone、Messos、YARN等。事实上，Spark和资源管理器关系不大，主要是能够获取Executor进程，并能保持相互通信。在SparkContext初始化过程中，Spark分别创建作业调度模块DAGScheduler和任务调度模块TaskScheduler(此例为Standalone模式下，在YARN-Client模式下任务调度模块为YarnClientClusterScheduler,在YARN-Cluster模式下为YarnClusterScheduler)。

三：总结
ThriftServer是一个不同的用户之间可以共享数据，常服务
spark application是每次启动都要申请资源，是例行的


https://blog.csdn.net/qq_43688472/article/details/85337458






# spark-sql    开启日志  

cp conf/log4j.properties.template conf/log4j.properties
vi conf/log4j.properties



# Set everything to be logged to the console
log4j.rootCategory=INFO, console, file

log4j.appender.console=org.apache.log4j.ConsoleAppender
log4j.appender.console.target=System.err
log4j.appender.console.threshold=ERROR
log4j.appender.console.layout=org.apache.log4j.PatternLayout
log4j.appender.console.layout.ConversionPattern=%d{yy/MM/dd HH:mm:ss} %p %c{1}: %m%n

log4j.appender.file=org.apache.log4j.RollingFileAppender
log4j.appender.file.File=/home/mbo/Spark/logging.log
log4j.appender.file.MaxFileSize=5MB
log4j.appender.file.MaxBackupIndex=10
log4j.appender.file.layout=org.apache.log4j.PatternLayout
log4j.appender.file.layout.ConversionPattern=%d{yy/MM/dd HH:mm:ss} %p %c{1}: %m%n

# Settings to quiet third party logs that are too verbose
log4j.logger.org.eclipse.jetty=WARN
log4j.logger.org.eclipse.jetty.util.component.AbstractLifeCycle=ERROR
log4j.logger.org.apache.spark.repl.SparkIMain$exprTyper=INFO
log4j.logger.org.apache.spark.repl.SparkILoop$SparkILoopInterpreter=INFO

https://gist.github.com/mbonaci/e92a2bc690e002f461c1




而Spark每次MapReduce操作是基于线程的，只在启动Executor是启动一次JVM，内存的Task操作是在线程复用的。


考虑一种极端查询：Select month_id,sum(sales) from T group by month_id;
这个查询只有一次shuffle操作，此时，也许Hive HQL的运行时间也许比Spark还快。
结论：Spark快不是绝对的，但是绝大多数，Spark都比Hadoop计算要快。这主要得益于其对mapreduce操作的优化以及对JVM使用的优化。


使用 jstack -l 线程号



