# TiDB-集群部署前环境检测
时间：2021/01/07



使用lsblk命令进行判断，参数-d表示显示设备名称，参数-o表示仅显示特定的列
ROTA是1的表示可以旋转，反之则不能旋转
nvmeSSD一般name以nvme开头



```
[root@tidb04-44 tidb-docker-compose]# lsblk -d -o name,rota
NAME ROTA
sda     1
sr0     1
```

检验网卡带宽
```
[root@tidb04-44 tidb-docker-compose]# ethtool ens33
Settings for ens33:
	Supported ports: [ TP ]
	Supported link modes:   10baseT/Half 10baseT/Full 
	                        100baseT/Half 100baseT/Full 
	                        1000baseT/Full 
	Supported pause frame use: No
	Supports auto-negotiation: Yes
	Supported FEC modes: Not reported
	Advertised link modes:  10baseT/Half 10baseT/Full 
	                        100baseT/Half 100baseT/Full 
	                        1000baseT/Full 
	Advertised pause frame use: No
	Advertised auto-negotiation: Yes
	Advertised FEC modes: Not reported
	Speed: 1000Mb/s
	Duplex: Full
	Port: Twisted Pair
	PHYAD: 0
	Transceiver: internal
	Auto-negotiation: on
	MDI-X: off (auto)
	Supports Wake-on: d
	Wake-on: d
	Current message level: 0x00000007 (7)
			       drv probe link
	Link detected: yes
```