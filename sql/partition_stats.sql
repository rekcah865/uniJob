set verify off
set timing on

define  ownname=&1
define  tabname=&2
define  partname=&3
define  estimate_percent=&4
define  degree=&5
define  granularity=&6
define  cascade=&7

prompt
exec dbms_stats.gather_table_stats(ownname=>'&ownname',tabname=>'&tabname',partname=>'&partname',estimate_percent=> &estimate_percent,degree=>&degree, granularity=>'&granularity',cascade=>&cascade,method_opt=> 'FOR ALL COLUMNS SIZE 1');

exit
	