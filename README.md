# uniJob
Unify cronjob out of Oracle DB server with Docker container
 
### uniJob Script

* Tablespace monitor - *[tbs_monitor.sh](tbs_monitor.sh)*

	Used to monitor Tablespace of Oracle database which defined by configuration file  
	
	```
	Usage
		tbs_monitor.sh.sh -f <configuration file: default - tbs.conf>
	```
	
* Gather stats - *[gather_stats.sh](gather_stats.sh)*

	Used to gather tables' stats which defined base on your configuration
	
	```
	Usage
		gather_stats.sh -s <tns_string1[,string2]> -u <username> -f <tab config file>
	```
	
* Index Rebuild - *[index_rebuild.sh](index_rebuild.sh)*
	
	Used to Rebuild index of OLTP
	
	```
	Usage
		index_rebuild.sh.sh -f <configuration file: default - index.conf>
	```
	
* Grant Role - *[grant_role.sh](grant_role.sh)*

	Used to Grant application role
	
	```
	Usage 
		grant_role.sh -f <configuration file: default - role.conf>
	```
	
* Purge data of table - *[purge_table.sh](purge_table.sh)*

	Used to purge table(such as monitor,trans_Hourly,msg,msg_source) for remote Oracle database 
	
	```	
	Usage
		purge_table.sh -t <tns_string1[,string2]> -u <username> -t <table name :monitor|trans|msg>
	```
	
* Purge database(Oracle,PosstgreSQL) log(trace,log) - *[purge_dblog.go](purge_dblog.go)*

	Used to purge Oracle trace or audit file in Oracle RDBMS or Oracle Grid Infrastructure or log file in PostgreSQL database
	
	```
	Usage
		purge_dblog -h <Host/IP> -t <Type: oracle|grid|postgres> -u <User>
		
		Default value h=**** -t=oracle -u=oracle   
		user is to connect remote server with ssh and it can get password from orapass
	```	
* Remote sql - *[rsql.sql](rsql.sh)*
	
	Used to execute SQL in remote Oracle database. You can configure sql file under sql/ folder
	
	```
	Usage
		rsql.sh -s <tns_string1[,string2]> -u <username> -f <sqlfile :handld_queue>
	```
	
### uniJob in Docker

* Build image(CentOS6.7) which includes cron, oracle instant client

	- Download [Oracle 12.1 instant client](http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html)
	- Edit supervisor file - *[uniJob_supervisor.conf](uniJob_supervisor.conf)*
	- Edit docker file - *[uniJob.dockerfile](uniJob.dockerfile)*
	
```command
$ pwd
/home/docker/uniJob
$ vi uniJob.dockerfile
...
$ vi uniJob_supervisor.conf
...
$ docker build --rm -t unijob:centos6  -f uniJob.dockerfile .

$ docker images

```

* Prepare for container

	- crontab
	- tnsnames.ora
	- ora.env
	
```command
$ cd /home/docker/uniJob
$ vi crontab
...
$ vi ora.env
export ORACLE_HOME=/opt/instantclient_12_1
export LD_LIBRARY_PATH=${ORACLE_HOME}
export TNS_ADMIN=/uniJob
export PATH=$ORACLE_HOME:$PATH
```

* Run container

```linux
$ docker run -d -l uniJob1 --name=uniJob1 -v /home/docker/uniJob:/uniJob -v /home/docker/uniJob/crontab:/uniJob/crontab unijob:centos6 

$ docker run -d -l uniJob1 --name=uniJob1 -v /home/docker/uniJob:/uniJob unijob:centos6 
...
$ docker ps 
CONTAINER ID        IMAGE                   COMMAND                  CREATED             STATUS              PORTS                   NAMES
afe85f693b4f        unijob:centos6          "/usr/bin/supervisord"   5 seconds ago       Up 3 seconds                                uniJob1
$ docker exec -it uniJob1 /bin/bash
$ crontab -l
...
```

* crontab change

```shell
$ vi /home/docker/uniJob/crontab
...
$ docker restart uniJob1
...
```

### Reference

[在docker中使用cron](http://blog.wuliwala.net/2015/01/12/run-crond-in-container/)
