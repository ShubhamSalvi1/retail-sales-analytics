-- ============================================================
-- Objective:
-- Analyse customer behaviour, value and purchasing patterns.
--
-- Source:
-- retail_sales_view
-- ============================================================

USE retail_project;


-- ============================================================
-- 1. TOP 10 CUSTOMERS BY NET REVENUE
-- ============================================================

SELECT
    CustomerID,
    Country,
    COUNT(DISTINCT InvoiceNo) AS total_orders,
    ROUND(SUM(net_line_revenue),2) AS net_revenue
FROM retail_sales_view
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID, Country
ORDER BY net_revenue DESC
LIMIT 10;


-- ============================================================
-- 2. TOP 10 CUSTOMERS BY NUMBER OF ORDERS
-- ============================================================

SELECT
    CustomerID,
    Country,
    COUNT(DISTINCT InvoiceNo) AS total_orders,
    ROUND(SUM(net_line_revenue),2) AS net_revenue
FROM retail_sales_view
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID, Country
ORDER BY total_orders DESC
LIMIT 10;


-- ============================================================
-- 3. CUSTOMER LIFETIME VALUE (CLV)
-- ============================================================

SELECT
    CustomerID,
    Country,
    COUNT(DISTINCT InvoiceNo) AS orders,
    SUM(units_sold) AS units_purchased,
    ROUND(SUM(net_line_revenue),2) AS customer_lifetime_value
FROM retail_sales_view
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID, Country
ORDER BY customer_lifetime_value DESC;


-- ============================================================
-- 4. AVERAGE CUSTOMER SPEND
-- ============================================================

WITH customer_revenue AS
(
    SELECT
        CustomerID,
        SUM(net_line_revenue) AS revenue
    FROM retail_sales_view
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
)

SELECT
    ROUND(AVG(revenue),2) AS average_customer_spend
FROM customer_revenue;


-- ============================================================
-- 5. REPEAT VS ONE-TIME CUSTOMERS
-- ============================================================

WITH customer_orders AS
(
    SELECT
        CustomerID,
        COUNT(DISTINCT InvoiceNo) AS order_count
    FROM retail_sales_view
    WHERE CustomerID IS NOT NULL
      AND InvoiceNo NOT LIKE 'C%'
    GROUP BY CustomerID
)

SELECT
    CASE
        WHEN order_count = 1 THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,

    COUNT(*) AS total_customers

FROM customer_orders

GROUP BY customer_type;


-- ============================================================
-- 6. CUSTOMER REVENUE RANKING
-- ============================================================

SELECT
    CustomerID,
    Country,
    ROUND(SUM(net_line_revenue),2) AS revenue,

    DENSE_RANK() OVER
    (
        ORDER BY SUM(net_line_revenue) DESC
    ) AS revenue_rank

FROM retail_sales_view

WHERE CustomerID IS NOT NULL

GROUP BY CustomerID, Country

ORDER BY revenue_rank;


-- ============================================================
-- 7. CUSTOMER REVENUE CONTRIBUTION
-- ============================================================

WITH customer_sales AS
(
    SELECT
        CustomerID,
        SUM(net_line_revenue) AS revenue
    FROM retail_sales_view
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
),

overall_sales AS
(
    SELECT SUM(revenue) AS total_revenue
    FROM customer_sales
)

SELECT
    cs.CustomerID,

    ROUND(cs.revenue,2) AS revenue,

    ROUND(
        100 * cs.revenue /
        os.total_revenue,
        2
    ) AS revenue_share_pct

FROM customer_sales cs

CROSS JOIN overall_sales os

ORDER BY revenue DESC;


-- ============================================================
-- 8. CUSTOMER SEGMENTATION
-- ============================================================

WITH customer_value AS
(
    SELECT
        CustomerID,
        SUM(net_line_revenue) AS revenue
    FROM retail_sales_view
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
)

SELECT

CustomerID,

ROUND(revenue,2) AS revenue,

CASE

WHEN revenue >= 10000 THEN 'VIP'

WHEN revenue >= 5000 THEN 'High Value'

WHEN revenue >= 1000 THEN 'Medium Value'

ELSE 'Low Value'

END AS customer_segment

FROM customer_value

ORDER BY revenue DESC;


-- ============================================================
-- END OF CUSTOMER ANALYSIS
-- ============================================================