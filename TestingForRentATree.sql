# createNewUser stored procedure testing
set @uID = -1;
call createNewUser('Test','Test@Test.com', 'Test', 'Test', '01478523691', 'Test', @uID); -- Should be added
call createNewUser('Test', 'Test3@Test.com', 'Test', 'Test', '01478523691', 'Test', @uID); -- Duplicate username error
call createNewUser('Test4', 'Test@Test.com', 'Test', 'Test', '01478523691', 'Test', @uID); -- Duplicate email error
call createNewUser('Test6', 'Test6@Test.com', 'Test', 'Test', '0125644', 'Test', @uID); -- Phone number validation error
select * from UserDetailsMaster;

# login stored procedure testing
set @resultCheck = -1;
call login('Test', 'shouldproduce0', @resultCheck); -- As the password does not match, it should return the value 0 to @resultCheck
select (concat('The result was ', @resultCheck)) as 'ThisValueShouldBe0';
call login('Test', 'Test', @resultCheck); -- As the password matches, it should return the value 1 to @resultCheck
select (concat('The result was ', @resultCheck)) as 'ThisValueShouldBe1';

# newDeliveryAddress stored procedure testing
call newDeliveryAddress('10', 'Test', 'Test', 'HP180ZP'); -- Should work
call newDeliveryAddress('10', 'Test', 'Test', 'abny'); -- Shouldn't work
call newDeliveryAddress('10', 'Test', 'Test', 'S12HH'); -- Should work

# userTransaction stored procedure testing
call userTransaction('Test', 30); -- Should add to table
call userTransaction('NoTest', 50); -- Shouldn't add to table as username does not exist
call createNewUser('Test2', 'Test2@Test.com', 'Test', 'Test', '98745632107', 'Test', @uID);
call userTransaction('Test2', 450); -- Should add
call userTransaction('Test', 70); -- Should add
select * from UserTransactionTable;

# newTreeDescriptionMaster procedure testing
call newTreeDescriptionMaster('Test', 'Test', 'Test', 10); -- Should add
call newTreeDescriptionMaster('Test2', 'Test2', 'Test2', 5); -- Should add
select * from TreeDescriptionMaster;

# insertNewSupplier procedure testing
call insertNewSupplier('TestSupplier'); -- Should add
call insertNewSupplier('TestSupplier2'); -- Should add
select * from TreeSupplierMaster;

# insertNewProduct procedure testing
call insertNewProduct(1, 1, 3.2, 30); -- Should add
call insertNewProduct(1, 1, 4.5, 35); -- Should add
call insertNewProduct(2, 1, 2.5, 50); -- Should add
call insertNewProduct(2, 2, 3.1, 60); -- Should add
call insertNewProduct(10, 1, 4.2, 30); -- Should throw error as TreeID doesn't exist
call insertNewProduct(1, 5, 3.1, 45); -- Should throw error as SupplierID doesn't exist
select * from ProductDescription;