# uniJob
Unify cronjob on DB server with Docker container
 
### uniJob Script


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

* Run container

```linux
$ docker run -d -l uniJob1 --name=uniJob1 -v /home/docker/uniJob:/uniJob -v /home/docker/uniJob/crontab:/uniJob/crontab unijob:centos6 
$ docker ps 

$ docker exec -it uniJob1 /bin/bash
$ crontab -l

```

* crontab change

```shell
$ vi /home/docker/uniJob/crontab

$ docker exec -it uniJob1 /bin/bash
$ crontab -e

```
