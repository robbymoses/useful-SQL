CREATE OR ALTER PROCEDURE [SchemaName].[ProcedureName]
    @saved_lsn_str NVARCHAR(36)
AS
/***************************************************************************************************
This is a template for querying CDC tables when you want to keep track of records that have changed
since previously run with slight modifications.

Procedure:          [procedureName]
Author:             [Name]
Description:        [Verbose description of what the query does goes here. Be specific and don't be
                    afraid to say too much. More is better, than less, every single time. Think about
                    "what, when, where, how and why" when authoring a description.]
Used By:            [Functional Area this is use in, for example, Payroll, Accounting, Finance]
Parameter(s):       @saved_lsn_str - Used to determine beginning window for cdc results.
Usage:              EXEC [SchemaName].[ProcedureName] @saved_lsn_str='53D71C00-1C00-0FFC-0001-000000000000'
****************************************************************************************************
SUMMARY OF CHANGES
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
***************************************************************************************************/
BEGIN
    DECLARE
        /*
            Capture Instance for the CDC table being queried. If you are unsure of the capture instance name, you can
            run this query:
                SELECT capture_instance FROM cdc.change_tables
        */
        @capture_instance NVARCHAR(255) = '',
        -- This is the guid representation of the @saved_lsn. This should be the @max_binary_guid of the previous run.
        @saved_lsn_guid uniqueidentifier,
        -- This is the binary value that will be the first row for the changes returned.
        @from_lsn binary(10),
        -- This is the binary value for the last row for the changes returned.
        @to_lsn binary(10) = sys.fn_cdc_get_max_lsn(),
        -- This is the LSN value that will be used to increment. This should be the @to_lsn of the previous run.
        @saved_lsn binary(10),
        -- This is the guid representation of the @to_lsn for the current run.
        @max_binary_guid uniqueidentifier;
    BEGIN
        -- CAST saved_lsn_str to GUID for proper conversion
        SET @saved_lsn_guid = CAST(@saved_lsn_str as uniqueidentifier)
        -- CAST the Guid to BINARY
        SET @saved_lsn = CAST(@saved_lsn_guid AS BINARY(10));
        -- Increment the LSN to the next value, if no value is supplied, use the min_lsn for the table.
        SET @from_lsn = sys.fn_cdc_increment_lsn(COALESCE(@saved_lsn, sys.fn_cdc_get_min_lsn(@capture_instance)));
        -- Set the @max_binary_guid so it can be returned
        SET @max_binary_guid = CAST(@to_lsn as uniqueidentifier);

        SELECT @max_binary_guid as max_lsn,
               *
        FROM
            /*
                Upon the enablement of CDC for a table, MSSQL will generate functions to assist with reading these
                tables.
                fn_cdc_get_all_changes_*:
                    will return every row that has changed for each transaction. This would
                    mean that if you update a record multiple times in different transaction, multiple records will be
                    returned.
                fn_cdc_get_net_changes_*:
                    This will return the latest change to a record. To see if the table in question supports it, you
                    can run the following:
                        SELECT capture_instance
                        FROM cdc.change_tables
                        WHERE supports_net_changes = 1
            */
            -- MSSQL will generate these functions on CDC Enablement for the table. For a list of these table names
            --cdc.fn_cdc_get_all_changes_[CAPTURE_INSTANCE]
            cdc.fn_cdc_get_net_changes_[CAPTURE_INSTANCE]
            (@from_lsn,
             @to_lsn,
             'all');
    END
END
