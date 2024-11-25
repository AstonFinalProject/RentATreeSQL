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
    Password varchar(300) not null,
    isAdmin BOOL DEFAULT FALSE,
    Hit int not null default 0,
    Miss int not null default 0,
    constraint uq_username unique(Username), -- Unique username
    constraint uq_email unique(Email), -- Unique email addressuserdetailsmaster
    constraint ck_emailvalidation check (Email like '_%@_%.com'), -- Email validation
    constraint ck_phonenovalidation check (TelephoneNo rlike '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]') -- Telephone number validation
);

create table if not exists UserTransactionTable(
	FinalTransactionID int primary key auto_increment, -- Primary key
    UserID int not null, -- Foreign key from UserDetailsMaster
    TotalSum double, 
    DeliverySlot char(2),
    ReturnSlot char(2),
    constraint fk_userID foreign key (UserID) references UserDetailsMaster (UserID) on delete cascade, -- Sets up foreign key and on delete cascade
    constraint ck_positivetotalsum check (TotalSum >= 0) -- Constraint to check total sum is greater than or equal to 0
);

create table if not exists TreeDescriptionMaster(
	TreeID int primary key auto_increment, -- Primary key
    TreeDescription varchar(100) not null,
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
    Price double not null, -- Price in pence right now as this is what was used in the sample code
    constraint fk_treeID foreign key (TreeID) references TreeDescriptionMaster (TreeID) on delete cascade, -- Sets up foreign key and on delete cascade
    constraint fk_supplierID foreign key (SupplierID) references TreeSupplierMaster (SupplierID) on delete cascade, -- Sets up foreign key and on delete cascade
    constraint ck_positiveheight check (Height > 0), -- Constraint to check that height is greater than 0
    constraint ck_positiveprice check (Price >= 0) -- Constraint to check that price is greater than or equal to 0
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

create table if not exists TreeStockTable(
	TreeStockID int primary key auto_increment,
    TreeID int not null,
    TreeStockDate date not null,
    Stock int,
    constraint fk_treeIDForStock foreign key (TreeID) references TreeDescriptionMaster (TreeID) on delete cascade
);

delimiter /
create procedure createNewUser(
	in p_Username varchar(30),
    in p_Email varchar(80),
    in p_FName varchar(30),
    in p_LName varchar(30),
    in p_TelephoneNo char(11),
    in p_Password varchar(300),
    out p_userID int
)
begin
	declare encrypted_Password varchar(300);
    set encrypted_Password = SHA1(p_Password); -- Encrpyt the password that is stored
	insert into UserDetailsMaster(Username,Email,FName,LName,TelephoneNo,Password) 
		values (p_Username,p_Email,p_FName,p_LName,p_TelephoneNo,encrypted_Password);
	SET p_userid = (SELECT MAX(UserID) FROM UserDetailsMaster);
end;
/

create procedure login(
	in p_Username varchar(30),
    in p_Password varchar(300),
    out p_Result boolean -- Result boolean to return back to be used by Java
)
begin
	declare Password_Login varchar(300); -- Declare local variable
    declare encrypted_Password_Attempt varchar(300); -- Delcare local variable
	DECLARE isAdmin BOOL;
    set Password_Login = (select (UserDetailsMaster.Password) from UserDetailsMaster where UserDetailsMaster.Username = p_Username); -- Set it equal to the password of corresponding username
    set encrypted_Password_Attempt = SHA1(p_Password); -- Checks if whatever password is attempted to log in is equal to the one stored
    SET isAdmin = (SELECT (UserDetailsMaster.isAdmin) FROM UserDetailsMaster WHERE UserDetailsMaster.Username = p_Username);
  

    if Password_Login = encrypted_Password_Attempt then 
		IF isAdmin THEN
			SET p_Result = 2;
		ELSE
			set p_Result = 1; -- If the password is correct then set result to 1
		END IF;
	else 
		set p_Result = 0; -- Otherwise, set result to 0
	end if;
end;
/

create procedure setAdmin(
	in p_Username varchar(30)
)
begin
	UPDATE UserDetailsMaster SET isAdmin = true WHERE UserDetailsMaster.Username = p_Username;
end;
/

create procedure adminLogin(
	in p_Username varchar(30),
    in p_Password varchar(300),
    out p_Result boolean -- Result boolean to return back to be used by Java
)
begin
	declare Password_Login varchar(300); -- Declare local variable
    declare encrypted_Password_Attempt varchar(300); -- Delcare local variable
	DECLARE isAdmin BOOL;
    set Password_Login = (select (UserDetailsMaster.Password) from UserDetailsMaster where UserDetailsMaster.Username = p_Username); -- Set it equal to the password of corresponding username
    set encrypted_Password_Attempt = SHA1(p_Password); -- Checks if whatever password is attempted to log in is equal to the one stored
    SET isAdmin = (SELECT (UserDetailsMaster.isAdmin) FROM UserDetailsMaster WHERE UserDetailsMaster.Username = p_Username);
    if Password_Login = encrypted_Password_Attempt AND isAdmin = TRUE then 
		set p_Result = 1; -- If the password is correct then set result to 1
	else 
		set p_Result = 0; -- Otherwise, set result to 0
	end if;
end;
/


create procedure incrementHit(
	in p_Username varchar(30)
)
begin
	SET @currentHit = (SELECT Hit FROM UserDetailsMaster WHERE UserDetailsMaster.Username = p_Username);
    UPDATE UserDetailsMaster SET Hit = (currentHit+1) WHERE UserDetailsMaster.Username = p_Username;
end;
/
create procedure incrementMiss(
	in p_Username varchar(30)
)
begin
	SET @currentMiss = (SELECT Miss FROM UserDetailsMaster WHERE UserDetailsMaster.Username = p_Username);
    UPDATE UserDetailsMaster SET Miss = (currentMiss+1) WHERE UserDetailsMaster.Username = p_Username;
end;
/


create procedure insertTree(
	in p_TreeType varchar(20),
    in p_TreeMaterial varchar(20),
    in p_SupplierName varchar(30),
    in p_Height double,
    in p_Price DOUBLE
)
begin
	SET @p_TreeID = (SELECT TreeID FROM TreeDescriptionMaster WHERE TreeDescriptionMaster.TreeType = p_TreeType AND TreeDescriptionMaster.TreeMaterial = p_TreeMaterial);
	SET @p_SupplierID = (SELECT SupplierID FROM TreeSupplierMaster WHERE TreeSupplierMaster.SupplierName = p_SupplierName);
	insert into ProductDescription(TreeID, SupplierID, Height, Price) values (@p_TreeID, @p_SupplierID, p_Height, p_Price);
end;
/
create procedure deleteTree(
	in p_ProductID INT
)
begin
    DELETE FROM ProductDescription WHERE ProductDescription.ProductID = p_ProductID;
end;
/


create procedure newTreeDescriptionMaster(
	in p_TreeDescription varchar(100),
    in p_TreeType varchar(20),
    in p_TreeMaterial varchar(20),
    in p_Stock int
)
begin 
	insert into TreeDescriptionMaster(TreeDescription, TreeType, TreeMaterial, Stock) values (p_TreeDescription, p_TreeType, p_TreeMaterial, p_Stock);
end;
/
create procedure deleteTreeType(
	in p_TreeID INT
)
begin
    DELETE FROM TreeDescriptionMaster WHERE TreeID.ProductID = p_ProductID;
end;
/

create procedure deleteTreeType(
	in p_TreeType varchar(20)
)
begin
	SET @p_TreeID = (SELECT TreeID FROM TreeDescriptionMaster WHERE TreeDescriptionMaster.Type = p_TreeType);
    DELETE FROM TreeDescriptionMaster WHERE TreeDescriptionMaster.TreeID = @p_TreeID;
end;
/


create procedure userTransaction(
	in p_Username varchar(30),
    in p_TotalSum double,
    out p_finalTransactionID int,
    in p_DeliverySlot char(2),
    in p_ReturnSlot char(2)
)
begin
	declare UserID_Transaction int; -- Declare local variable
    set UserID_Transaction = (select (UserDetailsMaster.UserID) from UserDetailsMaster where UserDetailsMaster.Username = p_Username); -- Set ID equal to ID corresponding to username -- Insert values into the transaction table
    insert into UserTransactionTable(UserID,TotalSum,DeliverySlot,ReturnSlot) values (UserID_Transaction, p_TotalSum, p_DeliverySlot, p_ReturnSlot); -- Insert values into the transaction table
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
	insert into ProductTransactionTable(ProductID,FinalTransactionID,LeaseStart,LeaseEnd) values (p_ProductID,p_FinalTransactionID,p_LeaseStart,p_LeaseEnd);
end;
/

create procedure newDeliveryAddress(
	in p_HouseNameOrNumber varchar(30),
    in p_StreetName varchar(30),
    in p_City varchar(30),
    in p_Postcode varchar(7),
    out p_deliveryid int
)
begin 
	insert into DeliveryAddressTable(HouseNameOrNumber, StreetName, City, Postcode) values (p_HouseNameOrNumber, p_StreetName, p_City, p_Postcode);
    set p_deliveryid = (select last_insert_id());
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
	in p_TreeDescription varchar(100),
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
    in p_Price double
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


create procedure insertTreeStockTable(
	in p_TreeID int,
    in p_TreeStockDate date,
    in p_Stock int
)
begin
	insert into TreeStockTable(TreeID, TreeStockDate, Stock) values (p_TreeID, p_TreeStockDate, p_Stock);
end;
/

create procedure setupTreeStock(IN startdate datetime, IN enddate datetime, IN treeid int)
begin
	declare stock int;
    set stock = (select treedescriptionmaster.stock from treedescriptionmaster where treedescriptionmaster.treeid=treeid);
	while(startdate<enddate) DO
        call insertTreeStockTable(treeid, startdate, stock);
		set startdate = (select date_add(startdate, interval 1 day));
    end while;
end;
/

create procedure setupTreeStockAllTrees(IN startdate datetime, IN enddate datetime)
BEGIN 
declare treeid_max int;
declare init int;
set init = 1;
set treeid_max = (select max(treedescriptionmaster.treeid) from treedescriptionmaster);
while(init<=treeid_max) do
	call setupTreeStock(startdate, enddate, init);
    set init = init+1;
end while;
END;
/


create procedure incrementHit(
	in p_Username varchar(30)
)
begin
    UPDATE UserDetailsMaster SET Hit = (Hit+1) WHERE UserDetailsMaster.Username = p_Username;
end;
/
create procedure incrementMiss(
	in p_Username varchar(30)
)
begin
    UPDATE UserDetailsMaster SET Miss = (Miss+1) WHERE UserDetailsMaster.Username = p_Username;
end;
/


create procedure insertTree(
	in p_TreeType varchar(20),
    in p_TreeMaterial varchar(20),
    in p_SupplierName varchar(30),
    in p_Height double,
    in p_Price DOUBLE
)
begin
	SET @p_TreeID = (SELECT TreeID FROM TreeDescriptionMaster WHERE TreeDescriptionMaster.TreeType = p_TreeType AND TreeDescriptionMaster.TreeMaterial = p_TreeMaterial);
	SET @p_SupplierID = (SELECT SupplierID FROM TreeSupplierMaster WHERE TreeSupplierMaster.SupplierName = p_SupplierName);
	insert into ProductDescription(TreeID, SupplierID, Height, Price) values (@p_TreeID, @p_SupplierID, p_Height, p_Price);
end;
/
create procedure deleteTree(
	in p_ProductID INT
)
begin
    DELETE FROM ProductDescription WHERE ProductDescription.ProductID = p_ProductID;
end;
/



create procedure deleteTreeType(
	in p_TreeID INT
)
begin
    DELETE FROM TreeDescriptionMaster WHERE TreeID = p_TreeID;
end;
/



create trigger adjustStockTreeStockTable after insert 
on ProductTransactionTable
for each row
begin
	declare init_date datetime;
    declare treeid_req int;
    set treeid_req = (select productdescription.treeid from productdescription where productdescription.productid=new.productid);
    set init_date = new.LeaseStart;
    while (init_date<new.LeaseEnd) DO
		update treestocktable set stock = stock - 1 where treestocktable.treeid = treeid_req and treestocktable.treestockdate = init_date;
		set init_date = date_add(init_date, interval 1 day);
    end while;
end;
/

create trigger newproductstock after insert
on treedescriptionmaster
for each row
begin 
call setupTreeStock('2021-11-04', '2025-11-04', new.treeid);
end;
/

delimiter ;


 #Trigger to adjust stock after transaction
/* create trigger adjustStock after insert on ProductTransactionTable
	for each row
		update TreeDescriptionMaster
			set TreeDescriptionMaster.Stock = TreeDescriptionMaster.Stock - 1 -- Adjust the stock by minus one
				where TreeID = ( select (ProductDescription.TreeID) from ProductDescription -- Of the corresponding tree type of the product that was sold
					where ProductDescription.ProductID = new.ProductID);
/
*/

# Default data storage
set @uID = -1;
call createNewUser('TestUsername', 'Test@Email.com', 'TestFName', 'TestLName', '99999999999', 'TestPassword', @uID);
call createNewUser('JY553', 'Jay01young@gmail.com', 'Jamie', 'Young', '07599268888', 'Pa$$word123', @uID);
call createNewUser('AChenna', 'AChenna@icloud.com', 'Aasrith', 'Chenna', '01296455788', 'DUMMY', @uID);
call createNewUser('Harison987', 'WrightHarison1@sky.com', 'Harison', 'Wright', '07526458792', 'NotAPassword', @uID);
call createNewUser('JKaur', 'ItsJasleen@btinternet.com', 'Jasleen', 'Kaur', '01456554238', 'DummyPassword!', @uID);

CALL setAdmin('Harison987');

call insertNewSupplier('GoGoTrees');
call insertNewSupplier('TreesRUs');
call insertNewSupplier('SuperTrees');

call newTreeDescriptionMaster('Wonderful artificial PVC Fir tree with beautiful leaves.', 'Fir', 'PVC', 4);
call newTreeDescriptionMaster('Natural Pine tree to bring life to the house for Christmas.', 'Pine', 'Natural', 2);
call newTreeDescriptionMaster('Artifical PE Spruce tree with woody scent to celebrate Christmas.', 'Spruce', 'PE', 5);
call newTreeDescriptionMaster('PVC Cedar Tree with life-like leaves and branches.', 'Cedar', 'PVC', 3);
call newTreeDescriptionMaster('Natural Fir tree, the perfect centre point for festivity.', 'Fir', 'Natural', 3);

call insertNewProduct(1, 1, 152.3, 30);
call insertNewProduct(1, 1, 165.7, 45);
call insertNewProduct(1, 1, 122.2, 32);
call insertNewProduct(1, 2, 150.5, 78);
call insertNewProduct(2, 3, 195.0, 156);
call insertNewProduct(2, 3, 210.0, 200);
call insertNewProduct(3, 1, 130.5, 50);
call insertNewProduct(3, 2, 89.0, 60);
call insertNewProduct(3, 2, 99.9, 80);
call insertNewProduct(3, 2, 105.0, 85);
call insertNewProduct(3, 3, 132.0, 105);
call insertNewProduct(4, 1, 123.4, 62);
call insertNewProduct(4, 1, 143.0, 75);
call insertNewProduct(4, 3, 162.6, 99);
call insertNewProduct(5, 2, 187.2, 170);
call insertNewProduct(5, 2, 199.9, 200);
call insertNewProduct(5, 3, 220.0, 205);

call setupTreeStockAllTrees('2021-11-04', '2025-11-04');
select count(*) from treestocktable;
select stock from treedescriptionmaster where treeid = 1;