set verify off
set timing on

exec DBMS_STATS.GATHER_SYSTEM_STATS;
exec DBMS_STATS.GATHER_DICTIONARY_STATS;

exit
