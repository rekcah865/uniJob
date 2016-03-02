#!/usr/bin/env bash

######################################################################################
## Program: index_rebuild.sh
## Purpose: It used to rebuild index for remote OLTP Oracle database by ora_sql
## Usage:   index_rebuild.sh.sh -f <configuration file: default - index.conf>
## Required: ora_sql - login remote db to execute sql file 
##			 config file (default: index.conf) - include tns user tbs_number 
##			 example: szdprlss1a, index_admin, 1
##	
## Version: 1.0
## Author:  rekcah865@gmail.com
## Revision History
##+         Wei.Shen	v1.0	Feb 18 2016	Creation
##
######################################################################################

PP=$(cd $(dirname $0) && pwd)
PN=$(basename $0 ".sh")
LP=$PP/log
CP=$PP/conf
SP=$PP/sql

LOG=$LP/$PN.log
VER=1.0
DEF_CONF=$CP/index.conf
HOST=$(hostname)

## Function list
usage() { 
	echo -e "\n$PN v$VER \n$PN.sh -f <configuration file: default - index.conf>"
	echo -e "	File format: tns schema role_name"
	echo -e "		e.g. szdprlss1a index_admin 1\n"
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

## loop 
while read TNS SCHEMA NO; do
	# Upper SCHMEA
	#SCHEMA=$(echo $SCHEMA|tr 'a-z' 'A-Z')
	
	TMPSQL=$PP/${PN}_${TNS}.sql
	# SQL script generate
	cat > $SP/$PN.sql <<EOF
SET TIME ON
SET ECHO ON
--SET TIMING ON	
SET LINE 200
SET PAGESIZE 0
SPOOL $TMPSQL
SELECT '--Rebuild tablespace :'|| tablespace_name 
FROM (	SELECT tablespace_name 
		FROM index_admin.index_rebuild_ts
		ORDER BY last_rebuild_date )
WHERE rownum <=$NO;

SELECT 'ALTER INDEX '
	||OWNER||'.'
	||segment_name
	||' REBUILD '
	||CASE 	WHEN segment_type='INDEX PARTITION' THEN 'PARTITION '||partition_name
			WHEN segment_type='INDEX SUBPARTITION' THEN 'SUBPARTITION '||partition_name
			ELSE ''
		END
	||' nologging online;'
from dba_segments
WHERE (owner,segment_name) not in 
	(	SELECT owner,index_name 
		FROM index_rebuild_excluded
	)
AND (owner,segment_name) in 
	(	SELECT a.owner,a.index_name 
		FROM dba_indexes a, index_rebuild_cfg b 
		WHERE b.rebuild='Y'
		AND a.index_type=b.index_type 
	)
AND tablespace_name in 
	(	SELECT a.tablespace_name 
		FROM (SELECT tablespace_name FROM index_rebuild_ts ORDER BY last_rebuild_date) a
		WHERE rownum <=$NO
	)
/
SELECT 'UPDATE index_rebuild_ts SET last_rebuild_date=sysdate WHERE tablespace_name='''||a.tablespace_name||''';'
FROM (SELECT tablespace_name FROM index_rebuild_ts ORDER BY last_rebuild_date) a
WHERE rownum <=$NO
/
SELECT 'commit;' FROM dual;
SPOOL OFF

SPOOL $TMP
@$TMPSQL
SPOOL OFF
EXIT

EOF

	log "$TNS:$SCHEMA:$NO $PN start."
	## Execute index rebuild script
	#$PP/ora_sql -t $TNS -u $SCHEMA -f $PP/$PN.sql 2>>$LOG
	$PP/ora_sql -S -t $TNS -u $SCHEMA -f $SP/$PN.sql 2>>$LOG
	if [[ $? -ne 0 ]]; then
		log "ora_sql execute error. Please check log" && continue
		exit 1
	fi
	#$PP/ora_sql -t $TNS -u $SCHEMA -f $PP/$PN.sql >> $TMP
	log "$TNS:$SCHEMA:$NO $PN end."
	if [[ $(grep ORA- $TMP|wc -l) -ge 1 ]]; then
		log "Error on $PN for index rebuild($NO tablespace) under $SCHEMA on $TNS DB" 
		if [[ ${MAIL_FLAG} -eq 1 ]]; then
			grep ORA- $TMP >> $LOG
			MAIL_TITLE="Index Rebuild for $TNS - ORA error found"
			## Mail alert
			cat $TMP | mailx -s "${MAIL_TITLE}" -r "${MAIL_SENDER}" "${MAIL_RCV}"		
			log "Send alert to ${MAIL_RCV}"
		fi
	fi
	## clean temporary file
	[[ -f $PP/${PN}_${TNS}.sql ]] && rm $PP/${PN}_${TNS}.sql
	
done < <(cat $CONF|grep -v "^#"|sed '/^$/d')

## clean temporary file
[[ -f $SP/$PN.sql ]] && rm $SP/$PN.sql
[[ -f $TMP ]] && rm $TMP

## End