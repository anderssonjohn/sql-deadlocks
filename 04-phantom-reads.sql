/*
PHANTOM READS EXAMPLE
====================

INSTRUCTIONS:
1. Open two separate query windows in SSMS
2. Copy Transaction 1 code to the first window
3. Copy Transaction 2 code to the second window
4. Execute Transaction 1 up to the first marked comment
5. Execute Transaction 2 up to its marked comment
6. Execute the middle part of Transaction 1 (which inserts a new product)
7. Execute the rest of Transaction 2
8. Execute the rest of Transaction 1
9. Repeat the whole process but with SERIALIZABLE isolation level in Transaction 2

WHAT'S HAPPENING:
- Transaction 2 runs a query that returns a set of rows
- Transaction 1 inserts a new row that would match Transaction 2's query
- Transaction 2 runs the same query again
- With REPEATABLE READ, the second query has an additional row (a "phantom")
- With SERIALIZABLE, the second query returns the same set as the first
*/

-- Use the Deadlocks database
USE Deadlocks;
GO

-- TRANSACTION 1: Run in first query window
BEGIN TRANSACTION;
    -- Show furniture products
    SELECT Id, Name, Price, CategoryId
    FROM Products
    WHERE CategoryId = 3;

    -- STOP HERE IN TRANSACTION 1, RUN TRANSACTION 2 UP TO ITS MARKED POINT

    -- Insert a new furniture product
    INSERT INTO Products (Name, Description, Price, StockLevel, CategoryId)
    VALUES ('Executive Desk', 'Premium office desk with drawers', 799.99, 5, 3);

    -- Show furniture products after insert
    SELECT Id, Name, Price, CategoryId
    FROM Products
    WHERE CategoryId = 3;

    -- Commit the change
    COMMIT TRANSACTION;
GO

-- TRANSACTION 2 (REPEATABLE READ): Run in second query window
-- First try with REPEATABLE READ
SELECT 'REPEATABLE READ Isolation Level' AS [Isolation Level];
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
    -- First read - count and list furniture products
    SELECT COUNT(*) AS FurnitureCount FROM Products WHERE CategoryId = 3;
    SELECT Id, Name, Price FROM Products WHERE CategoryId = 3;

    -- STOP HERE IN TRANSACTION 2, CONTINUE WITH TRANSACTION 1, THEN CONTINUE HERE

    -- Wait a moment to ensure Transaction 1 completes
    WAITFOR DELAY '00:00:02';

    -- Second read - with REPEATABLE READ, new rows can appear (phantoms)
    SELECT COUNT(*) AS FurnitureCount FROM Products WHERE CategoryId = 3;
    SELECT Id, Name, Price FROM Products WHERE CategoryId = 3;
COMMIT TRANSACTION;
GO

-- DELETE THE NEW PRODUCT (run this between tests)
DELETE FROM Products WHERE Name = 'Executive Desk';
GO

-- TRANSACTION 2 (SERIALIZABLE): Run in second query window after deleting
-- Now try with SERIALIZABLE
SELECT 'SERIALIZABLE Isolation Level' AS [Isolation Level];
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;
    -- First read - count and list furniture products
    SELECT COUNT(*) AS FurnitureCount FROM Products WHERE CategoryId = 3;
    SELECT Id, Name, Price FROM Products WHERE CategoryId = 3;

    -- STOP HERE IN TRANSACTION 2, CONTINUE WITH TRANSACTION 1, THEN CONTINUE HERE

    -- Wait a moment to ensure Transaction 1 tries to complete
    WAITFOR DELAY '00:00:02';

    -- Second read - with SERIALIZABLE, still the same count (no phantoms)
    SELECT COUNT(*) AS FurnitureCount FROM Products WHERE CategoryId = 3;
    SELECT Id, Name, Price FROM Products WHERE CategoryId = 3;
COMMIT TRANSACTION;

-- Reset isolation level
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO

/*
EXPECTED OUTCOME:
1. With REPEATABLE READ:
   - First read: 2 furniture products (Chair and Desk)
   - Second read: 3 furniture products (Chair, Desk, and Executive Desk)
   - Phantom read occurs!

2. With SERIALIZABLE:
   - First read: 2 furniture products (Chair and Desk)
   - Second read: Still 2 furniture products (Chair and Desk)
   - No phantom read
   - Transaction 1 may be blocked until Transaction 2 completes

This demonstrates how SERIALIZABLE prevents the phantom read phenomenon by acquiring
range locks that prevent other transactions from inserting rows that would match
the query conditions.
*/