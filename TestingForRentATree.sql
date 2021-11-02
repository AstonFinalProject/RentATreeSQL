# createNewUser stored procedure testing
set @uID = -1;
call createNewUser('Test','Test@Test.com', 'Test', 'Test', '01478523691', 'Test', @uID); -- Should be added
call createNewUser('Test', 'Test3@Test.com', 'Test', 'Test', '01478523691', 'Test', @uID); -- Duplicate username error
call createNewUser('Test4', 'Test@Test.com', 'Test', 'Test', '01478523691', 'Test', @uID); -- Duplicate email error
call createNewUser('Test6', 'Test6@Test.com', 'Test', 'Test', '0125644', 'Test', @uID); -- Phone number validation error

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