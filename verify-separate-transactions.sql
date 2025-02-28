/*
CONNECTION ISOLATION TEST
========================

INSTRUCTIONS:
1. Open two separate query windows in Rider
2. Copy "Connection 1" code to the first window
3. Copy "Connection 2" code to the second window
4. Execute Connection 1 up to the marked comment
5. Execute Connection 2
6. If Connection 2 is blocked (waiting), then the windows are using separate connections
7. Complete Connection 1 to release the block
8. Connection 2 should then complete

WHAT'S HAPPENING:
- Connection 1 begins a transaction and locks a row
- Connection 2 tries to access the same row
- If using separate connections, Connection 2 will be blocked until Connection 1 commits
- If using the same connection, Connection 2 would fail or wait for Connection 1
*/

-- Use the Deadlocks database
USE Deadlocks;
GO

-- CONNECTION 1: Run in first query window
BEGIN TRANSACTION;
    -- Print connection ID
    SELECT 'Connection 1 with SPID: ' + CAST(@@SPID AS VARCHAR(10)) AS ConnectionInfo;

    -- Get original price
    SELECT Id, Name, Price FROM Products WHERE Id = 1;

    -- Update price - this acquires a lock
    UPDATE Products
    SET Price = Price * 1.01  -- 1% increase
    WHERE Id = 1;

    -- Verify change
    SELECT Id, Name, Price FROM Products WHERE Id = 1;

    -- STOP HERE IN CONNECTION 1, RUN CONNECTION 2, THEN CONTINUE

    -- Wait 10 seconds to allow testing Connection 2
    WAITFOR DELAY '00:00:10';

    -- Commit to release the lock
    COMMIT TRANSACTION;

    -- Verify final price
    SELECT Id, Name, Price FROM Products WHERE Id = 1;

    -- Reset the price (if desired)
    UPDATE Products SET Price = 1499.99 WHERE Id = 1;
GO

-- CONNECTION 2: Run in second query window
-- This will be blocked if using a separate connection
BEGIN TRANSACTION;
    -- Print connection ID
    SELECT 'Connection 2 with SPID: ' + CAST(@@SPID AS VARCHAR(10)) AS ConnectionInfo;

    -- Try to update the same row - should be blocked if using separate connections
    -- If this executes immediately, the connections are not separate
    UPDATE Products
    SET Price = Price * 0.99  -- 1% decrease
    WHERE Id = 1;

    -- This will only print once Connection 1 commits and releases its lock
    SELECT 'Connection 2 successfully executed' AS Status;

    -- Verify the change (will reflect BOTH updates if separate connections)
    SELECT Id, Name, Price FROM Products WHERE Id = 1;

    -- Rollback our change
    ROLLBACK TRANSACTION;
GO

/*
EXPECTED OUTCOME:
1. Connection 1 will execute and wait at the marked point
2. Connection 2 will appear to hang if separate connections are being used
3. After 10 seconds, Connection 1 will complete
4. Connection 2 will then complete after Connection 1 releases its lock

If Connection 2 completes immediately without waiting, the windows are likely
using the same connection, which won't work for demonstrating deadlocks.
*/