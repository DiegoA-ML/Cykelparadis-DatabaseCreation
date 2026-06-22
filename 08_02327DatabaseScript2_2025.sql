-- TABLE MODIFICATIONS

USE DB;

-- An example of inserting new information into the static tables:
INSERT INTO Manufacturer VALUES ('3928485838', 'Meow Bikes');
INSERT INTO Zip VALUES ('2610', 'Denmark', 'Rødovre');
INSERT INTO Parts VALUES ('P012', 160, 'Front wheel', '3928485838');

-- INSERT into more used tables that are expected to be changed a lot
INSERT INTO Customer VALUES('230560-0102','jakob@gamail.com');
INSERT INTO PhoneNumber VALUES('230560-0102','+4544123355');
INSERT INTO Address VALUES('230560-0102','Rødeovre','6','2610','Denmark');



-- INSERT EXAMPLES MATCHING THE IMAGES
-- Bike insertion (matches screenshot)
INSERT INTO Bikes VALUES('B011','Touring', 28, 29, 25,'8972948729');

-- Multiple-row insertion (matches screenshot)
INSERT INTO Compatibility (bikeCode, partCode)
VALUES
('B011', 'P009'),
('B001', 'P003'),
('B005', 'P002');

-- INSERT new repair job of just created bike
INSERT INTO RepairJob VALUES('230560-0102','B011','2025-11-15','2025-11-17');

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

-- UPDATE EXAMPLE MATCHING IMAGE (moved house)
UPDATE Address
SET street = 'Tranevej',
    civicNumber = '18',
    zipCode = '8000'
WHERE CPR = '120385-5678';

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

-- DELETE EXAMPLE MATCHING IMAGE (removing phone number)
DELETE FROM PhoneNumber 
WHERE phoneNumber = '+4510101112';

DELETE FROM Compatibility 
WHERE partCode = 'P001';

-- DELETE EXAMPLE MATCHING IMAGE (discontinued part)
DELETE FROM Compatibility 
WHERE partCode = 'P002';

-- QUERIES

-- Show the CPR number of all customers who got one of their bike repaired more than once.
SELECT DISTINCT CPR 
FROM RepairJob
GROUP BY CPR, bikeCode
HAVING COUNT(*) > 1;

-- Show the code and manufacturer of all parts that were never used for any repair.
SELECT p.partCode, p.CVR
FROM RepairParts r RIGHT JOIN Parts p 
	ON r.partCode = p.partCode
WHERE quantity IS NULL;

-- For each part, show the code, manufacturer, and total quantity being used for all repair jobs in 2024
SELECT r.partCode, p.CVR, SUM(r.quantity) AS 'Total quantity used'
FROM RepairParts r JOIN Parts p
	ON r.partCode = p.partCode
WHERE r.startDate >= '2024-01-01' AND r.startDate <= '2024-12-31'
GROUP BY r.partCode, p.CVR;

-- Notice views must be created to run this query.
-- For each bike type, show the type, code and manufacturer of the most repaired bike.
SELECT type, bikeCode, CVR
FROM rankBikes
WHERE rnk <= 1
ORDER BY type ASC;


-- Show the code and manufacturer of bikes than can use only parts from the same manufacturer.
SELECT DISTINCT b.bikeCode, b.CVR
FROM Compatibility c JOIN Bikes b
	ON c.bikeCode = b.bikeCode JOIN Parts p
    ON c.partCode = p.partCode
GROUP BY b.bikeCode, b.CVR
HAVING COUNT(DISTINCT p.CVR) = 1 AND b.CVR = MIN(p.CVR);


-- SQL PROGRAMMING

DELIMITER //

CREATE TRIGGER checkCPR
BEFORE INSERT ON Customer
FOR EACH ROW
BEGIN 
  IF NEW.CPR NOT REGEXP '^[0-9]{6}-[0-9]{4}$' THEN 
    SIGNAL SQLSTATE '45000'
    	SET MESSAGE_TEXT = 'Invalid CPR Number';
  END IF;
END//


CREATE FUNCTION getRepairPartsCost(
    CPR VARCHAR(11),
    bikeCode VARCHAR(10),
    startDate DATE,
    endDate DATE
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE total DECIMAL(10,2);

    SELECT SUM(p.unitPrice * rp.quantity)
    INTO total
    FROM RepairParts AS rp
    JOIN Parts AS p ON rp.partCode = p.partCode
    WHERE rp.CPR = CPR
      AND rp.bikeCode = bikeCode
      AND rp.startDate = startDate
      AND rp.endDate = endDate;

    IF total IS NULL THEN
        SET total = 0;
    END IF;

    RETURN total;
END //

DELIMITER ;

-- SELECT getRepairPartsCost('050577-9911', 'B005', '2025-04-02', '2025-04-06') AS total_cost;




DELIMITER //

CREATE PROCEDURE addPartToRepair(
    IN inCPR VARCHAR(11),
    IN inBikeCode VARCHAR(10),
    IN inStartDate DATE,
    IN inEndDate DATE,
    IN inPartCode VARCHAR(10),
    IN inQuantity INT
)
BEGIN
    -- Check compatibility
    IF EXISTS (
        SELECT 1 FROM Compatibility
        WHERE bikeCode = inBikeCode AND partCode = inPartCode
    ) THEN
        -- Add/update part for repair job
        INSERT INTO RepairParts (CPR, bikeCode, startDate, endDate, partCode, quantity)
        VALUES (inCPR, inBikeCode, inStartDate, inEndDate, inPartCode, inQuantity)
        ON DUPLICATE KEY UPDATE quantity = quantity + inQuantity;
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This part is not compatible with this bike';
    END IF;
END //

DELIMITER ;

-- CALL addPartToRepair('050577-9911', 'B005', '2025-04-02', '2025-04-06', 'P007', 2);



DELIMITER //

CREATE TRIGGER checkRepairDuration
BEFORE INSERT ON RepairJob
FOR EACH ROW
BEGIN
    DECLARE duration INT;

    SET duration = DATEDIFF(NEW.endDate, NEW.startDate);

    IF duration > 3 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Repair cannot take longer than 3 days';
    END IF;
END //


CREATE TRIGGER checkRepairCost
BEFORE INSERT ON RepairParts
FOR EACH ROW
BEGIN
    DECLARE totalCost DECIMAL(10,2);
    DECLARE newCost DECIMAL(10, 2);

    SET totalCost = getRepairPartsCost(
        NEW.CPR,
        NEW.bikeCode,
        NEW.startDate,
        NEW.endDate
    );

    SET newCost = (SELECT unitPrice 
    FROM Parts 
    WHERE partCode = NEW.partCode) 
    * NEW.quantity;

    SET totalCost = totalCost + newCost;

    IF totalCost > 100000 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Repair cost cannot be more than 100.000 dkk';
    END IF;
END //

DELIMITER ;
