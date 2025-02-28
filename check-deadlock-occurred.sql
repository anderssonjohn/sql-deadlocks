-- DEADLOCK VERIFICATION SCRIPT
-- Run this AFTER attempting a deadlock to see if it was recorded

-- Use the Deadlocks database
USE Deadlocks;
GO

-- Option 1: Simple query to see if deadlocks have been detected (last 3)
SELECT TOP 3
    CAST(target_data as XML).value('(/RingBufferTarget/event/@timestamp)[1]', 'datetime2') AS deadlock_time
FROM
    sys.dm_xe_session_targets t
    JOIN sys.dm_xe_sessions s ON t.event_session_address = s.address
WHERE
    s.name = 'system_health'
    AND t.target_name = 'ring_buffer'
    AND CAST(target_data as XML).value('(/RingBufferTarget/event/@name)[1]', 'varchar(50)') = 'xml_deadlock_report'
ORDER BY
    deadlock_time DESC;

-- Option 2: Query to see deadlock information (if deadlocks have occurred)
;WITH deadlock_events AS (
    SELECT
        event_data = CAST(target_data AS XML)
    FROM
        sys.dm_xe_session_targets t
        JOIN sys.dm_xe_sessions s ON t.event_session_address = s.address
    WHERE
        s.name = 'system_health'
        AND t.target_name = 'ring_buffer'
)
SELECT TOP 5
    event_time = event_data.value('(event/@timestamp)[1]', 'datetime2'),
    victim_spid = event_data.value('(event/data[@name="victim_session_id"]/value)[1]', 'int'),
    deadlock_graph = event_data.query('(event/data[@name="xml_report"]/value/deadlock)[1]')
FROM
    deadlock_events
CROSS APPLY
    event_data.nodes('RingBufferTarget/event[@name="xml_deadlock_report"]') AS nodes(event_data)
ORDER BY
    event_time DESC;