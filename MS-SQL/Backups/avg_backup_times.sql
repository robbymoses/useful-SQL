/***************************************************************************************************
Create Date:        Nov. 29, 2023
Author:             Robert Moses
Description:        Gathers the details from backup tables located in msdb.dbo to analyze simple
                    statistics like average run time, average back up sizes, and last time it ran.
Parameter(s):       @previousBackupLimit This parameter controls the number of records used to average
                    the statistics. This is used by a row_number window function to order the previous
                    runs by their last run date per database.
***************************************************************************************************/
DECLARE @previousBackupLimit int = 5

;WITH backups_cte AS
         (SELECT BS.database_name
               , BMF.physical_device_name
               , BS.backup_start_date
               , CONVERT(DECIMAL(10, 2), BS.backup_size / 1024 / 1024)              AS backupSizeMB
               , CONVERT(DECIMAL(10, 2), BS.compressed_backup_size / 1024 / 1024)   AS compressedBackupSizeMB
               , DATEDIFF(ss, BS.backup_start_date, BS.backup_finish_date)          AS runTimeInSeconds
               , Row_Number() OVER
                 (PARTITION BY BS.database_name ORDER BY BS.backup_start_date DESC) AS rowNum
          FROM msdb.dbo.backupset BS
                   JOIN msdb.dbo.backupmediafamily BMF
                        ON BS.media_set_id = BMF.media_set_id)
SELECT D.name                                                              AS databaseName
     , CONVERT(varchar, DATEADD(ms, AVG(runTimeInSeconds) * 1000, 0), 114) AS avgRunTime
     , AVG(backupSizeMB)                                                   AS avgBackupSizeMB
     , AVG(compressedBackupSizeMB)                                         AS avgCompressedBackupSizeMB
     , MAX(backup_start_date)                                              AS last_run
FROM sys.databases D
         LEFT JOIN backups_cte CTE
                   ON D.name = CTE.database_name
                       AND rowNum < @previousBackupLimit
GROUP BY D.name