-- ============================================================
-- 1. TABLE ROW COUNTS
-- ============================================================

SELECT COUNT(*) AS customer_rows
FROM customers;

SELECT COUNT(*) AS product_rows
FROM products;

SELECT COUNT(*) AS order_rows
FROM orders;

SELECT COUNT(*) AS order_item_rows
FROM order_items;

SELECT COUNT(*) AS retail_sales_view_rows
FROM retail_sales_view;

-- ============================================================
-- 2. PRIMARY KEY VALIDATION
-- ============================================================

SELECT
COUNT(*) AS total_customers,
COUNT(DISTINCT CustomerID) AS unique_customers
FROM customers;


SELECT
COUNT(*) AS total_products,
COUNT(DISTINCT StockCode) AS unique_products
FROM products;


SELECT
COUNT(*) AS total_orders,
COUNT(DISTINCT InvoiceNo) AS unique_orders
FROM orders;


SELECT
COUNT(*) AS total_order_items,
COUNT(DISTINCT OrderItemID) AS unique_order_items
FROM order_items;

-- ============================================================
-- 3. REFERENTIAL INTEGRITY
-- ============================================================

SELECT COUNT(*) AS missing_orders

FROM order_items oi

LEFT JOIN orders o

ON oi.InvoiceNo = o.InvoiceNo

WHERE o.InvoiceNo IS NULL;

-- ============================================================
-- 3. REFERENTIAL INTEGRITY
-- ============================================================

SELECT COUNT(*) AS missing_orders

FROM order_items oi

LEFT JOIN orders o

ON oi.InvoiceNo = o.InvoiceNo

WHERE o.InvoiceNo IS NULL;

SELECT COUNT(*) AS missing_products

FROM order_items oi

LEFT JOIN products p

ON oi.StockCode = p.StockCode

WHERE p.StockCode IS NULL;

SELECT COUNT(*) AS missing_customers

FROM orders o

LEFT JOIN customers c

ON o.CustomerID = c.CustomerID

WHERE o.CustomerID IS NOT NULL

AND c.CustomerID IS NULL;

-- ============================================================
-- 4. JOIN VALIDATION
-- ============================================================

SELECT COUNT(*) AS joined_rows

FROM order_items oi

INNER JOIN orders o

ON oi.InvoiceNo = o.InvoiceNo

INNER JOIN products p

ON oi.StockCode = p.StockCode

LEFT JOIN customers c

ON o.CustomerID = c.CustomerID;

-- ============================================================
-- 5. MISSING VALUE VALIDATION
-- ============================================================

SELECT

SUM(CustomerID IS NULL) AS missing_customer,

SUM(StockCode IS NULL) AS missing_stock,

SUM(Description IS NULL) AS missing_description,

SUM(InvoiceNo IS NULL) AS missing_invoice

FROM retail_sales_view;

-- ============================================================
-- 6. REVENUE VALIDATION
-- ============================================================

SELECT

ROUND(SUM(gross_sales_revenue),2) AS gross_sales,

ROUND(SUM(return_value),2) AS returns,

ROUND(SUM(net_line_revenue),2) AS net_revenue

FROM retail_sales_view;

-- ============================================================
-- 7. VIEW PREVIEW
-- ============================================================

SELECT *

FROM retail_sales_view

LIMIT 20;