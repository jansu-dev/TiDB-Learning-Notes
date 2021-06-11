
# TiDB挂掉没有报警原因

        TIDB 的报警功能使用 Prometheus 和 Alertmanager 实现，具体机制为 Prometheus 服务器收集 TIDB 的状态信息，基于警报规则生成警报，并将警报发送到Alertmanager，
由 Alertmanager 将报警信息推送至邮件服务器。

        首先，Prometheus 用每 15 秒采样一次方式记录数据，而 TiDB_monitor_keep_alive 该指标表达式（ increase(tidb_monitor_keep_alive_total[10m]) < 100）的意思是汇总 10 分钟内（40次）对应 metrics 的增长情况，如果小于 100 则判定为 TiDB 经历过重启。
        图 2 为多次 kill tidb 进程测试结果，每次曲线的下降为一次 TiDB 杀进程操作，测试结果可知，只有在多次 kill TiDB 进程的情况下才会激发 TiDB_monitor_keep_alive 报警项。


图1

图2
因此，可能由于 TiDB 实例重启分快，在 prometheus 采样期间（6s）便完成了重启，出现无法检测到 OOM 的现象。

图3

        官网参考：https://docs.pingcap.com/tidb/v4.0/alert-rules#tidb_monitor_keep_alive

        其次，Prometheus 并不是每次采集到报警信息便会发送给 Alertmanager，在配置规则中 TiDB 默认将 TiDB_monitor_keep_alive 配置为持续观察 1min ，如果 1min 后该值仍然小于 100 ，则推送报警信息至 Altermanager ，最后到达邮件服务器。


        官网参考：https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/


3.2监控项修改建议

