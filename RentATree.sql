drop database if exists RentATree;
create database if not exists RentATree;
use RentATree;

create table if not exists UserDetailsMaster(
	UserID int primary key auto_increment, -- Primary key
    Username varchar(30) not null, 
    Email varchar(80) not null, 
    FName varchar(30) not null,
    LName varchar(30) not null,
    HouseNameOrNumber varchar(30) not null,
    StreetName varchar(30) not null,
    Postcode varchar(7) not null, 
    TelephoneNo char(11) not null, 
    Password varchar(30) not null,
    constraint uq_username unique(Username), -- Unique username
    constraint uq_email unique(Email), -- Unique email address
    constraint ck_emailvalidation check (Email like '_%@_%.com'), -- Email validation
    constraint ck_postcodevalidation check (Postcode rlike '[A-Z][A-Z][0-9][0-9][0-9][A-Z][A-Z]' or Postcode rlike '[A-Z][A-Z][0-9][0-9][A-Z][A-Z]'), -- Postcode validation
    constraint ck_phonenovalidation check (TelephoneNo rlike '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]') -- Telephone number validation
);

create table if not exists UserTransactionTable(
	FinalTransactionID int primary key auto_increment, -- Primary key
    UserID int not null, -- Foreign key from UserDetailsMaster
    TotalSum int default 0, 
    constraint fk_userID foreign key (UserID) references UserDetailsMaster (UserID) on delete cascade, -- Sets up foreign key and on delete cascade
    constraint ck_positivetotalsum check (TotalSum >= 0) -- Constraint to check total sum is greater than or equal to 0
);

create table if not exists TreeDescriptionMaster(
	TreeID int primary key auto_increment, -- Primary key
    TreeDescription varchar(50) not null,
    TreeType varchar(20) not null,
    TreeMaterial varchar(20) not null,
    Stock int not null default 0
);

create table if not exists TreeSupplierMaster(
	SupplierID int primary key auto_increment, -- Primary key
    SupplierName varchar(30)
);

create table if not exists ProductDescription(
	ProductID int primary key auto_increment, -- Primary key
    TreeID int not null, -- Foreign key from TreeDescriptionMaster
    SupplierID int not null, -- Foreign key from TreeSupplierMaster
    Height double not null, -- Height in centimeters as specified in the brief
    Price int not null, -- Price in pence right now as this is what was used in the sample code
    constraint fk_treeID foreign key (TreeID) references TreeDescriptionMaster (TreeID) on delete cascade, -- Sets up foreign key and on delete cascade
    constraint fk_supplierID foreign key (SupplierID) references TreeSupplierMaster (SupplierID) on delete cascade, -- Sets up foreign key and on delete cascade
    constraint ck_positiveheight check (Height > 0), -- Constraint to check that height is greater than 0
    constraint ck_positiveprice check (Price >= 0) -- Constraint to check that price is greate than or equal to 0
);

create table if not exists ProductTransactionTable(
	ProductTransactionID int primary key auto_increment, -- Primary key
    ProductID int not null, -- Foreign key from ProductDescription
    FinalTransactionID int not null, -- Foreign key from UserTransactionTable
    LeaseStart date not null,
    LeaseEnd date not null,
    constraint fk_productID foreign key (ProductID) references ProductDescription (ProductID) on delete cascade, -- Sets up foreign key and on delete cascade
    constraint fk_finalTransactionID foreign key (FinalTransactionID) references UserTransactionTable (FinalTransactionID) on delete cascade, -- Sets up foreign key and on delete cascade
    constraint ck_endAfterStart check (LeaseEnd > LeaseStart) -- Constraint to check LeaseEnd is after LeaseStart
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
    out p_Result boolean -- Result boolean to return back to be used by Java
)
begin
	declare Password_Login varchar(30); -- Declare local variable
    set Password_Login = (select (UserDetailsMaster.Password) from UserDetailsMaster where UserDetailsMaster.Username = p_Username); -- Set it equal to the password of corresponding username
	if Password_Login = p_Password then 
		set p_Result = 1; -- If the password is correct then set result to 1
	else 
		set p_Result = 0; -- Otherwise, set result to 0
	end if;
end;
/
delimiter ;