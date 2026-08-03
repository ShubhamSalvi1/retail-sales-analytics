-- ============================================================
-- RETAIL SALES ANALYTICS PROJECT
-- File: 01_database_setup.sql
-- Purpose:
--   Create and populate the relational tables used for analysis.
-- ============================================================
USE retail_project;

-- ============================================================
-- CUSTOMERS TABLE
-- One row per customer
-- ============================================================


CREATE TABLE customers (
    CustomerID VARCHAR(20) NOT NULL,
    Country VARCHAR(50),
    PRIMARY KEY (CustomerID)
);

INSERT INTO customers
(
    CustomerID,
    Country
)
WITH ranked_customers AS
(
    SELECT
        CustomerID,
        Country,

        ROW_NUMBER() OVER
        (
            PARTITION BY CustomerID
            ORDER BY InvoiceDate DESC, InvoiceNo DESC
        ) AS row_num

    FROM online_retail_clean
)
SELECT
    CustomerID,
    Country
FROM ranked_customers
WHERE row_num = 1;

SELECT COUNT(*) AS customer_count
FROM customers;

-- ============================================================
-- PRODUCTS TABLE
-- One row per product
-- ============================================================
CREATE TABLE products
(
    StockCode   VARCHAR(20) NOT NULL,
    Description VARCHAR(255) NOT NULL,

    PRIMARY KEY (StockCode)
);



INSERT INTO products
(
    StockCode,
    Description
)
WITH ranked_products AS
(
    SELECT
        StockCode,
        Description,

        ROW_NUMBER() OVER
        (
            PARTITION BY StockCode
            ORDER BY InvoiceDate DESC, InvoiceNo DESC
        ) AS row_num

    FROM online_retail_clean
)
SELECT
    StockCode,
    Description
FROM ranked_products
WHERE row_num = 1;

SELECT COUNT(*) AS product_count
FROM products;
-- ============================================================
-- ORDERS TABLE
-- One row per invoice
-- ============================================================

CREATE TABLE orders
(
    InvoiceNo       VARCHAR(20) NOT NULL,
    InvoiceDate     DATETIME NOT NULL,
    CustomerID      VARCHAR(20) NOT NULL,
    transaction_type VARCHAR(10) NOT NULL,

    PRIMARY KEY (InvoiceNo),

    INDEX idx_orders_customer (CustomerID),
    INDEX idx_orders_date (InvoiceDate),

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (CustomerID)
        REFERENCES customers(CustomerID)
);

INSERT INTO orders
(
    InvoiceNo,
    InvoiceDate,
    CustomerID,
    transaction_type
)
SELECT
    InvoiceNo,
    MIN(InvoiceDate) AS InvoiceDate,
    MIN(CustomerID) AS CustomerID,

    CASE
        WHEN InvoiceNo LIKE 'C%' THEN 'Return'
        ELSE 'Sale'
    END AS transaction_type

FROM online_retail_clean

GROUP BY InvoiceNo;

SELECT COUNT(*) AS order_count
FROM orders;

SELECT
    transaction_type,
    COUNT(*) AS order_count
FROM orders
GROUP BY transaction_type;

-- ============================================================
-- ORDER ITEMS TABLE
-- One row per transaction line
-- ============================================================

CREATE TABLE order_items
(
    OrderItemID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    InvoiceNo   VARCHAR(20) NOT NULL,
    StockCode   VARCHAR(20) NOT NULL,
    Quantity    INT NOT NULL,
    UnitPrice   DECIMAL(12,4) NOT NULL,

    PRIMARY KEY (OrderItemID),

    INDEX idx_order_items_invoice (InvoiceNo),
    INDEX idx_order_items_stockcode (StockCode),

    CONSTRAINT fk_order_items_order
        FOREIGN KEY (InvoiceNo)
        REFERENCES orders(InvoiceNo),

    CONSTRAINT fk_order_items_product
        FOREIGN KEY (StockCode)
        REFERENCES products(StockCode)
);

INSERT INTO order_items
(
    InvoiceNo,
    StockCode,
    Quantity,
    UnitPrice
)
SELECT
    InvoiceNo,
    StockCode,
    Quantity,
    UnitPrice
FROM online_retail_clean;


-- ============================================================
-- INDEXES
-- Improve JOIN performance
-- ============================================================

CREATE INDEX idx_orders_customer
ON orders(CustomerID);

CREATE INDEX idx_order_items_invoice
ON order_items(InvoiceNo);

CREATE INDEX idx_order_items_stock
ON order_items(StockCode);

-- ============================================================
-- FOREIGN KEYS
-- Maintain referential integrity
-- ============================================================

ALTER TABLE orders

ADD CONSTRAINT fk_orders_customer

FOREIGN KEY (CustomerID)

REFERENCES customers(CustomerID);



ALTER TABLE order_items

ADD CONSTRAINT fk_order_items_order

FOREIGN KEY (InvoiceNo)

REFERENCES orders(InvoiceNo);



ALTER TABLE order_items

ADD CONSTRAINT fk_order_items_product

FOREIGN KEY (StockCode)

REFERENCES products(StockCode);

-- ============================================================
-- END OF DATABASE SETUP
-- ============================================================