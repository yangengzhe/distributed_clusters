# Tomcat负载均衡

所用软件Apache2 + Tomcat

## 主要方式
mod_proxy、mod_proxy_blancer、mod_jk

### mod_proxy

mod_proxy是一种分工合作的方式，利用反向代理的技术，将任务跳转给各个服务器，并不能实现负载均衡，仅仅是访问跳转

主要用途：反向单例 单IP多域名多站点的功能

### mod_proxy_blancer

mod_proxy_blancer是mod_proxy的扩展，支持负载平衡。

可以按轮询策略、权重分配策略和请求相应负载均衡策略进行调度

### mod_jk

mod_jk是专门针对tomcat的方法，通过AJP协议链接Tomcat

### 比较

- proxy的缺点是，当其中一台tomcat停止运行的时候，apache仍然会转发请求过去，导致502网关错误。但是只要服务器再启动就不存在这个问题。
- mod_jk方式的优点是，Apache 会自动检测到停止掉的tomcat，然后不再发请求过去。
- mod_jk方式的缺点就是，当停止掉的tomcat服务器再次启动的时候，Apache检测不到，仍然不会转发请求过去。
- proxy和mod_jk的共同优点是.可以只将Apache置于公网，节省公网IP地址资源。可以通过设置来实现Apache专门负责处理静态网页，让Tomcat专门负责处理jsp和servlet等动态请求。
- 共同缺点是：如果前置Apache代理服务器停止运行，所有集群服务将无法对外提供。
- proxy和mod_jk对静态页面请求的处理，都可以通设置来选取一个尽可能优化的效果。
- mod_proxy_balancer和mod_jk都需要修改tomcat的配置文件配合<Engine name="Catalina" defaultHost="localhost" jvmRoute="tomcat1">
- 这三种Tomcat集群方式对实现最佳负载均衡都有一定不足，mod_proxy_balancer和mod_jk相对好些，mod_jk的设置能力更强些。lbfactor参数来分配请求任务。
- apache自带mod_proxy功能模块中目前只可以实现两种不同的负载均衡集群实现方式，第一种是分工合作的的形式，通过各台主机负责不同的任务而实 现任务分工。第二种是不同的机器在担任同样的任务，某台机器出现故障主机可以自动检测到将不会影响到客户端，而第一种却不能实现但第一种实现方式的优点在 于他是主服务器负担相应没第二种大因为台只是提供跳转指路功能，形象的说他不给你带路只是告诉你有条路可以到，但到了那是否可以看到你见的人他已经不会去管你了。相比之下第二种性能要比第一种会好很多；但他们都有个共同点都是一托N形式来完成任务的所以你的主机性能一定要好。

## Session的同步

sticky模式、复制模式、Terracotta模式（非自带）

###sticky模式

把所有同一个session的请求都发送到相同的节点，这样就避免了Session的问题

### 复制模式

所有的节点都保证同一个Session，有一点点的改变都会进行广播同步

方式：只要修改server.xml文件

（1）修改Engine节点信息： <Engine name="Catalina" defaultHost="localhost" jvmRoute="tomcat1">
（2）去掉<Cluster> <\Cluster> 的注释符
（3）web.xml中增加 <distributable/>

### Terracotta模式

另一种方式就是利用开源软件Terracotta。Terracotta的基本原理是对于集群间共享的数据，当在一个节点发生变化的时 候，Terracotta只把变化的部分发送给Terracotta服务器，然后由服务器把它转发给真正需要这个数据的节点。

## 安装实例 —— mod_jk模式

### 安装程序

	apt-get install apache2
	apt-get install libapache2-mod-jk

### 配置文件

	#进入配置文件目录
	cd /etc/apache2/mods-available
	vim jk.conf

在配置文件中，分别添加`JkOptions +RejectUnsafeURI`和`JkMount /* loadbalancer`

	#配置work.properties文件
	vim /etc/libapache2-mod-jk/workers.properties

修改`workers.tomcat_home`和`workers.java_home`为自己的tomcat和java路径.java:/usr/lib/jvm/java-1.7.0-openjdk-amd64 tomcat:/usr/share/tomcat7

配置worker.list
	
	#配置
	vim /etc/apache2/sites-available/000-default.conf

在<VirtualHost *:80>中添加`JkMount /* loadbalancer`

**修改每个节点/var/lib/tomcat7/conf/server.xml**

`<Engine name="Catalina" defaultHost="localhost" jvmRoute="tomcat1">`添加jvmRoute标签（要和前面对应上）

在<Engine/>标签中添加以下这段代码：

`<Cluster className="org.apache.catalina.ha.tcp.SimpleTcpCluster"/>`

重启服务 `service tomcat7 restart`

## 安装实例——Ubuntu mod_proxy_blancer模式

### 加载模块

	#进入apapche的配置目录
	cd /etc/apache2/mods-enabled
	#采用链接的方式加载必要模块
	ln -s ./../mods-available/proxy.load proxy.load
	ln -s ./../mods-available/proxy_http.load proxy_http.load
	ln -s ./../mods-available/proxy_balancer.load proxy_banancer.load
	#需要的支持文件
	ln -s ./../mods-available/slotmem_shm.load slotmem_shm.load
	ln -s ./../mods-available/lbmethod_byrequests.load lbmethod_byrequests.load
	ln -s ./../mods-available/lbmethod_bybusyness.load lbmethod_bybusyness.load
	ln -s ./../mods-available/lbmethod_bytraffic.load lbmethod_bytraffic.load
	ln -s ./../mods-available/lbmethod_heartbeat.load lbmethod_heartbeat.load

执行完上述模块的加载后，可以重启apache，如果发送错误可以查看错误日志

	#重启apache2
	/etc/init.d/apache2 restart
	#或
	service apache2 restart
	
	#错误日志
	/var/log/apache2/error.log 

### 配置反向代理（负载均衡）

	vi /etc/apache2/sites-available/000-default.conf
	
如下配置内容：

	<VirtualHost *:80>
		ServerAdmin admin@bit.com
		ProxyRequests Off
		Proxypass / balancer://proxy/
		ProxyPassReverse / balancer://proxy/
		<Proxy balancer://proxy>
			Order Deny,Allow
			Allow from all
			ProxySet lbmethod=bybusyness
			BalancerMember http://172.29.131.139:8080 loadfactor=1
			BalancerMember http://172.29.131.140:8080 loadfactor=1
		</Proxy>
	</VirtualHost>

**注意：**

- lbmethod=byrequests 按照请求次数均衡(默认) 
- lbmethod=bytraffic 按照流量均衡 
- lbmethod=bybusyness 按照繁忙程度均衡(总是分配给活跃请求数最少的服务器)

然后重启服务器，就完成了配置工作
	
	/etc/init.d/apache2 restart

### Session同步

1、下载Terracotta

	http://d2zwv9pap9ylyd.cloudfront.net/terracotta-3.7.7.tar.gz

2、安装

	tar zxvf terracotta-3.4.1.tar.gz
	mv terracotta-3.4.1 /usr/local/terracotta

3、配置Tomcat作为Terracotta客户端

复制`terracotta-session-1.3.7.jar`和`terracotta-toolkit-1.1-runtime-5.7.0.jar`到Tomcat/lib目录：`CATALINA_HOME/lib`

编辑 /var/lib/tomcat7/conf/context.xml文件

	<Context sessionCookiePath="/">
	<!-- 增加此配置 -->
	<Valve className="org.terracotta.session.TerracottaTomcat70xSessionValve" tcConfigUrl="172.29.131.138:9510"/>
	</Context>

**注意。编辑的文件中注意修改：server和web-application**

4、启动Terracotta

启动顺序：管理 => 子节点

	#进入目录
	cd /usr/local/terracotta
	#复制tc-config.xml到bin目录
	mv tc-config.xml ./bin/
	
	#配置java环境变量
	vi ~/.bashrc
	export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-amd64
	export JRE_HOME=${JAVA_HOME}/jre 
	export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib 
	export PATH=${JAVA_HOME}/bin:$PATH

	source ~/.bashrc
	
	#（主服务器）运行Terracotta(注意加 & 丢到后台执行)
	./start-tc-server.sh &

各个子节点，配置好context.xml后重启服务器

	#（各个子服务）重启Tomcat
	service tomcat7 restart

5、关闭

子节点关闭tomcat

管理节点执行 `./stop-tc-server.sh -n apache`

6、日志

	/var/lib/tomcat7/logs-172.29.131.139

---

参考：

- http://lihongchao87.iteye.com/blog/1727802
- https://my.oschina.net/u/865921/blog/349552
- http://www.cnblogs.com/interdrp/p/3574070.html

---

### 附录：

**注意拷贝mysql.jar到 tomcat/lib目录**

Tomcat目录：/var/lib/tomcat7/webapps/ROOT/

Logs:  /var/log/tomcat6

Binaries and Libs:  /usr/share/tomcat6 (although libs are symlinked to /usr/share/Java and some jars inside the bin directory get symlinked to /usr/share/Java as well)

System start/stop/status script: /etc/init.d/tomcat6.

CATALINA_HOME:  /usr/share/tomcat6

CATALINA_BASE:  /var/lib/tomcat6

The default webapps directory location is under /var/lib/tomcat6/

Configuration files are under /etc/tomcat6/