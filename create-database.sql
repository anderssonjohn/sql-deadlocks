-- First create the database
CREATE DATABASE Deadlocks;
GO

-- Then use the database
USE Deadlocks;
GO

-- Now begin a transaction for creating tables and inserting data
BEGIN TRANSACTION;

CREATE TABLE Organizations
(
    Id   INT NOT NULL IDENTITY PRIMARY KEY,
    Name NVARCHAR(MAX)
);

INSERT INTO Organizations
(Name)
VALUES ('Our Studio'),
       ('Volvo');

CREATE TABLE Branches
(
    Id             INT NOT NULL IDENTITY PRIMARY KEY,
    OrganizationId INT NOT NULL,
    Location       NVARCHAR(MAX),
    FOREIGN KEY (OrganizationId) REFERENCES Organizations (Id)
);

INSERT INTO Branches (Location, OrganizationId)
VALUES (N'Göteborg', 1),
       ('Stockholm', 1),
       (N'Malmö', 1),
       ('Torslanda', 2),
       ('Arendal', 2);

CREATE TABLE Users
(
    Id             INT NOT NULL IDENTITY PRIMARY KEY,
    Name           NVARCHAR(MAX),
    OrganizationId INT,
    FOREIGN KEY (OrganizationId) REFERENCES Organizations (Id)
);

CREATE TABLE UserBranches
(
    UserId   INT NOT NULL,
    BranchId INT NOT NULL,
    FOREIGN KEY (UserId) REFERENCES Users (Id),
    FOREIGN KEY (BranchId) REFERENCES Branches (Id),
    PRIMARY KEY (UserId, BranchId)
);

INSERT INTO Users (Name, OrganizationId)
VALUES (N'Användare 1', 1),
       (N'Användare 2', 2),
       ('John', NULL),
       ('Pontus 1', 1),
       ('Pontus 2', 1),
       ('Pontus 3', 1),
       ('Pontus 4', 1);

-- Insert data into UserBranches
INSERT INTO UserBranches (UserId, BranchId)
VALUES (1, 1), -- Användare 1 works at Göteborg
       (1, 2), -- Användare 1 also works at Stockholm
       (2, 4), -- Användare 2 works at Torslanda
       (3, 1), -- John works at Göteborg
       (4, 1), -- Pontus 1 works at Göteborg
       (5, 2), -- Pontus 2 works at Stockholm
       (6, 3), -- Pontus 3 works at Malmö
       (7, 1); -- Pontus 4 works at Göteborg

-- Create Products table for inventory management
CREATE TABLE Products
(
    Id          INT NOT NULL IDENTITY PRIMARY KEY,
    Name        NVARCHAR(100) NOT NULL,
    Description NVARCHAR(MAX),
    Price       DECIMAL(10, 2) NOT NULL,
    StockLevel  INT NOT NULL DEFAULT 0,
    CategoryId  INT
);

-- Create Categories table
CREATE TABLE Categories
(
    Id   INT NOT NULL IDENTITY PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL
);

-- Add foreign key after table creation
ALTER TABLE Products
ADD CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryId) REFERENCES Categories (Id);

-- Insert data into Categories
INSERT INTO Categories (Name)
VALUES ('Electronics'),
       ('Office Supplies'),
       ('Furniture'),
       ('Books'),
       ('Software');

-- Insert data into Products
INSERT INTO Products (Name, Description, Price, StockLevel, CategoryId)
VALUES ('Laptop', 'High-performance laptop for developers', 1499.99, 25, 1),
       ('Mouse', 'Ergonomic wireless mouse', 59.99, 100, 1),
       ('Office Chair', 'Comfortable chair for long hours', 299.99, 15, 3),
       ('Desk', 'Standing desk with motor', 599.99, 10, 3),
       ('SQL Server Book', 'Advanced SQL Server techniques', 49.99, 30, 4),
       ('Whiteboard', 'Large whiteboard for meetings', 129.99, 5, 2),
       ('Project Management Software', 'Enterprise license', 999.99, 50, 5),
       ('Headphones', 'Noise-cancelling headphones', 249.99, 20, 1);

-- Create Orders table (prone to deadlocks)
CREATE TABLE Orders
(
    Id           INT NOT NULL IDENTITY PRIMARY KEY,
    UserId       INT NOT NULL,
    OrderDate    DATETIME NOT NULL DEFAULT GETDATE(),
    TotalAmount  DECIMAL(10, 2) NOT NULL,
    Status       NVARCHAR(20) NOT NULL DEFAULT 'Pending',
    BranchId     INT NOT NULL,
    FOREIGN KEY (UserId) REFERENCES Users (Id),
    FOREIGN KEY (BranchId) REFERENCES Branches (Id)
);

-- Create OrderItems table
CREATE TABLE OrderItems
(
    Id        INT NOT NULL IDENTITY PRIMARY KEY,
    OrderId   INT NOT NULL,
    ProductId INT NOT NULL,
    Quantity  INT NOT NULL,
    Price     DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (OrderId) REFERENCES Orders (Id),
    FOREIGN KEY (ProductId) REFERENCES Products (Id)
);

-- Insert data into Orders
INSERT INTO Orders (UserId, OrderDate, TotalAmount, Status, BranchId)
VALUES (1, DATEADD(day, -10, GETDATE()), 1559.98, 'Completed', 1),
       (2, DATEADD(day, -7, GETDATE()), 599.99, 'Shipped', 4),
       (3, DATEADD(day, -5, GETDATE()), 109.98, 'Completed', 1),
       (4, DATEADD(day, -3, GETDATE()), 1799.97, 'Processing', 1),
       (5, DATEADD(day, -2, GETDATE()), 249.99, 'Pending', 2),
       (6, DATEADD(day, -1, GETDATE()), 599.99, 'Pending', 3),
       (7, GETDATE(), 1249.98, 'Processing', 1);

-- Insert data into OrderItems
INSERT INTO OrderItems (OrderId, ProductId, Quantity, Price)
VALUES (1, 1, 1, 1499.99), -- Laptop for Användare 1
       (1, 2, 1, 59.99),   -- Mouse for Användare 1
       (2, 4, 1, 599.99),  -- Desk for Användare 2
       (3, 2, 1, 59.99),   -- Mouse for John
       (3, 5, 1, 49.99),   -- SQL Book for John
       (4, 1, 1, 1499.99), -- Laptop for Pontus 1
       (4, 6, 1, 129.99),  -- Whiteboard for Pontus 1
       (4, 5, 1, 49.99),   -- SQL Book for Pontus 1
       (5, 8, 1, 249.99),  -- Headphones for Pontus 2
       (6, 4, 1, 599.99),  -- Desk for Pontus 3
       (7, 3, 1, 299.99),  -- Chair for Pontus 4
       (7, 7, 1, 999.99);  -- Software for Pontus 4

-- Create Inventory table (for tracking stock history)
CREATE TABLE Inventory
(
    Id           INT NOT NULL IDENTITY PRIMARY KEY,
    ProductId    INT NOT NULL,
    ChangeDate   DATETIME NOT NULL DEFAULT GETDATE(),
    ChangeAmount INT NOT NULL,
    Reason       NVARCHAR(50) NOT NULL,
    UserId       INT NOT NULL,
    FOREIGN KEY (ProductId) REFERENCES Products (Id),
    FOREIGN KEY (UserId) REFERENCES Users (Id)
);

-- Insert some inventory changes
INSERT INTO Inventory (ProductId, ChangeDate, ChangeAmount, Reason, UserId)
VALUES (1, DATEADD(day, -30, GETDATE()), 30, 'Initial Stock', 1),
       (1, DATEADD(day, -10, GETDATE()), -1, 'Sale', 1),
       (1, DATEADD(day, -3, GETDATE()), -1, 'Sale', 4),
       (2, DATEADD(day, -30, GETDATE()), 120, 'Initial Stock', 1),
       (2, DATEADD(day, -10, GETDATE()), -1, 'Sale', 1),
       (2, DATEADD(day, -5, GETDATE()), -1, 'Sale', 3),
       (2, DATEADD(day, -1, GETDATE()), -18, 'Defective Return', 5),
       (3, DATEADD(day, -20, GETDATE()), 20, 'Initial Stock', 2),
       (3, DATEADD(day, -1, GETDATE()), -1, 'Sale', 7),
       (4, DATEADD(day, -20, GETDATE()), 15, 'Initial Stock', 2),
       (4, DATEADD(day, -7, GETDATE()), -1, 'Sale', 2),
       (4, DATEADD(day, -1, GETDATE()), -1, 'Sale', 6);

-- Create a table for audit logs
CREATE TABLE AuditLogs
(
    Id           INT NOT NULL IDENTITY PRIMARY KEY,
    TableName    NVARCHAR(50) NOT NULL,
    RecordId     INT NOT NULL,
    Action       NVARCHAR(10) NOT NULL, -- Insert, Update, Delete
    ChangedBy    INT NOT NULL,
    ChangedDate  DATETIME NOT NULL DEFAULT GETDATE(),
    OldValues    NVARCHAR(MAX),
    NewValues    NVARCHAR(MAX),
    FOREIGN KEY (ChangedBy) REFERENCES Users (Id)
);

-- Insert some sample audit logs
INSERT INTO AuditLogs (TableName, RecordId, Action, ChangedBy, ChangedDate, OldValues, NewValues)
VALUES ('Products', 1, 'Update', 1, DATEADD(day, -5, GETDATE()), '{"Price": 1399.99}', '{"Price": 1499.99}'),
       ('Products', 2, 'Update', 1, DATEADD(day, -5, GETDATE()), '{"Price": 49.99}', '{"Price": 59.99}'),
       ('Orders', 1, 'Update', 1, DATEADD(day, -9, GETDATE()), '{"Status": "Processing"}', '{"Status": "Shipped"}'),
       ('Orders', 1, 'Update', 1, DATEADD(day, -8, GETDATE()), '{"Status": "Shipped"}', '{"Status": "Completed"}'),
       ('Orders', 2, 'Update', 2, DATEADD(day, -5, GETDATE()), '{"Status": "Processing"}', '{"Status": "Shipped"}');

COMMIT TRANSACTION;

-- Query to view all Users
SELECT * FROM Users;

GO -- Add a GO statement here to start a new batch

-- Some useful views for the workshop

-- Create a view to see order details
CREATE OR ALTER VIEW vw_OrderDetails AS
SELECT
    o.Id AS OrderId,
    u.Name AS UserName,
    o.OrderDate,
    o.TotalAmount,
    o.Status,
    b.Location AS BranchLocation,
    p.Name AS ProductName,
    oi.Quantity,
    oi.Price AS UnitPrice,
    (oi.Quantity * oi.Price) AS ItemTotal
FROM
    Orders o
    JOIN Users u ON o.UserId = u.Id
    JOIN Branches b ON o.BranchId = b.Id
    JOIN OrderItems oi ON o.Id = oi.OrderId
    JOIN Products p ON oi.ProductId = p.Id;
GO

-- Create a view for inventory status
CREATE OR ALTER VIEW vw_InventoryStatus AS
SELECT
    p.Id AS ProductId,
    p.Name AS ProductName,
    p.StockLevel AS CurrentStock,
    c.Name AS Category,
    p.Price AS CurrentPrice,
    (SELECT SUM(ChangeAmount) FROM Inventory i WHERE i.ProductId = p.Id) AS TotalChanges,
    (SELECT MAX(ChangeDate) FROM Inventory i WHERE i.ProductId = p.Id) AS LastChanged
FROM
    Products p
    LEFT JOIN Categories c ON p.CategoryId = c.Id;
GO

-- Create a view for user activity
CREATE OR ALTER VIEW vw_UserActivity AS
SELECT
    u.Id AS UserId,
    u.Name AS UserName,
    o.Name AS OrganizationName,
    COUNT(DISTINCT ord.Id) AS OrdersPlaced,
    COUNT(DISTINCT inv.Id) AS InventoryChanges,
    COUNT(DISTINCT al.Id) AS AuditActions
FROM
    Users u
    LEFT JOIN Organizations o ON u.OrganizationId = o.Id
    LEFT JOIN Orders ord ON u.Id = ord.UserId
    LEFT JOIN Inventory inv ON u.Id = inv.UserId
    LEFT JOIN AuditLogs al ON u.Id = al.ChangedBy
GROUP BY
    u.Id, u.Name, o.Name;
GO
