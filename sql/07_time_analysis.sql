-- ============================================================
-- Objective:
-- Analyse sales trends over time to identify seasonality,
-- growth patterns, peak selling periods and customer activity.
--
-- Source:
-- retail_sales_view
--
-- This script contains SELECT queries only.
-- ============================================================

USE retail_project;


-- ============================================================
-- 1. MONTHLY SALES PERFORMANCE
-- ============================================================

SELECT
    invoice_month,

    COUNT(DISTINCT InvoiceNo) AS total_orders,

    COUNT(DISTINCT CustomerID) AS active_customers,

    SUM(units_sold) AS units_sold,

    ROUND(SUM(gross_sales_revenue),2) AS gross_sales,

    ROUND(SUM(return_value),2) AS returns,

    ROUND(SUM(net_line_revenue),2) AS net_revenue

FROM retail_sales_view

GROUP BY invoice_month

ORDER BY invoice_month;


-- ============================================================
-- 2. YEARLY SALES PERFORMANCE
-- ============================================================

SELECT

invoice_year,

COUNT(DISTINCT InvoiceNo) AS total_orders,

COUNT(DISTINCT CustomerID) AS active_customers,

ROUND(SUM(net_line_revenue),2) AS net_revenue

FROM retail_sales_view

GROUP BY invoice_year

ORDER BY invoice_year;


-- ============================================================
-- 3. MONTH-ON-MONTH REVENUE GROWTH
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

LAG(revenue) OVER(ORDER BY invoice_month),

2

) AS previous_month,

ROUND(

revenue -
LAG(revenue) OVER(ORDER BY invoice_month),

2

) AS revenue_change

FROM monthly_sales;


-- ============================================================
-- 4. BEST SELLING MONTHS
-- ============================================================

SELECT

invoice_month,

ROUND(SUM(net_line_revenue),2) AS revenue

FROM retail_sales_view

GROUP BY invoice_month

ORDER BY revenue DESC;


-- ============================================================
-- 5. SALES BY WEEKDAY
-- ============================================================

SELECT

invoice_weekday,

COUNT(DISTINCT InvoiceNo) AS orders,

ROUND(SUM(net_line_revenue),2) AS revenue

FROM retail_sales_view

GROUP BY invoice_weekday

ORDER BY FIELD(

invoice_weekday,

'Monday',
'Tuesday',
'Wednesday',
'Thursday',
'Friday',
'Saturday',
'Sunday'

);


-- ============================================================
-- 6. SALES BY HOUR
-- ============================================================

SELECT

invoice_hour,

COUNT(DISTINCT InvoiceNo) AS total_orders,

ROUND(SUM(net_line_revenue),2) AS revenue

FROM retail_sales_view

GROUP BY invoice_hour

ORDER BY invoice_hour;


-- ============================================================
-- 7. PEAK SHOPPING HOURS
-- ============================================================

SELECT

invoice_hour,

COUNT(DISTINCT InvoiceNo) AS invoices,

SUM(units_sold) AS units,

ROUND(SUM(net_line_revenue),2) AS revenue

FROM retail_sales_view

GROUP BY invoice_hour

ORDER BY revenue DESC;


-- ============================================================
-- 8. MONTHLY RETURN ANALYSIS
-- ============================================================

SELECT

invoice_month,

ROUND(SUM(return_value),2) AS returned_revenue,

SUM(units_returned) AS returned_units

FROM retail_sales_view

GROUP BY invoice_month

ORDER BY invoice_month;


-- ============================================================
-- 9. ACTIVE CUSTOMERS BY MONTH
-- ============================================================

SELECT

invoice_month,

COUNT(DISTINCT CustomerID) AS active_customers

FROM retail_sales_view

GROUP BY invoice_month

ORDER BY invoice_month;


-- ============================================================
-- 10. NEW VS RETURNING CUSTOMERS
-- ============================================================

WITH first_purchase AS
(
SELECT

CustomerID,

MIN(invoice_month) AS first_month

FROM retail_sales_view

WHERE CustomerID IS NOT NULL

GROUP BY CustomerID
)

SELECT

f.first_month,

COUNT(*) AS new_customers

FROM first_purchase f

GROUP BY f.first_month

ORDER BY f.first_month;


-- ============================================================
-- 11. MONTHLY AVERAGE ORDER VALUE
-- ============================================================

WITH invoice_totals AS
(
SELECT

invoice_month,

InvoiceNo,

SUM(net_line_revenue) AS invoice_value

FROM retail_sales_view

GROUP BY invoice_month, InvoiceNo
)

SELECT

invoice_month,

ROUND(AVG(invoice_value),2) AS average_order_value

FROM invoice_totals

GROUP BY invoice_month

ORDER BY invoice_month;


-- ============================================================
-- 12. MONTHLY CUSTOMER SPEND
-- ============================================================

SELECT

invoice_month,

ROUND(

SUM(net_line_revenue)/
COUNT(DISTINCT CustomerID),

2

) AS average_customer_spend

FROM retail_sales_view

WHERE CustomerID IS NOT NULL

GROUP BY invoice_month

ORDER BY invoice_month;


-- ============================================================
-- 13. RUNNING REVENUE TOTAL
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

SUM(revenue)

OVER(

ORDER BY invoice_month

),

2

) AS cumulative_revenue

FROM monthly_sales;


-- ============================================================
-- 14. BEST PERFORMING DAY OF WEEK
-- ============================================================

SELECT

invoice_weekday,

ROUND(SUM(net_line_revenue),2) AS revenue,

DENSE_RANK()

OVER(

ORDER BY SUM(net_line_revenue) DESC

) AS weekday_rank

FROM retail_sales_view

GROUP BY invoice_weekday

ORDER BY weekday_rank;


-- ============================================================
-- END OF TIME ANALYSIS
-- ============================================================