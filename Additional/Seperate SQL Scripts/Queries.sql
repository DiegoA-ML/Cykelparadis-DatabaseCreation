USE DB;

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

CREATE VIEW mostRepairedBike AS (
	SELECT bikeCode, COUNT(*) AS tot
    FROM RepairJob
    GROUP BY bikeCode
);

CREATE VIEW mostRepairPerType AS (
	SELECT b.type, MAX(m.tot) AS maxTot
    FROM RepairJob r JOIN mostRepairedBike m 
		ON r.bikeCode = m.bikeCode JOIN Bikes b 
        ON b.bikeCode = r.bikeCode
	GROUP BY b.type
);

CREATE VIEW rankBikes AS (
	SELECT b.type, b.bikeCode, b.CVR, ROW_NUMBER() OVER(PARTITION BY b.type ORDER BY b.bikeCode ASC) AS rnk
    FROM mostRepairedBike m JOIN Bikes b 
		ON m.bikeCode = b.bikeCode JOIN mostRepairPerType mr
        ON mr.type = b.type
	WHERE m.tot = mr.maxTot
);


	
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
