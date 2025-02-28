/*
LOCK ESCALATION EXAMPLE
======================

INSTRUCTIONS:
1. Open two separate query windows in SSMS
2. Copy Transaction 1 code to the first window
3. Copy Transaction 2 code to the second window
4. Execute Transaction 1 (which starts updating many rows)
5. While Transaction 1 is running, execute Transaction 2
6. Observe that Transaction 2 is blocked

WHAT'S HAPPENING:
- Transaction 1 updates many rows in the Products table
- SQL Server escalates the lock from row-level to table-level
- Transaction 2 attempts to update a single row but is blocked by the table lock
- This demonstrates how lock escalation can affect concurrency
*/

-- Use the Deadlocks database
USE Deadlocks;
GO

-- Create a stored procedure to add more products for this test
CREATE OR ALTER PROCEDURE dbo.AddManyProducts
AS
BEGIN
    DECLARE @i INT = 1;
    DECLARE @name NVARCHAR(100);

    -- First delete any previously added test products
    DELETE FROM Products WHERE Name LIKE 'Test Product %';

    -- Add 1000 test products
    WHILE @i <= 100000
    BEGIN
        SET @name = 'Test Product ' + CAST(@i AS NVARCHAR(1000));

        INSERT INTO Products (Name, Description, Price, StockLevel, CategoryId)
        VALUES (@name, 'Test product for lock escalation demo', 10.99, 100, 1);

        SET @i = @i + 1;
    END;

    SELECT 'Added 100000 test products' AS [Status];
END;
GO

-- Run this to add test products (only needs to be done once)
EXEC dbo.AddManyProducts;
GO

-- TRANSACTION 1: Run in first query window
-- This transaction updates many rows, causing lock escalation
SELECT 'Starting Transaction 1 - updating many rows...' AS [Status];
BEGIN TRANSACTION;
    -- Update a large number of rows to trigger lock escalation
    UPDATE Products
    SET StockLevel = StockLevel + 1
    WHERE Name LIKE 'Test Product %';

    -- Pause to allow time to run Transaction 2
    WAITFOR DELAY '00:00:15';

    -- Complete the transaction
    SELECT 'Transaction 1 completed' AS [Status];
COMMIT TRANSACTION;
GO

-- TRANSACTION 2: Run in second query window while Transaction 1 is running
-- This transaction tries to update a single row and gets blocked
SELECT 'Starting Transaction 2 - updating one row...' AS [Status];
BEGIN TRANSACTION;
    -- Try to update a single product
    -- This will be blocked if Transaction 1 has a table lock
    UPDATE Products
    SET Description = 'Updated description'
    WHERE Id = 1;

    -- If we get here without waiting, no table lock was present
    SELECT 'Transaction 2 completed immediately' AS [Status];
COMMIT TRANSACTION;
GO

-- Clean up test data when done with the example
-- DELETE FROM Products WHERE Name LIKE 'Test Product %';
-- GO

/*
EXPECTED OUTCOME:
1. Transaction 1 starts updating many rows
2. SQL Server escalates row locks to a table lock
3. When Transaction 2 runs, it's blocked until Transaction 1 completes
4. After Transaction 1 completes (after ~15 seconds), Transaction 2 will complete

EXPLANATION:
SQL Server starts by taking row-level locks, but when a transaction modifies many
rows in a table (threshold can vary), it escalates to a table lock for efficiency.
This improves performance for the large update but reduces concurrency by blocking
other transactions from modifying any part of the table.
*/