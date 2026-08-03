-- ============================================================
-- Demonstrate practical advanced SQL techniques using simple,
-- business-focused retail analysis.
--
-- Concepts Used:
-- 1. Common Table Expressions (CTEs)
-- 2. DENSE_RANK()
-- 3. LAG()
-- 4. Running totals with SUM() OVER()
--
-- Source:
-- retail_sales_view
-- ============================================================

USE retail_project;


-- ============================================================
-- 1. CUSTOMER REVENUE RANKING
-- ============================================================
-- Business question:
-- Which customers generate the most net revenue?
--
-- DENSE_RANK assigns customers a revenue rank.
-- Customers with equal revenue receive the same rank.
-- ============================================================

SELECT
    CustomerID,
    Country,
    ROUND(SUM(net_line_revenue), 2) AS net_revenue,

    DENSE_RANK() OVER (
        ORDER BY SUM(net_line_revenue) DESC
    ) AS revenue_rank

FROM retail_sales_view


GROUP BY
    CustomerID,
    Country

ORDER BY
    revenue_rank;
-- ============================================================
-- 2. MONTH-ON-MONTH REVENUE GROWTH
-- ============================================================
-- Business question:
-- Is revenue increasing or decreasing compared with the
-- previous month?
--
-- LAG returns the value from the previous row.
-- ============================================================
WITH monthly_sales AS
(
    SELECT
        invoice_month,
        SUM(net_line_revenue) AS revenue
    FROM retail_sales_view
    GROUP BY invoice_month
)

SELECT
    invoice_month,

    ROUND(revenue,2) AS revenue,

    ROUND(
        LAG(revenue) OVER (
            ORDER BY invoice_month
        ),
        2
    ) AS previous_month,

    ROUND(
        revenue -
        LAG(revenue) OVER (
            ORDER BY invoice_month
        ),
        2
    ) AS revenue_change

FROM monthly_sales;
-- ============================================================
-- 3. RUNNING REVENUE TOTAL
-- ============================================================
-- Business question:
-- How much cumulative revenue has the business generated
-- by the end of each month?
-- ============================================================
WITH monthly_sales AS
(
    SELECT
        invoice_month,
        SUM(net_line_revenue) AS revenue
    FROM retail_sales_view
    GROUP BY invoice_month
)

SELECT

    invoice_month,

    ROUND(revenue,2) AS monthly_revenue,

    ROUND(

        SUM(revenue)

        OVER(

            ORDER BY invoice_month

        ),

        2

    ) AS cumulative_revenue

FROM monthly_sales;