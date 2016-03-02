# uniJob
Unify cronjob out of Oracle DB server with Docker container
 
### uniJob Script

* Tablespace monitor (tbs_monitor.sh)[tbs_monitor.sh]
	Used to monitor Tablespace of Oracle database which defined by configuration file 
	Usage: tbs_monitor.sh.sh -f <configuration file: default - tbs.conf>
	
* Gather stats (gather_stats.sh)[gather_stats.sh]
* Index Rebuild (index_rebuild.sh)[index_rebuild.sh]
* Grant Role (grant_role.sh)[grant_role.sh]
* Purge data of table (purge_table.sh)[purge_table.sh]
* Purge Oracle log(trace,log) (purge_oralog.go)[purge_oralog.go]
* Remote sql (rsql.sh)[]

### uniJob in Docker

* Build image which includes cron, oracle instant client

	- Download (Oracle 12.1 instant client)[http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html]
	- Edit supervisor file *(uniJob_supervisor.conf)[uniJob_supervisor.conf]*
	- Edit docker file *(uniJob.dockerfile)[uniJob.dockerfile]*
	
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

```command
$ cd /home/docker/uniJOb
$ vi crontab
...
$ vi ora.env
...
```
Prepare tnsnames.ora file in directory which is defined in ora.env file 

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

```

* crontab change

```shell
$ vi /home/docker/uniJob/crontab
...
$ docker restart uniJob1
...
```

sqlplus: error while loading shared libraries: libaio.so.1: cannot open shared object file: No such file or directory

$ go build purge_oralog.go

ls -l purge_oralog*


