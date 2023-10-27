begin transaction;

create database Test
use Test

create table Organizations
(
    Id   int not null identity primary key,
    Name nvarchar(max),
)

insert into Organizations
(Name)
values ('Omegapoint'),
       ('Volvo')

create table Branches
(
    Id             int not null identity primary key,
    OrganizationId int not null,
    Location       nvarchar(max),
    FOREIGN KEY (OrganizationId) REFERENCES Organizations (Id),
)

insert into Branches (Location, OrganizationId)
values (N'Göteborg', 1),
       ('Stockholm', 1),
       (N'Malmö', 1),
       ('Torslanda', 2),
       ('Arendal', 2)

create TABLE Users
(
    Id             int not null identity primary key,
    Name           nvarchar(max),
    OrganizationId int,
    FOREIGN KEY (OrganizationId) REFERENCES Organizations (Id)
)

create table UserBranches
(
    UserId   int not null,
    BranchId int not null,
    FOREIGN KEY (UserId) REFERENCES Users (Id),
    FOREIGN KEY (BranchId) REFERENCES Branches (Id)
)

insert into Users (Name, OrganizationId)
values (N'Användare 1', 1),
       (N'Användare 2', 2),
       ('John', null),
       ('Pontus 1', 1),
       ('Pontus 2', 1),
       ('Pontus 3', 1),
       ('Pontus 4', 1)


select *
from Users;
