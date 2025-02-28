/*
DEADLOCK EXAMPLE
================

INSTRUCTIONS:
1. Open two separate query windows in SSMS
2. Copy Transaction 1 code to the first window
3. Copy Transaction 2 code to the second window
4. Execute Transaction 1 up to the marked comment
5. Execute Transaction 2 up to the marked comment
6. Execute the rest of Transaction 1
7. Execute the rest of Transaction 2
8. One transaction will succeed, the other will fail with a deadlock error

WHAT'S HAPPENING:
Transaction 1 updates Product 1, then tries to update Order Item for Product 1
Transaction 2 updates Order Item for Product 1, then tries to update Product 1
Each transaction holds a lock that the other needs, causing a deadlock
*/

-- Use the Deadlocks database
USE Deadlocks;
GO

-- TRANSACTION 1: Run in first query window
BEGIN TRANSACTION;
    -- Get product info
    SELECT Id, Name, StockLevel, Price FROM Products WHERE Id = 1;

    -- Update product 1 stock level (acquires lock on Products table)
    UPDATE Products
    SET StockLevel = StockLevel - 1
    WHERE Id = 1;

    -- Simulate delay to ensure deadlock occurs
    WAITFOR DELAY '00:00:05';

    -- STOP HERE IN TRANSACTION 1, RUN TRANSACTION 2 UP TO THE MARKED POINT, THEN CONTINUE

    -- Now try to update OrderItems (needs lock on OrderItems)
    UPDATE OrderItems
    SET Quantity = Quantity + 1
    WHERE ProductId = 1 AND OrderId = 1;

    -- If we get here, the transaction succeeded
    SELECT 'Transaction 1 succeeded' AS [Status];
COMMIT TRANSACTION;
GO

-- TRANSACTION 2: Run in second query window
BEGIN TRANSACTION;
    -- Get order item info
    SELECT Id, OrderId, ProductId, Quantity FROM OrderItems
    WHERE ProductId = 1 AND OrderId = 1;

    -- Update order item (acquires lock on OrderItems table)
    UPDATE OrderItems
    SET Quantity = Quantity + 1
    WHERE ProductId = 1 AND OrderId = 1;

    -- Simulate delay to ensure deadlock occurs
    WAITFOR DELAY '00:00:05';

    -- STOP HERE IN TRANSACTION 2, THEN CONTINUE

    -- Now try to update Product (needs lock on Products)
    UPDATE Products
    SET StockLevel = StockLevel - 1
    WHERE Id = 1;

    -- If we get here, the transaction succeeded
    SELECT 'Transaction 2 succeeded' AS [Status];
COMMIT TRANSACTION;
GO

/*
EXPECTED OUTCOME:
One of the transactions will succeed with the message "Transaction X succeeded"
The other transaction will fail with an error similar to:
"Msg 1205, Level 13, State 56, Line XX
Transaction (Process ID XX) was deadlocked on lock resources with another process
and has been chosen as the deadlock victim. Rerun the transaction."

SQL Server automatically detects the deadlock and chooses one transaction as the "victim"
to be rolled back, allowing the other to proceed.
*/