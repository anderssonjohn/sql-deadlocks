set transaction isolation level read uncommitted
begin transaction

select *
into #TempUsers
FROM Users

update Users
set OrganizationId = #TempUsers.OrganizationId,
    Name           = 'John 1234'
from #TempUsers
where Users.Name = 'John' and #TempUsers.Name = 'John'


-- Select above this line and execute
commit

select *
from Users
where Name = 'John 1234'


-- Run below in another session

begin transaction;

update Users
set OrganizationId = 2
where name = 'John'

rollback

select *
from Users
where Name = 'John'
