SELECT o.name,
       s.last_execution_time,
       s.type_desc,
       s.execution_count
FROM sys.dm_exec_procedure_stats s
         INNER JOIN sys.objects o
                    ON s.object_id = o.object_id
-- DATABASE NAME
WHERE DB_NAME(s.database_ID) = ''
-- SPROC NAME
  AND o.name LIKE ('')