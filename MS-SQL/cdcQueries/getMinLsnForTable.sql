/***************************************************************************************************
Author:             Robert Moses
Description:        Get the Starting LSN of a Table, also includes a mapping from LSN to time.
***************************************************************************************************/

BEGIN
    DECLARE
        @captureInstance VARCHAR(255) = '[captureInstance]';

    SELECT sys.fn_cdc_get_min_lsn ( @captureInstance),
           sys.fn_cdc_map_lsn_to_time(sys.fn_cdc_get_min_lsn ( @captureInstance)) as lsn_time
END