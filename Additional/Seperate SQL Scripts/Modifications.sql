USE DB;

-- An example of inserting new information into the static tables:
INSERT INTO Manufacturer VALUES ('3928485838', 'Meow Bikes');
INSERT INTO Zip VALUES ('2610', 'Denmark', 'Rødovre');
INSERT INTO Parts VALUES ('P012', 160, 'Front wheel', '3928485838');

-- INSERT into more used tables that are expected to be changed a lot
INSERT INTO Customer VALUES('230560-0102','jakob@gamail.com');
INSERT INTO PhoneNumber VALUES('230560-0102','+4544123355');
INSERT INTO Address VALUES('230560-0102','Rødeovre','6','2610','Denmark');
INSERT INTO Bikes VALUES('B011','Mountain', 28, 25, 14.9,'3928485838');
INSERT INTO RepairJob VALUES('230560-0102','B011','2025-11-15','2025-11-17');
INSERT INTO Compatibility (bikeCode, partCode)
VALUES
('B011', 'P009'),
('B001', 'P003'),
('B005', 'P002');

-- Notice: This function needs to be called after the SQL programming section since this uses its function. 
-- CALL addPartToRepair('230560-0102', 'B011', '2025-11-15','2025-11-17', 'P012', 3);


-- UPDATE data
UPDATE Customer 
SET email = 'jakob7100@gmail.com'
WHERE CPR = '230560-0102';

UPDATE PhoneNumber
SET phoneNumber = '+4522301090'
WHERE CPR = '230560-0102';

UPDATE Address
SET street = 'Tranevej',
    civicNumber = '18',
    zipCode = '8000'
WHERE CPR = '230560-0102';

UPDATE Bikes
SET type = 'Hybridbike',
    speed = 30,
    weight = 28,
    diameter = 40
WHERE bikeCode = 'B011';

-- DELETE
-- Notice: We use ON DELETE CASCADE on the customer CPR. So the delete will work but it means 
-- we will lose the RepairJobs associated with this person. 
DELETE FROM Customer 
WHERE cpr = '010192-1234';

DELETE FROM PhoneNumber 
WHERE phoneNumber = '+4522233344';

DELETE FROM Compatibility 
WHERE partCode = 'P001';
