-- ============================================================
--
-- Objective:
-- Analyse overall business performance using sales, revenue,
-- orders, customers, products, returns and country-level KPIs.
--
-- Source:
-- retail_sales_view
--
-- Important:
-- This script contains SELECT queries only.
-- It does not modify the database.
-- Run each query separately in MySQL Workbench.
-- ============================================================

USE retail_project;


-- ============================================================
-- 1. OVERALL BUSINESS KPIs
-- ============================================================
-- Business question:
-- What is the overall size and performance of the business?
--
-- Notes:
-- total_orders includes both sales and return invoices.
-- net_units reflects sales minus returned units.
-- net_revenue reflects gross sales minus returns.
-- ============================================================

SELECT
    COUNT(DISTINCT InvoiceNo) AS total_orders,
    COUNT(DISTINCT CustomerID) AS total_customers,
    COUNT(DISTINCT StockCode) AS total_products,
    SUM(units_sold) AS total_units_sold,
    SUM(units_returned) AS total_units_returned,
    SUM(Quantity) AS net_units,
    ROUND(SUM(gross_sales_revenue), 2) AS gross_sales_revenue,
    ROUND(SUM(return_value), 2) AS returned_revenue,
    ROUND(SUM(net_line_revenue), 2) AS net_revenue
FROM retail_sales_view;


-- ============================================================
-- 2. SALES ORDERS AND RETURN ORDERS
-- ============================================================
-- Business question:
-- How many invoices represent sales and how many represent
-- returns or cancellations?
--
-- Invoice numbers beginning with C usually represent cancelled
-- or returned transactions in this dataset.
-- ============================================================

SELECT
    CASE
        WHEN InvoiceNo LIKE 'C%' THEN 'Return Invoice'
        ELSE 'Sales Invoice'
    END AS invoice_type,

    COUNT(DISTINCT InvoiceNo) AS invoice_count

FROM retail_sales_view

GROUP BY
    CASE
        WHEN InvoiceNo LIKE 'C%' THEN 'Return Invoice'
        ELSE 'Sales Invoice'
    END;


-- ============================================================
-- 3. REVENUE RETURN RATE
-- ============================================================
-- Business question:
-- What percentage of gross sales value was lost through returns?
--
-- Formula:
-- returned revenue / gross sales revenue
-- ============================================================

SELECT
    ROUND(SUM(gross_sales_revenue), 2) AS gross_sales_revenue,

    ROUND(SUM(return_value), 2) AS returned_revenue,

    ROUND(
        100.0 * SUM(return_value)
        / NULLIF(SUM(gross_sales_revenue), 0),
        2
    ) AS revenue_return_rate_pct

FROM retail_sales_view;


-- ============================================================
-- 4. QUANTITY RETURN RATE
-- ============================================================
-- Business question:
-- What percentage of sold units were returned?
-- ============================================================

SELECT
    SUM(units_sold) AS units_sold,

    SUM(units_returned) AS units_returned,

    ROUND(
        100.0 * SUM(units_returned)
        / NULLIF(SUM(units_sold), 0),
        2
    ) AS quantity_return_rate_pct

FROM retail_sales_view;


-- ============================================================
-- 5. AVERAGE ORDER VALUE
-- ============================================================
-- Business question:
-- How much net revenue does the business generate per invoice?
--
-- Step 1:
-- Calculate the net value of each invoice.
--
-- Step 2:
-- Calculate the average across all invoices.
--
-- This method is more accurate than dividing line-level
-- revenue by the number of invoice rows.
-- ============================================================

WITH invoice_totals AS (
    SELECT
        InvoiceNo,
        ROUND(SUM(net_line_revenue), 2) AS invoice_revenue
    FROM retail_sales_view
    GROUP BY InvoiceNo
)

SELECT
    COUNT(*) AS invoice_count,

    ROUND(
        AVG(invoice_revenue),
        2
    ) AS average_order_value,

    ROUND(
        MIN(invoice_revenue),
        2
    ) AS minimum_invoice_value,

    ROUND(
        MAX(invoice_revenue),
        2
    ) AS maximum_invoice_value

FROM invoice_totals;


-- ============================================================
-- 6. AVERAGE SALES ORDER VALUE
-- ============================================================
-- Business question:
-- What is the average value of a successful sales invoice,
-- excluding return invoices?
--
-- This is usually more useful operationally than calculating
-- the average across both positive and negative invoices.
-- ============================================================

WITH sales_invoice_totals AS (
    SELECT
        InvoiceNo,
        SUM(gross_sales_revenue) AS invoice_sales_value
    FROM retail_sales_view
    WHERE InvoiceNo NOT LIKE 'C%'
    GROUP BY InvoiceNo
)

SELECT
    COUNT(*) AS sales_invoice_count,

    ROUND(
        AVG(invoice_sales_value),
        2
    ) AS average_sales_order_value

FROM sales_invoice_totals;


-- ============================================================
-- 7. AVERAGE BASKET SIZE
-- ============================================================
-- Business question:
-- How many units are purchased in an average sales order?
--
-- Returns are excluded so that negative quantities do not
-- distort normal customer purchasing behaviour.
-- ============================================================

WITH sales_invoice_units AS (
    SELECT
        InvoiceNo,
        SUM(units_sold) AS invoice_units
    FROM retail_sales_view
    WHERE InvoiceNo NOT LIKE 'C%'
    GROUP BY InvoiceNo
)

SELECT
    COUNT(*) AS sales_invoice_count,

    ROUND(
        AVG(invoice_units),
        2
    ) AS average_units_per_order

FROM sales_invoice_units;


-- ============================================================
-- 8. AVERAGE NUMBER OF PRODUCT LINES PER ORDER
-- ============================================================
-- Business question:
-- How many distinct product types appear in an average invoice?
--
-- This measures basket variety, while average basket size
-- measures the number of physical units purchased.
-- ============================================================

WITH invoice_product_lines AS (
    SELECT
        InvoiceNo,
        COUNT(DISTINCT StockCode) AS distinct_products
    FROM retail_sales_view
    WHERE InvoiceNo NOT LIKE 'C%'
    GROUP BY InvoiceNo
)

SELECT
    ROUND(
        AVG(distinct_products),
        2
    ) AS average_distinct_products_per_order

FROM invoice_product_lines;


-- ============================================================
-- 9. CUSTOMER PURCHASE FREQUENCY
-- ============================================================
-- Business question:
-- How many sales orders does the average customer place?
--
-- Only successful sales invoices are included.
-- ============================================================

WITH customer_orders AS (
    SELECT
        CustomerID,
        COUNT(DISTINCT InvoiceNo) AS order_count
    FROM retail_sales_view
    WHERE InvoiceNo NOT LIKE 'C%'
      AND CustomerID IS NOT NULL
    GROUP BY CustomerID
)

SELECT
    COUNT(*) AS purchasing_customers,

    ROUND(
        AVG(order_count),
        2
    ) AS average_orders_per_customer,

    MAX(order_count) AS highest_customer_order_count

FROM customer_orders;


-- ============================================================
-- 10. COUNTRY PERFORMANCE
-- ============================================================
-- Business question:
-- Which countries generate the most sales and revenue?
--
-- Net revenue includes returns.
-- Results are sorted by net revenue.
-- ============================================================

SELECT
    Country,

    COUNT(DISTINCT InvoiceNo) AS total_orders,

    COUNT(DISTINCT CustomerID) AS total_customers,

    SUM(units_sold) AS units_sold,

    SUM(units_returned) AS units_returned,

    ROUND(
        SUM(gross_sales_revenue),
        2
    ) AS gross_sales_revenue,

    ROUND(
        SUM(return_value),
        2
    ) AS returned_revenue,

    ROUND(
        SUM(net_line_revenue),
        2
    ) AS net_revenue

FROM retail_sales_view

WHERE Country IS NOT NULL

GROUP BY Country

ORDER BY net_revenue DESC;


-- ============================================================
-- 11. COUNTRY PERFORMANCE EXCLUDING UNITED KINGDOM
-- ============================================================
-- Business question:
-- Which international markets perform best outside the main
-- domestic market?
--
-- The United Kingdom dominates this dataset, so excluding it
-- makes smaller international markets easier to compare.
-- ============================================================

SELECT
    Country,

    COUNT(DISTINCT InvoiceNo) AS total_orders,

    COUNT(DISTINCT CustomerID) AS total_customers,

    ROUND(
        SUM(net_line_revenue),
        2
    ) AS net_revenue

FROM retail_sales_view

WHERE Country IS NOT NULL
  AND Country <> 'United Kingdom'

GROUP BY Country

ORDER BY net_revenue DESC

LIMIT 15;


-- ============================================================
-- 12. REVENUE CONCENTRATION BY COUNTRY
-- ============================================================
-- Business question:
-- What percentage of total revenue comes from each country?
--
-- This helps identify whether the business is overly dependent
-- on one geographic market.
-- ============================================================

WITH country_revenue AS (
    SELECT
        Country,
        SUM(net_line_revenue) AS net_revenue
    FROM retail_sales_view
    WHERE Country IS NOT NULL
    GROUP BY Country
),

total_revenue AS (
    SELECT
        SUM(net_revenue) AS business_revenue
    FROM country_revenue
)

SELECT
    cr.Country,

    ROUND(
        cr.net_revenue,
        2
    ) AS net_revenue,

    ROUND(
        100.0 * cr.net_revenue
        / NULLIF(tr.business_revenue, 0),
        2
    ) AS revenue_share_pct

FROM country_revenue cr

CROSS JOIN total_revenue tr

ORDER BY cr.net_revenue DESC;


-- ============================================================
-- 13. MONTHLY BUSINESS PERFORMANCE
-- ============================================================
-- Business question:
-- How do orders, customers, units and revenue change by month?
--
-- invoice_month is formatted as YYYY-MM, so alphabetical
-- ordering also produces correct chronological ordering.
-- ============================================================

SELECT
    invoice_month,

    COUNT(DISTINCT InvoiceNo) AS total_orders,

    COUNT(DISTINCT CustomerID) AS active_customers,

    SUM(units_sold) AS units_sold,

    SUM(units_returned) AS units_returned,

    ROUND(
        SUM(gross_sales_revenue),
        2
    ) AS gross_sales_revenue,

    ROUND(
        SUM(return_value),
        2
    ) AS returned_revenue,

    ROUND(
        SUM(net_line_revenue),
        2
    ) AS net_revenue

FROM retail_sales_view

WHERE InvoiceDate IS NOT NULL

GROUP BY invoice_month

ORDER BY invoice_month;


-- ============================================================
-- 14. TRANSACTION TYPE SUMMARY
-- ============================================================
-- Business question:
-- How are transaction lines divided between sales and returns?
-- ============================================================

SELECT
    transaction_type,

    COUNT(*) AS transaction_lines,

    COUNT(DISTINCT InvoiceNo) AS invoices,

    SUM(Quantity) AS signed_quantity,

    ROUND(
        SUM(net_line_revenue),
        2
    ) AS signed_revenue

FROM retail_sales_view

GROUP BY transaction_type;


-- ============================================================
-- 15. BUSINESS KPI SUMMARY IN ONE ROW
-- ============================================================
-- Purpose:
-- Produce a compact output that can later be compared with
-- KPI cards in Power BI.
-- ============================================================

WITH sales_orders AS (
    SELECT
        InvoiceNo,
        SUM(gross_sales_revenue) AS order_value,
        SUM(units_sold) AS order_units
    FROM retail_sales_view
    WHERE InvoiceNo NOT LIKE 'C%'
    GROUP BY InvoiceNo
)

SELECT
    ROUND(
        SUM(rsv.gross_sales_revenue),
        2
    ) AS gross_sales,

    ROUND(
        SUM(rsv.return_value),
        2
    ) AS returned_revenue,

    ROUND(
        SUM(rsv.net_line_revenue),
        2
    ) AS net_revenue,

    COUNT(DISTINCT rsv.InvoiceNo) AS total_invoices,

    COUNT(DISTINCT rsv.CustomerID) AS total_customers,

    COUNT(DISTINCT rsv.StockCode) AS total_products,

    ROUND(
        (
            SELECT AVG(order_value)
            FROM sales_orders
        ),
        2
    ) AS average_sales_order_value,

    ROUND(
        (
            SELECT AVG(order_units)
            FROM sales_orders
        ),
        2
    ) AS average_units_per_sales_order

FROM retail_sales_view rsv;


-- ============================================================
-- END OF BUSINESS ANALYSIS
-- ============================================================