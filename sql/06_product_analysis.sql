-- ============================================================
-- Objective:
-- Analyse product sales, revenue, returns and contribution
-- to overall business performance.
--
-- Source:
-- retail_sales_view
--
-- Important:
-- This script contains SELECT queries only.
-- It does not modify the database.
-- ============================================================

USE retail_project;


-- ============================================================
-- 1. TOP 10 PRODUCTS BY NET REVENUE
-- ============================================================

SELECT
    StockCode,
    Description,
    SUM(units_sold) AS units_sold,
    SUM(units_returned) AS units_returned,
    ROUND(SUM(net_line_revenue), 2) AS net_revenue
FROM retail_sales_view
GROUP BY StockCode, Description
ORDER BY net_revenue DESC
LIMIT 10;


-- ============================================================
-- 2. TOP 10 PRODUCTS BY UNITS SOLD
-- ============================================================

SELECT
    StockCode,
    Description,
    SUM(units_sold) AS total_units_sold,
    ROUND(SUM(gross_sales_revenue), 2) AS gross_sales_revenue,
    ROUND(SUM(net_line_revenue), 2) AS net_revenue
FROM retail_sales_view
GROUP BY StockCode, Description
ORDER BY total_units_sold DESC
LIMIT 10;


-- ============================================================
-- 3. TOP 10 PRODUCTS BY NUMBER OF SALES ORDERS
-- ============================================================
-- Measures how frequently each product appears across invoices.

SELECT
    StockCode,
    Description,
    COUNT(DISTINCT InvoiceNo) AS sales_order_count,
    SUM(units_sold) AS units_sold,
    ROUND(SUM(gross_sales_revenue), 2) AS gross_sales_revenue
FROM retail_sales_view
WHERE InvoiceNo NOT LIKE 'C%'
  AND units_sold > 0
GROUP BY StockCode, Description
ORDER BY sales_order_count DESC
LIMIT 10;


-- ============================================================
-- 4. TOP 10 PRODUCTS BY RETURNED UNITS
-- ============================================================

SELECT
    StockCode,
    Description,
    SUM(units_returned) AS returned_units,
    ROUND(SUM(return_value), 2) AS returned_revenue,
    COUNT(DISTINCT CASE
        WHEN transaction_type = 'Return' THEN InvoiceNo
    END) AS return_invoice_count
FROM retail_sales_view
GROUP BY StockCode, Description
HAVING SUM(units_returned) > 0
ORDER BY returned_units DESC
LIMIT 10;


-- ============================================================
-- 5. TOP 10 PRODUCTS BY RETURN VALUE
-- ============================================================

SELECT
    StockCode,
    Description,
    SUM(units_returned) AS returned_units,
    ROUND(SUM(return_value), 2) AS return_value
FROM retail_sales_view
GROUP BY StockCode, Description
HAVING SUM(return_value) > 0
ORDER BY return_value DESC
LIMIT 10;


-- ============================================================
-- 6. PRODUCT QUANTITY RETURN RATE
-- ============================================================
-- Formula:
-- returned units / sold units
--
-- Products with no positive sales are excluded to prevent
-- division by zero and misleading rates.
-- ============================================================

SELECT
    StockCode,
    Description,
    SUM(units_sold) AS units_sold,
    SUM(units_returned) AS units_returned,

    ROUND(
        100.0 * SUM(units_returned)
        / NULLIF(SUM(units_sold), 0),
        2
    ) AS quantity_return_rate_pct

FROM retail_sales_view

GROUP BY StockCode, Description

HAVING SUM(units_sold) > 0

ORDER BY quantity_return_rate_pct DESC,
         units_returned DESC;


-- ============================================================
-- 7. HIGH-RETURN PRODUCTS WITH MEANINGFUL SALES VOLUME
-- ============================================================
-- Filters out products with very low sales volume.
-- The threshold can be adjusted later.
-- ============================================================

SELECT
    StockCode,
    Description,
    SUM(units_sold) AS units_sold,
    SUM(units_returned) AS units_returned,

    ROUND(
        100.0 * SUM(units_returned)
        / NULLIF(SUM(units_sold), 0),
        2
    ) AS quantity_return_rate_pct,

    ROUND(SUM(net_line_revenue), 2) AS net_revenue

FROM retail_sales_view

GROUP BY StockCode, Description

HAVING SUM(units_sold) >= 50
   AND SUM(units_returned) > 0

ORDER BY quantity_return_rate_pct DESC,
         units_sold DESC

LIMIT 20;


-- ============================================================
-- 8. PRODUCT REVENUE RANKING
-- ============================================================

SELECT
    StockCode,
    Description,
    ROUND(SUM(net_line_revenue), 2) AS net_revenue,

    DENSE_RANK() OVER (
        ORDER BY SUM(net_line_revenue) DESC
    ) AS revenue_rank

FROM retail_sales_view

GROUP BY StockCode, Description

ORDER BY revenue_rank;


-- ============================================================
-- 9. PRODUCT REVENUE CONTRIBUTION
-- ============================================================

WITH product_revenue AS (
    SELECT
        StockCode,
        Description,
        SUM(net_line_revenue) AS net_revenue
    FROM retail_sales_view
    GROUP BY StockCode, Description
),

total_revenue AS (
    SELECT
        SUM(net_revenue) AS business_revenue
    FROM product_revenue
)

SELECT
    pr.StockCode,
    pr.Description,

    ROUND(pr.net_revenue, 2) AS net_revenue,

    ROUND(
        100.0 * pr.net_revenue
        / NULLIF(tr.business_revenue, 0),
        2
    ) AS revenue_share_pct

FROM product_revenue pr

CROSS JOIN total_revenue tr

ORDER BY pr.net_revenue DESC;


-- ============================================================
-- 10. CUMULATIVE PRODUCT REVENUE CONTRIBUTION
-- ============================================================
-- This prepares the data for Pareto analysis.
-- ============================================================

WITH product_revenue AS (
    SELECT
        StockCode,
        Description,
        SUM(net_line_revenue) AS net_revenue
    FROM retail_sales_view
    GROUP BY StockCode, Description
),

ranked_products AS (
    SELECT
        StockCode,
        Description,
        net_revenue,

        SUM(net_revenue) OVER (
            ORDER BY net_revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_revenue,

        SUM(net_revenue) OVER () AS total_revenue

    FROM product_revenue
)

SELECT
    StockCode,
    Description,
    ROUND(net_revenue, 2) AS net_revenue,

    ROUND(
        100.0 * net_revenue
        / NULLIF(total_revenue, 0),
        2
    ) AS individual_revenue_share_pct,

    ROUND(
        100.0 * cumulative_revenue
        / NULLIF(total_revenue, 0),
        2
    ) AS cumulative_revenue_share_pct

FROM ranked_products

ORDER BY net_revenue DESC;


-- ============================================================
-- 11. PARETO PRODUCT CLASSIFICATION
-- ============================================================
-- Products contributing to the first 80% of cumulative revenue
-- are classified as Core Revenue Products.
-- ============================================================

WITH product_revenue AS (
    SELECT
        StockCode,
        Description,
        SUM(net_line_revenue) AS net_revenue
    FROM retail_sales_view
    GROUP BY StockCode, Description
),

ranked_products AS (
    SELECT
        StockCode,
        Description,
        net_revenue,

        SUM(net_revenue) OVER (
            ORDER BY net_revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_revenue,

        SUM(net_revenue) OVER () AS total_revenue

    FROM product_revenue
),

classified_products AS (
    SELECT
        StockCode,
        Description,
        net_revenue,

        100.0 * cumulative_revenue
        / NULLIF(total_revenue, 0) AS cumulative_revenue_pct

    FROM ranked_products
)

SELECT
    StockCode,
    Description,
    ROUND(net_revenue, 2) AS net_revenue,
    ROUND(cumulative_revenue_pct, 2) AS cumulative_revenue_pct,

    CASE
        WHEN cumulative_revenue_pct <= 80
        THEN 'Core Revenue Product'
        ELSE 'Remaining Product'
    END AS pareto_category

FROM classified_products

ORDER BY net_revenue DESC;


-- ============================================================
-- 12. SUMMARY OF PARETO CATEGORIES
-- ============================================================

WITH product_revenue AS (
    SELECT
        StockCode,
        SUM(net_line_revenue) AS net_revenue
    FROM retail_sales_view
    GROUP BY StockCode
),

ranked_products AS (
    SELECT
        StockCode,
        net_revenue,

        SUM(net_revenue) OVER (
            ORDER BY net_revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_revenue,

        SUM(net_revenue) OVER () AS total_revenue

    FROM product_revenue
),

classified_products AS (
    SELECT
        StockCode,
        net_revenue,

        CASE
            WHEN 100.0 * cumulative_revenue
                 / NULLIF(total_revenue, 0) <= 80
            THEN 'Core Revenue Product'
            ELSE 'Remaining Product'
        END AS pareto_category

    FROM ranked_products
)

SELECT
    pareto_category,
    COUNT(*) AS product_count,
    ROUND(SUM(net_revenue), 2) AS category_revenue

FROM classified_products

GROUP BY pareto_category

ORDER BY category_revenue DESC;


-- ============================================================
-- 13. LOW-PERFORMING PRODUCTS
-- ============================================================
-- Products with positive sales but very low net revenue.
-- This can help identify slow-moving inventory.
-- ============================================================

SELECT
    StockCode,
    Description,
    SUM(units_sold) AS units_sold,
    COUNT(DISTINCT InvoiceNo) AS invoice_count,
    ROUND(SUM(net_line_revenue), 2) AS net_revenue

FROM retail_sales_view

GROUP BY StockCode, Description

HAVING SUM(units_sold) > 0
   AND SUM(net_line_revenue) > 0

ORDER BY net_revenue ASC

LIMIT 20;


-- ============================================================
-- 14. PRODUCTS WITH NEGATIVE NET REVENUE
-- ============================================================
-- These products have return value exceeding sales value
-- within the analysed period.
-- ============================================================

SELECT
    StockCode,
    Description,
    SUM(units_sold) AS units_sold,
    SUM(units_returned) AS units_returned,
    ROUND(SUM(gross_sales_revenue), 2) AS gross_sales,
    ROUND(SUM(return_value), 2) AS returned_revenue,
    ROUND(SUM(net_line_revenue), 2) AS net_revenue

FROM retail_sales_view

GROUP BY StockCode, Description

HAVING SUM(net_line_revenue) < 0

ORDER BY net_revenue ASC;


-- ============================================================
-- END OF PRODUCT ANALYSIS
-- ============================================================