/*
DIRTY READS EXAMPLE
==================

INSTRUCTIONS:
1. Open two separate query windows in SSMS
2. Copy Transaction 1 code to the first window
3. Copy Transaction 2 code to the second window
4. Execute Transaction 1 up to the marked comment
5. Execute all of Transaction 2
6. Execute the rest of Transaction 1
7. Observe the results in Transaction 2

WHAT'S HAPPENING:
- Transaction 1 updates a product price but doesn't commit
- Transaction 2 reads the uncommitted data using READ UNCOMMITTED isolation level
- Transaction 1 then rolls back the change
- Result: Transaction 2 used data that was never committed (a "dirty read")
*/

-- Use the Deadlocks database
USE Deadlocks;
GO

-- TRANSACTION 1: Run in first query window
BEGIN TRANSACTION;
    -- Show original price
    SELECT Id, Name, Price FROM Products WHERE Id = 2;

    -- Update the price - THIS CHANGE IS NOT YET COMMITTED
    UPDATE Products
    SET Price = 199.99
    WHERE Id = 2;

    -- Show the updated price
    SELECT Id, Name, Price FROM Products WHERE Id = 2;

    -- STOP HERE IN TRANSACTION 1, RUN ALL OF TRANSACTION 2, THEN CONTINUE

    -- Now roll back the transaction (undo the changes)
    ROLLBACK TRANSACTION;

    -- Verify the price is back to original
    SELECT Id, Name, Price FROM Products WHERE Id = 2;
GO

-- TRANSACTION 2: Run in second query window
-- First with default isolation level (READ COMMITTED)
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT Id, Name, Price FROM Products WHERE Id = 2;

-- Then with READ UNCOMMITTED isolation level
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT Id, Name, Price FROM Products WHERE Id = 2;

GO

/*
EXPECTED OUTCOME:
1. Default isolation level (READ COMMITTED) will show the original price
2. READ UNCOMMITTED will show the "dirty" price (199.99) that was never committed
3. After Transaction 1 rolls back, the price will be back to original

This demonstrates the potential dangers of using READ UNCOMMITTED in applications
where data consistency is important. The READ UNCOMMITTED isolation level allowed
Transaction 2 to read data that was never actually committed to the database.
*/