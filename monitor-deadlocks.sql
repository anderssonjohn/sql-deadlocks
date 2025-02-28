/*
DEADLOCK MONITORING SCRIPT
=========================

INSTRUCTIONS:
1. Run the deadlock example as instructed in 01-deadlock-example.sql
2. Open a third query window and run this script to verify deadlock status
3. This script can be run at any point during the deadlock example to see current status

WHAT IT SHOWS:
- Current blocking and waiting chains (who is blocking whom)
- Deadlock detection from system health session
- Recent deadlocks that have occurred
*/

-- Use the Deadlocks database
USE Deadlocks;
GO

-- 1. Check for current blocking sessions (run this while transactions are in progress)
SELECT
    -- Blocking session
    blocking.session_id AS blocking_session_id,
    blocking_exec.text AS blocking_command,
    -- Blocked session
    blocked.session_id AS blocked_session_id,
    blocked_exec.text AS blocked_command,
    -- Wait info
    blocked.wait_type,
    blocked.wait_time / 1000.0 AS wait_time_seconds,
    -- Resource info
    DB_NAME(blocked.database_id) AS database_name,
    OBJECT_NAME(obj.object_id) AS blocked_object_name,
    obj.type_desc AS object_type
FROM
    sys.dm_exec_requests blocked
    JOIN sys.dm_exec_sessions blocking ON blocking.session_id = blocked.blocking_session_id
    OUTER APPLY sys.dm_exec_sql_text(blocked.sql_handle) blocked_exec
    OUTER APPLY sys.dm_exec_sql_text(blocking.most_recent_sql_handle) blocking_exec
    LEFT JOIN sys.partitions p ON p.hobt_id = blocked.resource_associated_entity_id
    LEFT JOIN sys.objects obj ON obj.object_id = p.object_id
WHERE
    blocked.blocking_session_id <> 0
ORDER BY
    wait_time_seconds DESC;

-- 2. View wait types that suggest deadlock (run this while transactions are in progress)
SELECT
    session_id,
    wait_type,
    wait_time / 1000.0 AS wait_time_seconds,
    command,
    DB_NAME(database_id) AS database_name,
    last_wait_type,
    wait_resource,
    status
FROM
    sys.dm_exec_requests
WHERE
    wait_type LIKE 'LCK%' OR wait_type = 'DEADLOCK_GRAPH'
ORDER BY
    wait_time_seconds DESC;

-- 3. Check if deadlocks have been recorded (run this after deadlock should have occurred)
;WITH deadlock_xml AS (
    SELECT
        CAST(target_data AS XML) AS xml_data
    FROM
        sys.dm_xe_session_targets t
        JOIN sys.dm_xe_sessions s ON t.event_session_address = s.address
    WHERE
        s.name = 'system_health'
        AND t.target_name = 'ring_buffer'
)
SELECT
    xml_data.value('(/event/@timestamp)[1]', 'datetime') AS deadlock_time,
    xml_data.query('(/event/data/value/deadlock)[1]') AS deadlock_graph
FROM
    deadlock_xml
CROSS APPLY
    xml_data.nodes('/RingBufferTarget/event[@name="xml_deadlock_report"]') AS XEventData(xml_data)
ORDER BY
    deadlock_time DESC;

-- 4. Display current lock information (run while transactions are active)
SELECT
    request_session_id AS session_id,
    resource_type,
    resource_database_id,
    DB_NAME(resource_database_id) AS database_name,
    OBJECT_NAME(resource_associated_entity_id) AS object_name,
    resource_description,
    request_mode,
    request_status,
    request_owner_type
FROM
    sys.dm_tran_locks
WHERE
    resource_database_id = DB_ID('Deadlocks') AND
    resource_type <> 'DATABASE'
ORDER BY
    request_session_id,
    resource_type;