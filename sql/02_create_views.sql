-- ============================================================
--
-- Objective:
-- Create a reusable analytical view by combining the normalized
-- retail tables and adding business-ready calculated columns.
--
-- Source Tables:
-- customers
-- products
-- orders
-- order_items
--
-- Output View:
-- retail_sales_view
--
-- Grain:
-- One row per transaction line
-- ============================================================

USE retail_project;


-- ============================================================
-- VIEW: retail_sales_view
-- ============================================================

CREATE OR REPLACE VIEW retail_sales_view AS

SELECT
    oi.OrderItemID,
    o.InvoiceNo,
    o.InvoiceDate,

    YEAR(o.InvoiceDate) AS invoice_year,
    MONTH(o.InvoiceDate) AS invoice_month_number,
    MONTHNAME(o.InvoiceDate) AS invoice_month_name,
    DATE_FORMAT(o.InvoiceDate, '%Y-%m') AS invoice_month,
    DAYNAME(o.InvoiceDate) AS invoice_weekday,
    HOUR(o.InvoiceDate) AS invoice_hour,

    o.CustomerID,
    c.Country,

    oi.StockCode,
    p.Description,

    oi.Quantity,
    oi.UnitPrice,

    ROUND(
        oi.Quantity * oi.UnitPrice,
        4
    ) AS net_line_revenue,

    o.transaction_type,

    CASE
        WHEN oi.Quantity > 0
        THEN oi.Quantity * oi.UnitPrice
        ELSE 0
    END AS gross_sales_revenue,

    CASE
        WHEN oi.Quantity < 0
        THEN ABS(oi.Quantity * oi.UnitPrice)
        ELSE 0
    END AS return_value,

    CASE
        WHEN oi.Quantity > 0
        THEN oi.Quantity
        ELSE 0
    END AS units_sold,

    CASE
        WHEN oi.Quantity < 0
        THEN ABS(oi.Quantity)
        ELSE 0
    END AS units_returned

FROM order_items oi

INNER JOIN orders o
    ON oi.InvoiceNo = o.InvoiceNo

INNER JOIN customers c
    ON o.CustomerID = c.CustomerID

INNER JOIN products p
    ON oi.StockCode = p.StockCode;
    
-- ============================================================
-- VALIDATION
-- ============================================================

SELECT
    (SELECT COUNT(*) FROM online_retail_clean) AS clean_rows,
    (SELECT COUNT(*) FROM order_items) AS order_item_rows,
    (SELECT COUNT(*) FROM retail_sales_view) AS view_rows;

-- Check that OrderItemID remains unique in the view.

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT OrderItemID) AS unique_order_items
FROM retail_sales_view;

SELECT
    MIN(InvoiceDate) AS first_date,
    MAX(InvoiceDate) AS last_date
FROM retail_sales_view;



-- Preview the final view.

SELECT *
FROM retail_sales_view
LIMIT 20;

SELECT
    (SELECT COUNT(*) FROM online_retail) AS raw_rows,
    (SELECT COUNT(*) FROM online_retail_clean) AS clean_rows,
    (SELECT COUNT(*) FROM customers) AS customers,
    (SELECT COUNT(*) FROM products) AS products,
    (SELECT COUNT(*) FROM orders) AS orders,
    (SELECT COUNT(*) FROM order_items) AS order_items,
    (SELECT COUNT(*) FROM retail_sales_view) AS view_rows;
    

SELECT
    MIN(InvoiceDate) AS first_date,
    MAX(InvoiceDate) AS last_date,
    ROUND(SUM(net_line_revenue), 2) AS total_net_revenue
FROM retail_sales_view;