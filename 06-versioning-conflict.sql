/*
OPTIMISTIC CONCURRENCY CONTROL EXAMPLE
====================================

INSTRUCTIONS:
1. Open two separate query windows in SSMS
2. Copy Application 1 code to the first window
3. Copy Application 2 code to the second window
4. Execute Application 1 up to the marked comment
5. Execute Application 2 up to its marked comment
6. Execute the rest of Application 1 (which updates and commits)
7. Execute the rest of Application 2 (which tries to update the same row)
8. Observe that Application 2 detects the conflict

WHAT'S HAPPENING:
This simulates two application processes that use optimistic concurrency control:
- Both applications read the same record
- Each remembers the original values
- When updating, each checks if the data has changed since it was read
- The second update fails because the data was changed by the first update
*/

-- Use the Deadlocks database
USE Deadlocks;
GO

-- First, let's add a timestamp column to Products for tracking changes
-- Only run this once
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE name = 'RowVersion' AND object_id = OBJECT_ID('Products')
)
BEGIN
    ALTER TABLE Products ADD RowVersion ROWVERSION;
    SELECT 'Added RowVersion column to Products table' AS [Status];
END
GO

-- APPLICATION 1: Run in first query window
-- This represents an application process that reads then updates a product
DECLARE @ProductId INT = 1;
DECLARE @OriginalPrice DECIMAL(10, 2);
DECLARE @OriginalVersion BINARY(8);

-- Read the current product data
SELECT
    Id,
    Name,
    Price AS CurrentPrice,
    RowVersion
FROM
    Products
WHERE
    Id = @ProductId;

-- Store original values
SELECT
    @OriginalPrice = Price,
    @OriginalVersion = RowVersion
FROM
    Products
WHERE
    Id = @ProductId;

-- STOP HERE IN APPLICATION 1, RUN APPLICATION 2 UP TO ITS MARKED POINT

-- Now update the product (this would happen after some application processing)
BEGIN TRANSACTION;
    -- Check if data has changed since we read it
    IF EXISTS (
        SELECT 1 FROM Products
        WHERE Id = @ProductId AND RowVersion = @OriginalVersion
    )
    BEGIN
        -- Data hasn't changed, safe to update
        UPDATE Products
        SET Price = @OriginalPrice * 1.10  -- 10% price increase
        WHERE Id = @ProductId AND RowVersion = @OriginalVersion;

        IF @@ROWCOUNT = 1
            SELECT 'Application 1: Update successful' AS [Status];
        ELSE
            SELECT 'Application 1: Update failed, data was modified' AS [Status];
    END
    ELSE
    BEGIN
        -- Data has changed, can't safely update
        SELECT 'Application 1: Update failed, data was modified' AS [Status];
    END
COMMIT TRANSACTION;

-- Verify the current data
SELECT
    Id,
    Name,
    Price AS NewPrice,
    RowVersion
FROM
    Products
WHERE
    Id = @ProductId;
GO

-- APPLICATION 2: Run in second query window
-- This represents another application process that tries to update the same product
DECLARE @ProductId INT = 1;
DECLARE @OriginalPrice DECIMAL(10, 2);
DECLARE @OriginalVersion BINARY(8);

-- Read the current product data
SELECT
    Id,
    Name,
    Price AS CurrentPrice,
    RowVersion
FROM
    Products
WHERE
    Id = @ProductId;

-- Store original values
SELECT
    @OriginalPrice = Price,
    @OriginalVersion = RowVersion
FROM
    Products
WHERE
    Id = @ProductId;

-- STOP HERE IN APPLICATION 2, CONTINUE WITH APPLICATION 1, THEN CONTINUE HERE

-- Now try to update the product (after Application 1 has already updated it)
BEGIN TRANSACTION;
    -- Check if data has changed since we read it
    IF EXISTS (
        SELECT 1 FROM Products
        WHERE Id = @ProductId AND RowVersion = @OriginalVersion
    )
    BEGIN
        -- Data hasn't changed, safe to update
        UPDATE Products
        SET Price = @OriginalPrice * 0.90  -- 10% price decrease
        WHERE Id = @ProductId AND RowVersion = @OriginalVersion;

        IF @@ROWCOUNT = 1
            SELECT 'Application 2: Update successful' AS [Status];
        ELSE
            SELECT 'Application 2: Update failed, data was modified' AS [Status];
    END
    ELSE
    BEGIN
        -- Data has changed, can't safely update
        SELECT 'Application 2: Update failed, data was modified' AS [Status];

        -- Show current data to see what changed
        SELECT
            Id,
            Name,
            Price AS CurrentPrice,
            RowVersion AS CurrentVersion,
            @OriginalPrice AS OriginalPrice,
            @OriginalVersion AS OriginalVersion
        FROM
            Products
        WHERE
            Id = @ProductId;
    END
COMMIT TRANSACTION;
GO

/*
EXPECTED OUTCOME:
1. Application 1 reads the product and its version
2. Application 2 reads the same product and its version
3. Application 1 updates the product (increasing price by 10%) - SUCCEEDS
4. Application 2 tries to update the product but fails because the RowVersion has changed

EXPLANATION:
The ROWVERSION column in SQL Server automatically updates whenever a row is modified.
By checking the version before updating, applications can detect if another process
has changed the data since it was read. This is known as optimistic concurrency control
because it assumes conflicts are rare, and only checks for them at update time rather
than locking data during the entire process.
*/