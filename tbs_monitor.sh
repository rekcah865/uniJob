#!/usr/bin/env bash

######################################################################################
## Program: tbs_monitor.sh
## Purpose: It used to monitor tablespace for remote Oracle database by ora_sql
## Usage:   tbs_monitor.sh.sh -f <configuration file: default - tbs.conf>
## Required: ora_sql - login remote db to execute sql file 
##			 config file (default: tbs.conf) - include tns user threshold
##			 example: szdprlss1a, index_admin, 80
##	
## Version: 1.0
## Author:  rekcah865@gmail.com
## Revision History
##+         Wei.Shen	v1.0	Feb 19 2016	Creation
##+         Wei.Shen	v1.1	Mar 01 2016	Separate mail conifg,SQL out of program
##
######################################################################################

PP=$(cd $(dirname $0) && pwd)
PN=$(basename $0 ".sh")
CP=$PP/conf
LP=$PP/log
SP=$PP/sql

LOG=$LP/$PN.log
VER=1.1
DEF_CONF=$CP/tbs.conf
HOST=$(hostname)

## Function list
usage() { 
	echo -e "\n$PN v$VER \n$PN.sh -f <configuration file: default - tbs.conf>"
	echo -e "	File format: tns user threshold"
	echo -e "		e.g. szdprlss1a, index_admin, 80\n"
}
log() { 
	echo -e "$(date '+%Y-%m-%d %H:%M:%S') " "$1" >> $LOG
	if [ "$2" != "noecho" ]; then
        echo -e "$1"
    fi
}

## Check ora_sql 
[[ ! -x $PP/ora_sql ]] && log "File $PP/ora_sql not be executable" && exit 1 
[[ ! $(command -v mailx) ]] && log "mailx is required."

## Mail
MAIL_CONFIG=$CP/mail.conf
if [[ -f ${MAIL_CONFIG} ]]; then
	MAIL_SENDER=$(awk -F ' *= *' '$1=="mail_sender"{print $2}' ${MAIL_CONFIG})
	MAIL_RECEIVER=$(awk -F ' *= *' '$1=="mail_receiver"{print $2}' ${MAIL_CONFIG})
	MAIL_FLAG=1
else
	log "Mail configuration file mail.conf not found"
	MAIL_FLAG=0
fi

## Initial variable
TNS=
SCHEMA=
ROLE=
SQL=$SP/$PN.sql
TMP=/tmp/$PN.tmp

## Parse config file
if [[ "$1" = "-f" ]]; then
	shift
	if [[ -f $CONF ]]; then
		CONF=$1
	else
		CONF=$CP/$1
	fi
else
	CONF=${DEF_CONF}
fi
## Check config file
[ ! -f $CONF ] && log "File $CONF not found. Exit.. " && usage && exit 1

## Check SQL file 
[ ! -f $SQL ] && log "File $SQL not found. Exit.. " && usage && exit 1

## loop 
while read TNS USER PERCENT; do

	#TMPSQL=$PP/${PN}_${TNS}.sql

	log "$TNS:$USER:>${PERCENT}% $PN start."
	## Execute tablespace forecast script
	#$PP/ora_sql -t $TNS -u $USER -f $TMPSQL 2>>$LOG
	$PP/ora_sql -S -t $TNS -u $USER -f $SQL -p "$TMP $PERCENT" 2>>$LOG
	if [[ $? -ne 0 ]]; then
		log "ora_sql execute error. Please check log" && continue
		exit 1
	fi

	if [[ $(grep "no rows selected" $TMP|wc -l) -ne 1 ]]; then
		NUM=$(cat $TMP|grep "rows selected."|awk '{print $1}')
		log "$NUM Tablespaces usage on $TNS is more than threshold ${PERCENT}%"		
		cat $TMP |sed '/^$/d;s/  */ /g;s/ $/%/g'>> $LOG
		if [[ ${MAIL_FLAG} -eq 1 ]]; then
			MAIL_TITLE="Tablespace Forecast for $TNS - Usage > ${PERCENT}% found"
			## Mail alert
			log "Send alert to ${MAIL_RCV}"
			sed -i '1i Tablespace		Used_Size(MB)	Max_Size(MB)	Percent_%\n' $TMP
			cat $TMP|grep -v "rows selected." | mailx -s "${MAIL_TITLE}" -r "${MAIL_SENDER}" "${MAIL_RCV}"	
		fi
	else
		log "No tablespace usage on $TNS is more than ${PERCENT}%"
	fi
	
	log "$TNS:$USER:>${PERCENT}% $PN end."
	## clean temporary file
	[[ -f $TMPSQL ]] && rm $TMPSQL
	
done < <(cat $CONF|grep -v "^#"|sed '/^$/d')

## clean temporary file
[[ -f $TMP ]] && rm $TMP

## End