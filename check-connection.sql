-- Connection verification script
-- Run this in each query window to verify separate connections

-- Get the current session ID (SPID)
SELECT @@SPID AS 'Current Connection ID';

-- Get additional connection information
SELECT
    session_id,
    login_time,
    host_name,
    program_name,
    client_interface_name,
    login_name
FROM
    sys.dm_exec_sessions
WHERE
    session_id = @@SPID;

-- Optional: View all active connections to the database
SELECT
    session_id,
    login_time,
    host_name,
    program_name,
    client_interface_name,
    login_name
FROM
    sys.dm_exec_sessions
WHERE
    database_id = DB_ID('Deadlocks')
ORDER BY
    session_id;