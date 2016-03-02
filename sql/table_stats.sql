set verify off
set timing on

define  ownname=&1
define  tabname=&2
define  estimate_percent=&3
define  degree=&4
define  granularity=&5
define  cascade=&6

prompt
exec dbms_stats.gather_table_stats(ownname=>'&ownname',tabname=>'&tabname',estimate_percent=>&estimate_percent,degree=>&degree,granularity=>'&granularity',cascade=>&cascade,method_opt=>'FOR ALL COLUMNS SIZE 1');

exit
