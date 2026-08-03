-- ============================================================
-- Project: Retail Sales Analytics
-- File: 00_data_cleaning.sql
--
-- Author: Shubham Salvi
--
-- Objective:
-- Clean the raw Online Retail dataset and create a reliable
-- source table for relational database design and analysis.
--
-- Dataset:
-- UCI Online Retail Dataset
--
-- Cleaning Rules:
-- 1. Remove records with missing CustomerID
-- 2. Remove records with missing Description
-- 3. Remove records with UnitPrice = 0
-- 4. Retain negative quantities (customer returns)
-- ============================================================

USE retail_project;

CREATE TABLE online_retail_full_stage
(
    InvoiceNo   VARCHAR(20),
    StockCode   VARCHAR(20),
    Description VARCHAR(255),
    Quantity    VARCHAR(20),
    InvoiceDate VARCHAR(30),
    UnitPrice   VARCHAR(30),
    CustomerID  VARCHAR(20),
    Country     VARCHAR(100)
);

LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/OnlineRetail.csv'
INTO TABLE online_retail_full_stage
CHARACTER SET latin1
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    @CustomerID,
    Country
) 
SET CustomerID = NULLIF(TRIM(@CustomerID), '');


SELECT COUNT(*) AS imported_rows
FROM online_retail_full_stage;


SELECT InvoiceDate
FROM online_retail_full_stage
LIMIT 10;

-- Validating Invoice date
SELECT
    MIN(
        STR_TO_DATE(
            TRIM(InvoiceDate),
            '%d-%m-%Y %H:%i'
        )
    ) AS first_date,

    MAX(
        STR_TO_DATE(
            TRIM(InvoiceDate),
            '%d-%m-%Y %H:%i'
        )
    ) AS last_date
    

FROM online_retail_full_stage;

SELECT COUNT(*) AS invalid_dates
FROM online_retail_full_stage
WHERE STR_TO_DATE(
          TRIM(InvoiceDate),
          '%d-%m-%Y %H:%i'
      ) IS NULL;
-- Validating unit      
SELECT COUNT(*) AS invalid_quantities
FROM online_retail_full_stage
WHERE NULLIF(TRIM(Quantity), '') IS NULL
   OR TRIM(Quantity) NOT REGEXP '^-?[0-9]+$';

SELECT
    SUM(CustomerID IS NULL OR TRIM(CustomerID) = '') AS missing_customer_ids,
    SUM(Description IS NULL OR TRIM(Description) = '') AS missing_descriptions,
    SUM(CAST(TRIM(UnitPrice) AS DECIMAL(12,4)) <= 0) AS zero_or_negative_prices,
    SUM(CAST(TRIM(Quantity) AS SIGNED) < 0) AS return_rows
FROM online_retail_full_stage;

RENAME TABLE
    online_retail TO online_retail_partial_backup,
    online_retail_clean TO online_retail_clean_partial_backup;

SHOW TABLES LIKE '%partial_backup%';

RENAME TABLE
    online_retail_full_stage TO online_retail;
    
SELECT COUNT(*) from online_retail;

-- ------------------------------------------------------------
-- Create the cleaned dataset
-- ------------------------------------------------------------
CREATE TABLE online_retail_clean
(
    InvoiceNo   VARCHAR(20) NOT NULL,
    StockCode   VARCHAR(20) NOT NULL,
    Description VARCHAR(255) NOT NULL,
    Quantity    INT NOT NULL,
    InvoiceDate DATETIME NOT NULL,
    UnitPrice   DECIMAL(12,4) NOT NULL,
    CustomerID  VARCHAR(20) NOT NULL,
    Country     VARCHAR(100) NOT NULL
);

INSERT INTO online_retail_clean
(
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country
)
SELECT
    TRIM(InvoiceNo),
    TRIM(StockCode),
    TRIM(Description),
    CAST(TRIM(Quantity) AS SIGNED),
    STR_TO_DATE(
        TRIM(InvoiceDate),
        '%d-%m-%Y %H:%i'
    ),
    CAST(TRIM(UnitPrice) AS DECIMAL(12,4)),
    TRIM(CustomerID),
    TRIM(Country)
FROM online_retail
WHERE NULLIF(TRIM(CustomerID), '') IS NOT NULL
  AND NULLIF(TRIM(Description), '') IS NOT NULL
  AND CAST(TRIM(UnitPrice) AS DECIMAL(12,4)) > 0;

-- ============================================================
-- End of data cleaning
-- ============================================================


-- ------------------------------------------------------------
-- Validation
-- ------------------------------------------------------------

SELECT COUNT(*) AS cleaned_rows
FROM online_retail_clean;

SELECT
    COUNT(*) AS missing_customer
FROM online_retail_clean
WHERE CustomerID IS NULL
   OR TRIM(CustomerID) = '';

SELECT
    SUM(CustomerID IS NULL OR TRIM(CustomerID) = '') AS missing_customer_ids,
    SUM(Description IS NULL OR TRIM(Description) = '') AS missing_descriptions,
    SUM(UnitPrice <= 0) AS invalid_prices,
    SUM(Quantity < 0) AS return_rows
FROM online_retail_clean;

DESCRIBE online_retail_clean;
