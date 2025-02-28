/*
NON-REPEATABLE READS EXAMPLE
===========================

INSTRUCTIONS:
1. Open two separate query windows in SSMS
2. Copy Transaction 1 code to the first window
3. Copy Transaction 2 code to the second window
4. Execute Transaction 1 up to the first marked comment
5. Execute Transaction 2 up to its marked comment
6. Execute the middle part of Transaction 1 (which updates the product)
7. Execute the rest of Transaction 2
8. Execute the rest of Transaction 1
9. Repeat the whole process but with REPEATABLE READ isolation level in Transaction 2

WHAT'S HAPPENING:
- Transaction 2 reads a product price
- Transaction 1 updates and commits that product price
- Transaction 2 reads the price again
- With READ COMMITTED, the two readings are different (non-repeatable)
- With REPEATABLE READ, the second reading is the same as the first
*/

-- Use the Deadlocks database
USE Deadlocks;
GO

-- TRANSACTION 1: Run in first query window
BEGIN TRANSACTION;
    -- Show original price
    SELECT Id, Name, Price FROM Products WHERE Id = 3;

    -- STOP HERE IN TRANSACTION 1, RUN TRANSACTION 2 UP TO ITS MARKED POINT

    -- Update the price
    UPDATE Products
    SET Price = 349.99
    WHERE Id = 3;

    -- Show the updated price
    SELECT Id, Name, Price FROM Products WHERE Id = 3;

    -- Commit the change
    COMMIT TRANSACTION;

    -- Verify the price is updated
    SELECT Id, Name, Price FROM Products WHERE Id = 3;
GO

-- TRANSACTION 2 (READ COMMITTED): Run in second query window
-- First try with READ COMMITTED (default)
SELECT 'READ COMMITTED Isolation Level' AS [Isolation Level];
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;
    -- First read
    SELECT GETDATE() AS [Time], 'First Read' AS [Read], Id, Name, Price
    FROM Products WHERE Id = 3;

    -- STOP HERE IN TRANSACTION 2, CONTINUE WITH TRANSACTION 1, THEN CONTINUE HERE

    -- Wait a moment to ensure Transaction 1 completes
    WAITFOR DELAY '00:00:02';

    -- Second read - may be different from first read with READ COMMITTED
    SELECT GETDATE() AS [Time], 'Second Read' AS [Read], Id, Name, Price
    FROM Products WHERE Id = 3;
COMMIT TRANSACTION;
GO

-- RESET THE PRODUCT PRICE (run this between tests)
UPDATE Products SET Price = 299.99 WHERE Id = 3;
GO

-- TRANSACTION 2 (REPEATABLE READ): Run in second query window after resetting
-- Now try with REPEATABLE READ
SELECT 'REPEATABLE READ Isolation Level' AS [Isolation Level];
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
    -- First read
    SELECT GETDATE() AS [Time], 'First Read' AS [Read], Id, Name, Price
    FROM Products WHERE Id = 3;

    -- STOP HERE IN TRANSACTION 2, CONTINUE WITH TRANSACTION 1, THEN CONTINUE HERE

    -- Wait a moment to ensure Transaction 1 completes
    WAITFOR DELAY '00:00:02';

    -- Second read - should be same as first read with REPEATABLE READ
    SELECT GETDATE() AS [Time], 'Second Read' AS [Read], Id, Name, Price
    FROM Products WHERE Id = 3;
COMMIT TRANSACTION;

-- Reset isolation level
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO

/*
EXPECTED OUTCOME:
1. With READ COMMITTED:
   - First read: Original price (299.99)
   - Second read: Updated price (349.99)
   - The read is not repeatable!

2. With REPEATABLE READ:
   - First read: Original price (299.99)
   - Second read: Still original price (299.99) even though another transaction changed it
   - The read is repeatable!

This demonstrates how REPEATABLE READ prevents the non-repeatable read phenomenon by
holding shared locks until the transaction completes, preventing other transactions
from modifying the data.
*/