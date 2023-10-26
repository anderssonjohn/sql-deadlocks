set transaction isolation level repeatable read
begin transaction

select * from Users where Name = 'John'
waitfor delay '00:00:05'

update Users set Name = 'John123' where Name = 'John'

rollback;