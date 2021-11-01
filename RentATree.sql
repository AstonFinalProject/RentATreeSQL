drop database if exists RentATree;
create database if not exists RentATree;
use RentATree;

create table if not exists UserDetailsMaster(
	UserID int primary key auto_increment, -- Primary key
    Username varchar(30) not null, -- Needs to be unique
    Email varchar(80) not null, -- Needs to be unique, also add validation
    FName varchar(30) not null,
    LName varchar(30) not null,
    HouseNameOrNumber varchar(30) not null,
    StreetName varchar(30) not null,
    Postcode varchar(7) not null, -- Add validation
    TelephoneNo char(11) not null, -- Add validation
    Password varchar(30) not null,
    constraint uq_username unique(Username),
    constraint uq_email unique(Email),
    constraint ck_emailvalidation check (Email like '_%@_%.com'),
    constraint ck_postcodevalidation check (Postcode rlike '[A-Z][A-Z][0-9][0-9][0-9][A-Z][A-Z]' or Postcode rlike '[A-Z][A-Z][0-9][0-9][A-Z][A-Z]'),
    constraint ck_phonenovalidation check (TelephoneNo rlike '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
);

delimiter /
create procedure createNewUser(
	in p_Username varchar(30),
    in p_Email varchar(80),
    in p_FName varchar(30),
    in p_LName varchar(30),
    in p_HouseNameOrNumber varchar(30),
    in p_StreetName varchar(30),
    in p_Postcode varchar(7),
    in p_TelephoneNo char(11),
    in p_Password varchar(30)
)
begin
	insert into UserDetailsMaster(Username,Email,FName,LName,HouseNameOrNumber,StreetName,Postcode,TelephoneNo,Password) 
		values (p_Username,p_Email,p_FName,p_LName,p_HouseNameOrNumber,p_StreetName,p_Postcode,p_TelephoneNo,p_Password);
end;
/

create procedure login(
	in p_Username varchar(30),
    in p_Password varchar(30),
    out p_Result boolean
)
begin
	declare Password_Login varchar(30);
    set Password_Login = (select (UserDetailsMaster.Password) from UserDetailsMaster where UserDetailsMaster.Username = p_Username);
	if Password_Login = p_Password then 
		set p_Result = 1;
	else 
		set p_Result = 0;
	end if;
end;
/