
SET TIME ON
SET ECHO ON
--SET TIMING ON 
SET LINE 200
SET TRIMSPOOL OFF 
SET PAGESIZE 0
SET VERIFY OFF

define  TMP=&1
define  PERCENT=&2

SPOOL &TMP
SELECT d.tablespace_name
        , NVL(b.allocatesize - NVL(f.freesize, 0), 0)   used_MB
        , a.maxsize maxsize_MB
        , NVL(round((b.allocatesize - NVL(f.freesize, 0)) / a.maxsize * 100), 0) pct_used
FROM dba_tablespaces d 
        , (     SELECT tablespace_name,sum(maxsize) maxsize
                FROM (  SELECT tablespace_name, decode(autoextensible,'YES',round(sum(maxbytes)/1024/1024),round(sum(bytes)/1024/1024)) maxsize     
                                FROM dba_data_files      
                                GROUP BY tablespace_name,autoextensible
                        ) GROUP BY tablespace_name
          ) a
        , ( SELECT tablespace_name, sum(bytes)/1024/1024 allocatesize
      from dba_data_files
      group by tablespace_name
          ) b 
        , (     SELECT tablespace_name, sum(bytes)/1024/1024 freesize
                FROM dba_free_space
                GROUP BY tablespace_name
          ) f 
WHERE d.tablespace_name = a.tablespace_name(+)  
AND d.tablespace_name = b.tablespace_name(+)
AND d.tablespace_name = f.tablespace_name(+)
AND d.contents='PERMANENT'
AND NVL(round((b.allocatesize - NVL(f.freesize, 0)) / a.maxsize * 100), 0) > &PERCENT
/

SPOOL OFF

EXIT
