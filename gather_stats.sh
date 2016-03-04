#!/usr/bin/env bash

######################################################################################
## Program: gather_stats.sh
## Purpose: It used to gather stats base on our defined table configuration 
##			for remote Oracle database by ora_sql
## Usage:   gather_stats.sh -t <tns_string1[,string2]> -u <username> -f <tab config file>
## Required: ora_sql - login remote db to execute sql file 
##	
## Version: 1.1
## Author:  rekcah865@gmail.com
## Revision History
##+		Wei.Shen	v1.0	Feb 19 2016	Creation
##+		Wei.Shen	v1.1	Feb 25 2016 Add -f function to support customized conf
##
######################################################################################

PP=$(cd $(dirname $0) && pwd)
PN=$(basename $0 ".sh")
CP=$PP/conf
LP=$PP/log
SP=$PP/sql

LOG=$LP/$PN.log
VER=1.1

## Function list
usage() { 
	echo -e "\n$PN v$VER "
	echo -e "Usage:  $PN.sh -s <tns_string1[,string2]> -u <username> -f <tab config file>"
	echo -e "	Can only run for ODS / TS / LSS database\n"
}
log() { 
	echo -e "$(date '+%Y-%m-%d %H:%M:%S') " "$1" >> $LOG
	if [ "$2" != "noecho" ]; then
        echo -e "$1"
    fi
}
run_stats() {
	CONF=$1
	## gather for table from configuration
	while read LINE; do
		#echo $LINE
		set - $LINE
		OWNER=$1
		TAB=$2
		ESTIMATE=$3
		DEGREE=$4
		GRANULARITY=$5
		CASCADE=$6
		
		## Check collection scheme
		if [[ "$GRANULARITY" == "GLOBAL" || "$GRANULARITY" == "DEFAULT" ]]; then
			# Analysis all table
			[[ ! -f ${TABLE_STATS} ]] && log "File ${TABLE_STATS} not found" && return 1
			log "Gaterh stats for $TAB"
			$PP/ora_sql -S -t $TNS -u $USER -f ${TABLE_STATS} -p "$OWNER $TAB $ESTIMATE $DEGREE $GRANULARITY $CASCADE" 2>>$LOG
			continue
		elif [[ "$GRANULARITY" == "PARTITION" ]]; then
			[[ ! -f ${CURRENT_PARTITION} ]] && log "File ${CURRENT_PARTITION} not found" && return 1
			log "Get partition name for $TAB"
			PARTNAME=$($PP/ora_sql -S -t $TNS -u $USER -f ${CURRENT_PARTITION} -p "${OWNER} ${TAB} ${RUN_DATE}" 2>>$LOG)
		elif [[ "$GRANULARITY" == "SUBPARTITION" ]]; then
			[[ ! -f ${CURRENT_SUBPARTITION} ]] && log "File ${CURRENT_SUBPARTITION} not found" && return 1
			log "Get sub partition name for $TAB"
			PARTNAME=$($PP/ora_sql -S -t $TNS -u $USER -f $CURRENT_SUBPARTITION -p "${OWNER} ${TAB} ${RUN_DATE}" 2>>$LOG)
		fi
		if [[ -z $PARTNAME ]]; then
			log "Cannot find current partition for $OWNER.$TAB"		
			continue
		else
			echo $PARNAME
			for PAR in $PARTNAME; do
				[[ ! -f ${PARTITION_STATS} ]] && log "File ${PARTITION_STATS} no found" && return 1
				log "Gather stats for partition $PAR on $TAB"
				$PP/ora_sql -S -t $TNS -u $USER -f $PARTITION_STATS -p "$OWNER $TAB $PAR $ESTIMATE $DEGREE $GRANULARITY $CASCADE" 2>>$LOG
			done			
		fi
		
	done < <(cat $CONF |awk '$1 !~ /^#/ && NF == 6')
	
	## Gather stats for system 
	[[ ! -f ${SYSTEM_STATS} ]] && log "File ${PARTITION_STATS} no found" && return 1
	log "Gather stats for system on $TNS"
	$PP/ora_sql -S -t $TNS -u $USER -f $SYSTEM_STATS 2>>$LOG
}

## Check ora_sql 
[[ ! -x $PP/ora_sql ]] && log "File $PP/ora_sql not be executable" && exit 1 
#[[ ! $(command -v mailx) ]] && log "mailx is required."

## Process check - Alert if previous running
MAIL_SENDER=FIS.Notice@xxx.com
MAIL_RCV=rekcah865@gmail.com
if [[ $(ps -ef|grep "${PN}.sh $*"|grep -v $$|grep -v grep|wc -l) -gt 1 ]]; then
	log "Found last time $PN is running. Exit.."
	MAIL_TITLE="Duplicated process $PN found"
	ps -ef|grep "${PN}.sh $*" | mailx -s "${MAIL_TITLE}" -r "${MAIL_SENDER}" "${MAIL_RCV}"	
	exit 1
fi


## Initial variable
TNSS=
USER=
CONF=
CONFFILE=

## Parse parameter
while getopts s:u:f: next; do
	case $next in
		s) TNSS=$OPTARG;;
		u) USER=$OPTARG;;
		f) CONF=$OPTARG;;
		*) usage && exit 1 ;;
	esac
done

if [[ $TNSS == "" || $USER == "" ]]; then
	echo "[ORA-]Miss define for variable TNS,USER"
	echo ""
	usage
	exit 1
fi
if [[ -f $CP/$CONF ]]; then
	log "Use customized configuration file $CONF"
	CONFFILE=$CP/$CONF
fi


# Script Execute Date and Time in DD-MON-YYYY HH24:MI format
RUN_DATE=$(date +%d-%b-%Y_%H:%M)

## stats SQL file
TABLE_STATS=$SP/table_stats.sql
PARTITION_STATS=$SP/partition_stats.sql
SUBPARTITION_STATS=$SP/subpartition_stats.sql
#CURRENT_PARTITION=$SP/current_partition.sql
CURRENT_SUBPARTITION=$SP/current_subpartition.sql
SYSTEM_STATS=$SP/system_stats.sql

## For multi-instance separated by ,
MULTIS=$(echo $TNSS|awk -F\, '{print NF}')

if [[ $MULTIS -gt 1 ]]; then
	IFS_ORG=$IFS
	IFS=","
	for TNS in $TNSS; do
		## Check configure file
		if [[ -z $CONFFILE ]] ; then
			log "Use default configuration file stats_${USER}.conf"
			if [[ ! -f $CP/stats_${USER}.conf ]] ; then
				log "File $CP/stats_${USER}.conf not found. Skipping gather stats for $TNS.. " 
				exit 1
			else
				CONFFILE=$CP/stats_${USER}.conf
			fi
		fi			
		
		## current_partition.sql is different for ODS and LSS
		CURRENT_PARTITION=$SP/current_partition_${USER}.sql
		
		log "$TNS: gather stats for table under $USER start"
		## read table configuration from conf file
		run_stats $CONFFILE
		
		log "$TNS: gather stats for table under $USER end"
	done
	IFS=${IFS_ORG}
else
	TNS=$TNSS
	## Check configure file
	if [[ -z $CONFFILE ]] ; then
		log "Use default configuration file stats_${USER}.conf"
		if [[ ! -f $CP/stats_${USER}.conf ]] ; then
			log "File $CP/stats_${USER}.conf not found. Skipping gather stats for $TNS.. " 
			exit 1
		else
			CONFFILE=$CP/stats_${USER}.conf
		fi
	fi				
	
	## current_partition.sql is different for ODS and LSS
	CURRENT_PARTITION=$SP/current_partition_${USER}.sql
	
	log "$TNS: gather stats for table under $USER start"
	## read table configuration from conf file
	run_stats $CONFFILE
	
	log "$TNS: gather stats for table under $USER end"
fi

## End