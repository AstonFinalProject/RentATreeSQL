drop database if exists RentATree;
create database if not exists RentATree;
use RentATree;

create table if not exists UserDetailsMaster(
	UserID int primary key auto_increment, -- Primary key
    Username varchar(30) not null, 
    Email varchar(80) not null, 
    FName varchar(30) not null,
    LName varchar(30) not null,
    TelephoneNo char(11) not null, 
    Password varchar(30) not null,
    constraint uq_username unique(Username), -- Unique username
    constraint uq_email unique(Email), -- Unique email addressuserdetailsmaster
    constraint ck_emailvalidation check (Email like '_%@_%.com'), -- Email validation
   
    constraint ck_phonenovalidation check (TelephoneNo rlike '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]') -- Telephone number validation
);

-- constraint ck_postcodevalidation check (Postcode rlike '[A-Z][A-Z][0-9][0-9][0-9][A-Z][A-Z]' or Postcode rlike '[A-Z][A-Z][0-9][0-9][A-Z][A-Z]'), -- Postcode validation

create table if not exists UserTransactionTable(
	FinalTransactionID int primary key auto_increment, -- Primary key
    UserID int not null, -- Foreign key from UserDetailsMaster
    TotalSum int, 
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

create table if not exists DeliveryAddressTable(
	DeliveryAddressID int primary key auto_increment, -- Primary key
    HouseNameOrNumber varchar(30) not null, 
    StreetName varchar(30) not null,
    City varchar(30) not null,
    Postcode varchar(7),
    constraint ck_postcodevalidation check (Postcode rlike '[A-Z][0-9][0-9][0-9][A-Z][A-Z]' or Postcode rlike '[A-Z][0-9][0-9][A-Z][A-Z]' or Postcode rlike '[A-Z][0-9][0-9][0-9][A-Z][A-Z]' or Postcode rlike '[A-Z][A-Z][0-9][0-9][0-9][A-Z][A-Z]')
);

create table if not exists DeliveryTransactionJunction(
	FinalTransactionID int not null, -- Foreign key from UserTransactionTable
    DeliveryAddressID int not null, -- Foreign key from DeliveryAddressTable
    constraint fk_deliveryFinalTransactionID foreign key (FinalTransactionID) references UserTransactionTable (FinalTransactionID) on delete cascade, -- Sets up foreign key reference and on delete cascade
    constraint fk_deliveryAddressID foreign key (DeliveryAddressID) references DeliveryAddressTable (DeliveryAddressID) on delete cascade -- Sets up foreign key reference and on delete cascade
);

delimiter /
create procedure createNewUser(
	in p_Username varchar(30),
    in p_Email varchar(80),
    in p_FName varchar(30),
    in p_LName varchar(30),
    in p_TelephoneNo char(11),
    in p_Password varchar(30),
    out p_userID int
)
begin
	insert into UserDetailsMaster(Username,Email,FName,LName,TelephoneNo,Password) 
		values (p_Username,p_Email,p_FName,p_LName,p_TelephoneNo,p_Password);
	SET p_userid = (SELECT MAX(UserID) FROM UserDetailsMaster);
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

create procedure userTransaction(
	in p_Username varchar(30),
    in p_TotalSum int,
    out p_finalTransactionID int
)
begin
	declare UserID_Transaction int; -- Declare local variable
    set UserID_Transaction = (select (UserDetailsMaster.UserID) from UserDetailsMaster where UserDetailsMaster.Username = p_Username); -- Set ID equal to ID corresponding to username
    insert into UserTransactionTable(UserID,TotalSum) values (UserID_Transaction, p_TotalSum); -- Insert values into the transaction table
    SET  p_finalTransactionID = (SELECT last_insert_id());
end;
/

create procedure productTransaction(
	in p_ProductID int,
    in p_FinalTransactionID int,
    in p_LeaseStart date,
    in p_LeaseEnd date
)
begin
	insert into ProductTransactionTable(ProductID,FinalTransactionID,LeaseStart,LeaseEnd) values (p_ProductID,p_inalTransactionID,p_LeaseStart,p_LeaseEnd);
end;
/

create procedure newDeliveryAddress(
	in p_HouseNameOrNumber varchar(30),
    in p_StreetName varchar(30),
    in p_City varchar(30),
    in p_Postcode varchar(7)
)
begin 
	insert into DeliveryAddressTable(HouseNameOrNumber, StreetName, City, Postcode) values (p_HouseNameOrNumber, p_StreetName, p_City, p_Postcode);
end;
/

create procedure insertTransactionJunction(
	in p_FinalTransactionID int,
    in p_DeliveryAddressID int
)
begin
	insert into DeliveryTransactionJunction(FinalTransactionID, DeliveryAddressID) values (p_FinalTransactionID, p_DeliveryAddressID);
end;
/

create procedure newTreeDescriptionMaster(
	in p_TreeDescription varchar(50),
    in p_TreeType varchar(20),
    in p_TreeMaterial varchar(20),
    in p_Stock int
)
begin 
	insert into TreeDescriptionMaster(TreeDescription, TreeType, TreeMaterial, Stock) values (p_TreeDescription, p_TreeType, p_TreeMaterial, p_Stock);
end;
/

create procedure insertNewProduct(
	in p_TreeID int,
    in p_SupplierID int,
    in p_Height double,
    in p_Price int
)
begin
	insert into ProductDescription(TreeID, SupplierID, Height, Price) values (p_TreeID, p_SupplierID, p_Height, p_Price);
end;
/

create procedure insertNewSupplier(
	in p_SupplierName varchar(30)
)
begin
	insert into TreeSupplierMaster(SupplierName) values (p_SupplierName);
end;
/

create trigger adjustStock after insert on ProductTransactionTable
	for each row
		update TreeDescriptionMaster
			set Stock.TreeDescriptionMaster = Stock.TreeDescriptionMaster - 1 
				where TreeID = ( select (TreeID.ProductDescription) from ProductDescription 
					where ProductID.ProductDescription = new.ProductID);
/
delimiter ;

INSERT INTO treedescriptionmaster (TreeDescription, TreeType, TreeMaterial, Stock) VALUES ("this is a tree", "oak", "pvc", 100);
INSERT INTO treesuppliermaster (suppliername) VALUES ("xyz supplier");
INSERT INTO productdescription (TreeID, SupplierID, Height, Price) VALUES (1,1,1000,10);
INSERT INTO productdescription (TreeID, SupplierID, Height, Price) VALUES (1,1,1001,10);
INSERT INTO productdescription (TreeID, SupplierID, Height, Price) VALUES (1,1,1001,15);
INSERT INTO productdescription (TreeID, SupplierID, Height, Price) VALUES (1,1,1002,10);
INSERT INTO productdescription (TreeID, SupplierID, Height, Price) VALUES (1,1,1004,10);
