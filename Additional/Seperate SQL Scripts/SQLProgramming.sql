
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
