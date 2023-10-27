set transaction isolation level read committed
begin transaction

select *
From Users
where Name = 'John'

select *
From Users
where Name = 'John'


rollback