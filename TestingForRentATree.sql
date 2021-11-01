call createNewUser('Test','Test@Test.com', 'Test', 'Test', 10, 'Test', 'HP180ZP', '01478523691', 'Test'); -- Should be added
call createNewUser('Test2', 'sjnfiu', 'Test', 'Test', '2', 'Test', 'HP180ZP', '01234567891', 'Test'); -- Email validation error
call createNewUser('Test', 'Test3@Test.com', 'Test', 'Test', 10, 'Test', 'HP180ZP', '01478523691', 'Test'); -- Duplicate username error
call createNewUser('Test4', 'Test@Test.com', 'Test', 'Test', 10, 'Test', 'HP180ZP', '01478523691', 'Test'); -- Duplicate email error
call createNewUser('Test5', 'Test5@Test.com', 'Test', 'Test', 5, 'Test', '00sn279', '01234567891', 'Test'); -- Postcode validation error
call createNewUser('Test6', 'Test6@Test.com', 'Test', 'Test', 3, 'Test', 'HP180ZP', '0125644', 'Test'); -- Phone number validation error