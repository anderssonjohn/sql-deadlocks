# SQL Server Deadlocks and Concurrency Workshop

This repository contains a database schema and several SQL scripts designed to demonstrate SQL Server concurrency issues, deadlocks, and isolation levels for educational purposes.

## Getting Started

### Prerequisites

- SQL Server (2016 or newer)
- SQL Server Management Studio (SSMS) or Azure Data Studio

### Setup

1. Clone this repository
2. Run the `create-database.sql` script to create the sample database and populate it with data
3. Review the example scripts and run them following the instructions inside each file

## Workshop Overview

This workshop covers the following concurrency topics:

1. **Deadlocks** - When two transactions block each other
2. **Transaction Isolation Levels** - Various isolation levels and their effects:
   - READ UNCOMMITTED
   - READ COMMITTED
   - REPEATABLE READ
   - SERIALIZABLE
3. **Concurrency Phenomena**:
   - Dirty reads
   - Non-repeatable reads
   - Phantom reads
4. **Lock Escalation** - How row-level locks can escalate to table-level locks
5. **Optimistic Concurrency Control** - Using row versioning to detect conflicts

## Example Scripts

### 01-deadlock-example.sql

Demonstrates a classic deadlock scenario where two transactions acquire locks in different orders.

### 02-dirty-reads.sql

Shows how READ UNCOMMITTED isolation level can lead to reading uncommitted data that might be rolled back.

### 03-non-repeatable-reads.sql

Compares READ COMMITTED with REPEATABLE READ to show how the latter prevents data from changing during a transaction.

### 04-phantom-reads.sql

Compares REPEATABLE READ with SERIALIZABLE to show how the latter prevents new rows from appearing in result sets.

### 05-lock-escalation.sql

Shows how SQL Server can escalate from row-level locks to table-level locks when many rows are affected.

### 06-versioning-conflict.sql

Demonstrates optimistic concurrency control using SQL Server's ROWVERSION feature.

## Database Schema

The sample database contains the following main tables:

1. **Organizations** - Companies in the system
2. **Branches** - Physical locations belonging to organizations
3. **Users** - People who use the system
4. **Products** - Items that can be ordered
5. **Categories** - Product categories
6. **Orders** - Orders placed by users
7. **OrderItems** - Line items within orders
8. **Inventory** - Stock level changes for products
9. **AuditLogs** - Record of changes to the database

## Best Practices

When designing applications to handle concurrency, consider these best practices:

1. Keep transactions as short as possible
2. Access objects in the same order across all transactions
3. Use appropriate isolation levels for your needs
4. Consider optimistic concurrency for low-contention scenarios
5. Use snapshot isolation for reporting queries
6. Be aware of lock escalation thresholds
7. Implement retry logic for deadlock victims
8. Monitor for deadlocks using SQL Server's deadlock graph

## Further Reading

- [SQL Server Transaction Locking and Row Versioning Guide](https://docs.microsoft.com/en-us/sql/relational-databases/sql-server-transaction-locking-and-row-versioning-guide)
- [Understanding and resolving SQL Server deadlocks](https://docs.microsoft.com/en-us/sql/relational-databases/understand-and-resolve-sql-server-blocking)
- [Transaction Isolation Levels](https://docs.microsoft.com/en-us/sql/t-sql/statements/set-transaction-isolation-level-transact-sql)

Connectionsträng
`jdbc:sqlserver://localhost:1434;user=sa;password=secure_password123`

### Läsning

https://learn.microsoft.com/en-us/sql/relational-databases/sql-server-transaction-locking-and-row-versioning-guide
