-- SIMPLE DEADLOCK MONITORING SCRIPT
-- Use simpler queries that are less likely to get blocked

-- Use the Deadlocks database
USE Deadlocks;
GO

-- 1. Simplest query to check if sessions are blocking each other
SELECT
    session_id,
    blocking_session_id,
    wait_type,
    wait_time/1000.0 AS wait_time_seconds,
    status
FROM
    sys.dm_exec_requests
WHERE
    blocking_session_id <> 0
    OR session_id IN (SELECT blocking_session_id FROM sys.dm_exec_requests WHERE blocking_session_id <> 0);

-- 2. List active sessions without complex joins
SELECT
    session_id,
    login_time,
    host_name,
    program_name,
    login_name,
    status,
    cpu_time,
    memory_usage,
    last_request_start_time,
    last_request_end_time
FROM
    sys.dm_exec_sessions
WHERE
    is_user_process = 1
ORDER BY
    session_id;

-- 3. Simple lock information query
SELECT
    request_session_id,
    resource_type,
    resource_description,
    request_mode,
    request_status
FROM
    sys.dm_tran_locks
WHERE
    resource_database_id = DB_ID('Deadlocks');

-- 4. After deadlock occurs, check error log for deadlock info
EXEC sp_readerrorlog 0, 1, 'deadlock';

-- 5. Simple query to find deadlock details in the system health session
-- (This one is the most likely to work reliably after a deadlock has occurred)
SELECT TOP 3
    CAST(target_data as XML).value('(/RingBufferTarget/event/@timestamp)[1]', 'datetime2') AS deadlock_time
FROM
    sys.dm_xe_session_targets t
    JOIN sys.dm_xe_sessions s ON t.event_session_address = s.address
WHERE
    s.name = 'system_health'
    AND t.target_name = 'ring_buffer';

-- 6. Simple query to find active transactions
SELECT
    session_id,
    transaction_id,
    database_id,
    DB_NAME(database_id) as database_name,
    status
FROM
    sys.dm_tran_active_transactions t
    JOIN sys.dm_tran_session_transactions s ON t.transaction_id = s.transaction_id;