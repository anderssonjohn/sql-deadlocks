set transaction isolation level repeatable read
begin transaction

select * from Users where Name = 'John'
waitfor delay '00:00:05'

update Users set Name = 'John123' where Name = 'John'

rollback ;

-- NEW SESSION BELOW

set transaction isolation level repeatable read
begin transaction

select * from Users where Name = 'Pontus 1'
waitfor delay '00:00:05'

update Users set Name = 'Pontus 1234' where Name = 'Pontus 1'

rollback;