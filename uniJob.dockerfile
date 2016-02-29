##
FROM centos:6.7

MAINTAINER Wei.Shen

## Base setting
RUN echo "proxy=http://10.40.3.249:3128" >> /etc/yum.conf
RUN ln -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN echo ZONE="Asia/Shanghai" > /etc/sysconfig/clock

## Supervisord
RUN yum -y install python-setuptools
ENV http_proxy=http://10.40.3.249:3128 
ENV https_proxy=http://10.40.3.249:3128
RUN easy_install supervisor
ADD ./uniJob_supervisor.conf /etc/supervisor.conf

## Cron, Postfix, ksh
RUN yum -y install vixie-cron mailx ksh postfix unzip

## Oracle Instant client
## Download - http://download.oracle.com/otn/linux/instantclient/121020/instantclient-basic-linux.x64-12.1.0.2.0.zip
ADD ./instantclient-basic-linux.x64-12.1.0.2.0.zip /tmp
RUN cd /opt && unzip /tmp/instantclient-basic-linux.x64-12.1.0.2.0.zip && rm /tmp/instantclient-basic-linux.x64-12.1.0.2.0.zip

ENTRYPOINT ["/usr/bin/supervisord","-c","/etc/supervisor.conf"]
