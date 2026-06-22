
DROP DATABASE IF EXISTS DB;
CREATE DATABASE IF NOT EXISTS DB;

USE DB;

CREATE TABLE IF NOT EXISTS Manufacturer (
	CVR		VARCHAR(10) NOT NULL,
    name	VARCHAR(255),
    PRIMARY KEY(CVR)
);

CREATE TABLE IF NOT EXISTS Bikes (
	bikeCode	VARCHAR(10) NOT NULL,
    type	    VARCHAR(255),
    speed		INT,
    weight		FLOAT,
    diameter	INT,
    CVR			VARCHAR(10) NOT NULL,
    PRIMARY KEY (bikeCode),
    FOREIGN KEY(CVR) REFERENCES Manufacturer(CVR)
);

CREATE TABLE IF NOT EXISTS Parts (
	partCode		VARCHAR(10) NOT NULL,
    unitPrice	INT,
    description VARCHAR(255),
    CVR			VARCHAR(10) NOT NULL,
    PRIMARY KEY(partCode),
    FOREIGN KEY(CVR) REFERENCES Manufacturer(CVR)
);

CREATE TABLE IF NOT EXISTS Compatibility (
	bikeCode   VARCHAR(10) NOT NULL,
    partCode   VARCHAR(10) NOT NULL,
    PRIMARY KEY (bikeCode, partCode),
    FOREIGN KEY (bikeCode) REFERENCES Bikes(bikeCode),
    FOREIGN KEY (partCode) REFERENCES Parts(partCode)
);

CREATE TABLE IF NOT EXISTS Customer (
	CPR		   VARCHAR(11) NOT NULL,
    email	   VARCHAR(255),
    PRIMARY KEY(CPR)
);

CREATE TABLE IF NOT EXISTS RepairJob (
	CPR		   VARCHAR(11) NOT NULL,
    bikeCode   VARCHAR(10) NOT NULL,
    startDate  DATE NOT NULL,
    endDate	   DATE NOT NULL,
    PRIMARY KEY(CPR, bikeCode, startDate, endDate),
	FOREIGN KEY (CPR) REFERENCES Customer(CPR) ON DELETE CASCADE,
    FOREIGN KEY (bikeCode) REFERENCES Bikes(bikeCode)
);

CREATE TABLE IF NOT EXISTS RepairParts (
	CPR		   VARCHAR(11) NOT NULL,
    bikeCode   VARCHAR(10) NOT NULL,
    startDate  DATE NOT NULL,
    endDate	   DATE NOT NULL,
    partCode   VARCHAR(10) NOT NULL, 
	quantity   INT NOT NULL,
    PRIMARY KEY(CPR, bikeCode, startDate, endDate, partCode),
	FOREIGN KEY (CPR, bikeCode, startDate, endDate)
        REFERENCES RepairJob(CPR, bikeCode, startDate, endDate)
        ON DELETE CASCADE,
    FOREIGN KEY (partCode) REFERENCES Parts(partCode)
);

CREATE TABLE IF NOT EXISTS FullName (
	CPR 	  VARCHAR(11) NOT NULL,
    firstName VARCHAR(255),
    lastName  VARCHAR(255),
    PRIMARY KEY (CPR),
    FOREIGN KEY (CPR) REFERENCES Customer(CPR) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS PhoneNumber (
	CPR		    VARCHAR(11) NOT NULL,
    phoneNumber VARCHAR(16),
	PRIMARY KEY (CPR, phoneNumber),
    FOREIGN KEY (CPR) REFERENCES Customer(CPR) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Zip (
	zipCode		VARCHAR(4),
	country		VARCHAR(20),
    city		VARCHAR(40),
    
    PRIMARY KEY (zipCode, country)
);

CREATE TABLE IF NOT EXISTS Address (
	CPR			VARCHAR(11) NOT NULL,
    street		VARCHAR(40),
    civicNumber VARCHAR(20),
    zipCode		VARCHAR(20) NOT NULL,
    country 	VARCHAR(255) NOT NULL,

    PRIMARY KEY (CPR),
    FOREIGN KEY (CPR) REFERENCES Customer(CPR) ON DELETE CASCADE,
    FOREIGN KEY (zipCode, country) REFERENCES Zip(zipCode, country)
);
