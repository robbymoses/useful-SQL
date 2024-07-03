/***************************************************************************************************
Author:             Robert Moses
Description:        Check to see if a specific column has changed for CDC Table. This can also be used
                    from the pre-built fn_get_*_changes.
***************************************************************************************************/

BEGIN
    DECLARE
        @column_ordinal int,
        @capture_instance VARCHAR(255) = '[captureInstance]',
        @column_name VARCHAR(128) = '[columnName]';

    SET @column_ordinal = sys.fn_cdc_get_column_ordinal( @capture_instance,@column_name)

    SELECT sys.fn_cdc_is_bit_set(@column_ordinal, __$update_mask) as 'hasColumnChanged', *
    FROM cdc.[tableName]
END

