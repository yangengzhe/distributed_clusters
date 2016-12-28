# MySQL Cluster

> MySQL Cluster 是MySQL 适合于分布式计算环境的高实用、可拓展、高性能、高冗余版本，其研发设计的初衷就是要满足许多行业里的最严酷应用要求，这些应用中经常要求数据库运行的可靠性要达到99.999%。

MySQL Cluster的特点是在内存中部署服务器的集群，这样的好处是可以免去读写磁盘IO，提高速度。同时也能够使用多种故障切换和负载平衡选项配置NDB存储引擎。

## 三类节点介绍

### 管理节点

用于调度、管理整个数据库集群，一般又一台服务器构成。

### 数据节点

MySQL Cluster的核心，用于存储整个数据内容，日志等。但是由于数据节点间是复制关系，所以当数据节点增加时，集群的处理速度会变慢。

### SQL节点（对外入口）

对外部程序呈现出来的数据服务。实际是按照一定算法调用不同数据节点的数据，可以认为是数据和应用直接的桥梁。增加SQL节点可以提高集群的并发速度和整体的吞吐量。

## NDB引擎介绍

MySQL Cluster使用的是一个专门的内存存储引擎，叫做NDB引擎。利用内存引擎的好处是免去了磁盘IO，提高了数据的读写速度，但是缺陷就是受内存大小的制约，要划分足够大的内存才可以正常工作。

NDB引擎是一个分布式的，可以部署在多态服务器上，实现数据的可靠性和扩展性。*理论上2台NDB的数据节点就可以实现整个数据库集群的冗余性和解决单点故障问题。*

缺点：

1. 受到内存的大小限制，存储大量数据的代价较高
2. 由于存于内存，突然断电可能会导致数据丢失
3. 多节点复制，通过网络广播每一个操作，所以受网络制约很大

优点：

1. 分布式解决方案
2. 扩展性好，可以随时增加集群
3. 冗余性好，每个数据节点的数据都一样，可以进行备份

## 搭建2节点Mysql集群

### 准备工作

本例主要用到2台服务器来搭建mysql集群：

	管理节点 172.29.131.136

	数据节点A 172.29.131.136
	数据节点B 172.29.131.137

	SQL节点A 172.29.131.136
	SQL节点B 172.29.131.137

下载Mysql Cluster

	http://www.mysql.com/downloads/cluster/

(本文采用Ubuntu系统)

### 安装工作

主要分为自动安装和手动安装两部分。

mysql-cluster的自动安装程序十分方便，简单。但是为了配置的更灵活，笔者更倾向于手动配置。

#### 安装目录：/usr/local/bin

	tar -xzvf mysql-cluster-gpl-7.2.4-linux2.6-x86_64.tar.gz
	mv mysql-cluster-gpl-7.2.4-linux2.6-x86_64 /usr/local/bin
	cd /usr/local/bin
	mv mysql-cluster-gpl-7.2.4-linux2.6-x86_64 mysql

### 开启自动部署系统

	bin/ndb_setup.py

注意：打开自动部署系统是在页面上进行部署，如果对于非桌面系统来说，还需要设置两个参数，在远程打开安装页面`bin/ndb_setup.py  -N 192.168.1.8  -p 8081` （如果有防火墙要开启防火墙）

之后打开网页：`http://192.168.1.8:8081/welcome.html`进行配置

1、选择`Create New MySQL Cluster`进行新安装

2、正常填写名称、IP地址等信息，这里需要注意下：

Host list: 	全部mysql节点的IP

Application area ：

- simple testing：只分配很少的内存，因此只能存一点点数据
- Web application：会尽量多分配内存。（具体多少根据下面几页配置决定）
- realtime：在Web application的基础上，缩短心跳的间隔，能更快的发现机器故障。

Write load：（写吞吐率）

- low：<100/s
- medium：100-1000/s
- high：>1000/s

因此一般情况下选择Web application 和medium即可

**SSH property**

用于在多台机器的远程部署时使用，如果像hadoop一样 有免密登陆就不用设置了。否则需要设置下ssh（如果本机部署可以不设置）

本例是在本机部署，所以不用设置了

3、内存配置默认为本机大小。但是若全部分配，可能会导致本机内存不足启动失败。但是如果太少（低于1.8G）可能会存不了什么数据导致报错。

因此建议微微调低点内存

	安装地址：/usr/local/bin/mysql/
	数据地址：/home/yangengzhe/MySQL_Cluster/

4、配置节点

默认情况下会配置1个管理节点，2个数据节点，2个MySQL节点，另外还有3个API节点（直接用Ndb API连接及ndb工具运行时使用）

本例中配置成：1个管理节点 1个数据节点 1个Mysql节点，1个API节点

5、配置节点信息

主要是配置端口和路径等。除非是占用了端口，否则不用修改。（管理节点的默认端口号是1186，SQL节点使用了3306）

	管理路径：/home/yangengzhe/MySQL_Cluster/49/
	数据路径：/home/yangengzhe/MySQL_Cluster/1/
	SQL路径：/home/yangengzhe/MySQL_Cluster/53/
		-端口3306
		-Socket/home/yangengzhe/MySQL_Cluster/53/mysql.socket

6、部署启动

点击“deploy and start cluster” 等待绿色进度条完成即可

### 手动配置

### 配置前工作

1、关闭防火墙、或者允许端口1186 2202 3306等（后期设置中用到的端口）

2、解压到目录`/usr/local/mysql`

3、创建用到的目录

	数据节点A 172.29.131.136
		- 管理节点 /usr/local/mysql-gdms/mysqlmgm
			- 运行目录和文件目录 /usr/local/mysql-gdms/mysqlmgm/bin/config
			- 数据目录 /usr/local/mysql-gdms/mysqlmgm/mgmdata
		- 数据节点 /usr/local/mysql-gdms/mysqldata
			- 运行目录 /usr/local/mysql-gdms/mysqldata/bin/
			- DataDir=/usr/local/mysql-gdms/mysqldata/data1
			- BackupDataDir=/usr/local/mysql-gdms/mysqldata/backup1
		- SQL节点 /usr/local/mysql-gdms/mysqlapp
			- 数据 /usr/local/mysql-gdms/mysqlapp/data
			- 日志 /usr/local/mysql-gdms/mysqlapp/log
			- Socket /usr/local/mysql-gdms/mysqlapp/socket
			- /usr/local/mysql-gdms/mysqlapp/tmp
	数据节点B 172.29.131.137
		- 数据节点 /usr/local/mysql-gdms/mysqldata
			- 运行目录 /usr/local/mysql-gdms/mysqldata/bin/
			- DataDir=/usr/local/mysql-gdms/mysqldata/data2
			- BackupDataDir=/usr/local/mysql-gdms/mysqldata/backup2
		- SQL节点 /usr/local/mysql-gdms/mysqlapp
			- 数据 /usr/local/mysql-gdms/mysqlapp/data
			- 日志 /usr/local/mysql-gdms/mysqlapp/log
			- Socket /usr/local/mysql-gdms/mysqlapp/socket
			- /usr/local/mysql-gdms/mysqlapp/tmp
		
4、配置文件（只有管理节点需要）

这里需要一个配置文件 config.ini （可以利用自动部署系统来生成配置文件，也可以按照下方修改）

	#
	# Configuration file for Mysql-Dbs
	#

	[NDB_MGMD DEFAULT]
	Portnumber=1186

	[NDB_MGMD]
	NodeId=49
	HostName=172.29.131.136
	DataDir=/usr/local/mysql-gdms/mysqlmgm/mgmdata
	Portnumber=1186

	[TCP DEFAULT]
	SendBufferMemory=4M
	ReceiveBufferMemory=4M

	[NDBD DEFAULT]
	BackupMaxWriteSize=1M
	BackupDataBufferSize=16M
	BackupLogBufferSize=4M
	BackupMemory=20M
	BackupReportFrequency=10
	MemReportFrequency=30
	LogLevelStartup=15
	LogLevelShutdown=15
	LogLevelCheckpoint=8
	LogLevelNodeRestart=15
	DataMemory=4075M
	IndexMemory=727M
	MaxNoOfTables=4096
	MaxNoOfTriggers=3500
	NoOfReplicas=1
	StringMemory=25
	DiskPageBufferMemory=64M
	SharedGlobalMemory=20M
	LongMessageBuffer=32M
	MaxNoOfConcurrentTransactions=16384
	BatchSizePerLocalScan=512
	FragmentLogFileSize=256M
	NoOfFragmentLogFiles=23
	RedoBuffer=32M
	MaxNoOfExecutionThreads=4
	StopOnError=false
	LockPagesInMainMemory=1
	TimeBetweenEpochsTimeout=32000
	TimeBetweenWatchdogCheckInitial=60000
	TransactionInactiveTimeout=60000
	HeartbeatIntervalDbDb=15000
	HeartbeatIntervalDbApi=15000

	[NDBD]
	NodeId=1
	HostName=172.29.131.136
	DataDir=/usr/local/mysql-gdms/mysqldata/data1
	BackupDataDir=/usr/local/mysql-gdms/mysqldata/backup1

	[NDBD]
	NodeId=2
	HostName=172.29.131.137
	DataDir=/usr/local/mysql-gdms/mysqldata/data2
	BackupDataDir=/usr/local/mysql-gdms/mysqldata/backup2

	[MYSQLD DEFAULT]

	[MYSQLD]
	NodeId=53
	HostName=172.29.131.136

	[MYSQLD]
	NodeId=54
	HostName=172.29.131.137

	[API]
	NodeId=50
	HostName=172.29.131.136

	[API]
	NodeId=51
	HostName=172.29.131.137

### 配置管理节点

在172.29.131.136配置

	#创建管理节点运行目录和配置完成后的生成文件目录
	mkdir -p /usr/local/mysql-gdms/mysqlmgm/bin/config
	#创建管理节点数据目录
	mkdir -p /usr/local/mysql-gdms/mysqlmgm/mgmdata
	#进入管理节点目录
	cd /usr/local/mysql-gdms/mysqlmgm
	#拷贝管理节点的必要文件到运行目录
	cp /usr/local/mysql/bin/ndb_mgmd /usr/local/mysql-gdms/mysqlmgm/bin/
	cp /usr/local/mysql/bin/ndb_mgm  /usr/local/mysql-gdms/mysqlmgm/bin/
	#拷贝参数配置文件到管理节点运行目录
	cp ~/config.ini /usr/local/mysql-gdms/mysqlmgm/bin/config.ini
	#把管理节点的运行目录加入环境变量
	vim ~/.bash_profile
	#在PATH变量后面增加":/usr/local/mysql-gdms/mysqlmgm/bin",如下形式：
	PATH=$PATH:$HOME/bin:/usr/local/mysql-gdms/mysqlmgm/bin
	#退出VIM，使用命令，让环境变量立即生效
	source ~/.bash_profile

### 配置数据节点

分别在172.29.131.136和172.29.131.137配置

	#172.29.131.136上创建数据节点所需目录
	mkdir -p /usr/local/mysql-gdms/mysqldata/bin/
	mkdir /usr/local/mysql-gdms/mysqldata/data1
	mkdir /usr/local/mysql-gdms/mysqldata/backup1
	
	#172.29.131.137上创建数据节点所需目录
	mkdir -p /usr/local/mysql-gdms/mysqldata/bin/
	mkdir /usr/local/mysql-gdms/mysqldata/data2
	mkdir /usr/local/mysql-gdms/mysqldata/backup2
	
	#两台机器上都做以下操作
	#进入数据节点的运行目录
	cd /usr/local/mysql-gdms/mysqldata
	#拷贝必要的程序到运行目录
	cp /usr/local/mysql/bin/ndbd    /usr/local/mysql-gdms/mysqldata/bin/
	cp /usr/local/mysql/bin/ndbmtd  /usr/local/mysql-gdms/mysqldata/bin/

`/usr/local/mysql-gdms/mysqldata/bin/` 目录编写配置文件如下：文件命名为 `my_data.cnf`

	[mysql_cluster] 
	# Options for data node process: 
	# location of management server**注意这里是指向管理服务器的IP！**
	ndb-connectstring=172.29.131.136:1186,

**同样配置给另一个服务器**

	#把数据节点的运行目录加入环境变量
	vim ~/.bash_profile
	#在PATH变量后面增加":/usr/local/mysql-gdms/mysqldata/bin";
	# 如下形式：
	PATH=$PATH:$HOME/bin:/usr/local/mysql-gdms/mysqlmgm/bin:/usr/local/mysql-gdms/mysqldata/bin
	# 或
	PATH=$PATH:$HOME/bin:/usr/local/mysql-gdms/mysqldata/bin
	#退出VIM，使用命令，让环境变量立即生效
	source ~/.bash_profile

### 配置SQL节点

这个比较复杂，要分别在两台sql节点上执行下面操作：

	#创建应用节点所需目录
	mkdir -p /usr/local/mysql-gdms/mysqlapp/
	mkdir /usr/local/mysql-gdms/mysqlapp/data
	mkdir /usr/local/mysql-gdms/mysqlapp/log
	mkdir /usr/local/mysql-gdms/mysqlapp/socket
	mkdir /usr/local/mysql-gdms/mysqlapp/tmp
	
	#复所需运行文件到应用节点目录
	cp -r /usr/local/mysql /usr/local/mysql-gdms/mysqlapp/app/
	
	#目录转到mysql应用节点运行目录
	cd /usr/local/mysql-gdms/mysqlapp/app/
	
	#如果出现问题，需要安装下
	dpkg –i libaio1_0.3.109-2ubuntu1_amd64.deb
	dpkg -i libaio-dev_0.3.109-2ubuntu1_amd64.deb 
	
	#创建mysql实例
	./bin/mysqld --collation-server=utf8_general_ci --character-set-server=utf8 --basedir=/usr/local/mysql-gdms/mysqlapp/app --datadir=/usr/local/mysql-gdms/mysqlapp/data --initialize

`/usr/local/mysql-gdms/mysqlapp/app/` 目录下创建 `my_app.cnf`文件

	[mysqld]
	ndbcluster=on
	port=3306
	log-error=/usr/local/mysql-gdms/mysqlapp/log/mysqld.err
	basedir=/usr/local/mysql-gdms/mysqlapp/app
	datadir=/usr/local/mysql-gdms/mysqlapp/data
	tmpdir=/usr/local/mysql-gdms/mysqlapp/tmp
	ndb-connectstring=172.29.131.136:1186,
	socket=/usr/local/mysql-gdms/mysqlapp/socket/mysql.socket

分别继续执行下面操作：

	#把应用节点的运行目录加入环境变量
	vim ~/.bash_profile
	
	#在PATH变量后面增加":/usr/local/mysql-gdms/mysqlapp/app/bin";
	# 如下形式：
	PATH=$PATH:$HOME/bin:/usr/local/mysql-gdms/mysqlmgm/bin:/usr/local/mysql-gdms/mysqldata/bin:/usr/local/mysql-gdms/mysqlapp/app/bin
	# 或
	PATH=$PATH:$HOME/bin:/usr/local/mysql-gdms/mysqldata/bin:/usr/local/mysql-gdms/mysqlapp/app/bin
	#退出VIM，使用命令，让环境变量立即生效
	source ~/.bash_profile

### 运行各个节点

#### 管理节点
	
	#切换管理员
	sudo -s
	#切换目录
	cd /usr/local/mysql-gdms/mysqlmgm/bin
	
	#第一次启动是使用
	ndb_mgmd -f /usr/local/mysql-gdms/mysqlmgm/bin/config.ini --configdir=/usr/local/mysql-gdms/mysqlmgm/bin/config --initial

	#以后的每一次启动使用
	ndb_mgmd -f /usr/local/mysql-gdms/mysqlmgm/bin/config.ini --configdir=/usr/local/mysql-gdms/mysqlmgm/bin/config

#### 数据节点
	
	#切换管理员
	sudo -s
	#切换目录
	cd /usr/local/mysql-gdms/mysqldata/bin
	
	#第一次启动是使用
	ndbmtd --defaults-file=/usr/local/mysql-gdms/mysqldata/bin/my_data.cnf --initial
	
	#以后的每一次启动使用
	ndbmtd --defaults-file=/usr/local/mysql-gdms/mysqldata/bin/my_data.cnf 

#### SQL节点

	#创建启动应用节点所需的符号链接
	ln -s /usr/local/mysql-gdms/mysqlapp/socket/mysql.socket /tmp/mysql.sock
	
	#创建mysql用户和组，以启动mysql应用节点服务
	groupadd mysql
	useradd -g mysql -s /usr/sbin/nologin mysql
	#赋值用户和组的权限
	chown -R mysql:mysql /usr/local/mysql-gdms

启动mysql:

	#进入目录
	cd /usr/local/mysql-gdms/mysqlapp/app/bin
	#启动
	./mysqld_safe  --defaults-file=/usr/local/mysql-gdms/mysqlapp/app/my_app.cnf --user=mysql

### 关闭集群

顺序：

开启： 管理-> 数据 -> SQL
关闭： 管理-> SQL

#### 管理节点

	#切换管理员
	sudo -s
	#执行关闭
	/usr/local/mysql-gdms/mysqlmgm/bin/ndb_mgm -e shutdown

#### SQL节点

	#进入目录
	cd /usr/local/mysql-gdms/mysqlapp/app/bin
	#执行关闭
	./mysqladmin -u root -p shutdown

### 监控集群

管理节点登陆：

	cd /usr/local/mysql-gdms/mysqlmgm/bin
	ndb_mgm
	show

---

参考阅读：

http://blog.csdn.net/icerleer/article/details/46404573

http://bangbangba.blog.51cto.com/3180873/1710062


---

### 附录

修改root密码：

`SET PASSWORD FOR 'root'@'localhost' = PASSWORD('ices515.com');`

远程访问

`grant all PRIVILEGES on *.* to root@'172.29.144.51' identified by 'ices515.com';`