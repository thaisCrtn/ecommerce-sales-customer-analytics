SELECT
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_revenue
FROM orders o
    JOIN order_items oi 
        ON oi.order_id = o.order_id
WHERE o.status = 'Completed';

-- What is the average order value (AOV) for completed orders?
SELECT 
    ROUND(SUM(oi.quantity * oi.unit_price) / COUNT(DISTINCT o.order_id), 2) AS average_order_value
FROM orders o
    JOIN order_items oi
        ON oi.order_id = o.order_id
WHERE o.status = 'Completed';

-- How much revenue does each country generate?
SELECT c.country,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue
FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY c.country
ORDER BY revenue DESC;

-- Which products generate the most revenue?
SELECT
    p.product_id,
    p.product_name,
    p.category,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_revenue,
    DENSE_RANK() OVER (ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS revenue_dense_rank
FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'Completed'
GROUP BY p.product_id, p.product_name, p.category
ORDER BY revenue_dense_rank
LIMIT 10;

-- How does revenue change month over month?
SELECT
    TO_CHAR(o.order_date, 'YYYY-MM') AS order_month,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS monthly_revenue
FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY TO_CHAR(o.order_date, 'YYYY-MM')
ORDER BY order_month;

-- How much did revenue grow or decrease compared with the previous month?

WITH monthly_revenue AS (
    SELECT
        TO_CHAR(o.order_date, 'YYYY-MM') AS order_month,
        ROUND(SUM(oi.quantity * oi.unit_price), 2) AS monthly_revenue
    FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY TO_CHAR(o.order_date, 'YYYY-MM')
),
monthly_revenue_with_lag AS (SELECT
    order_month,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY order_month) AS previous_month_revenue
FROM monthly_revenue
)
SELECT 
    order_month,
    monthly_revenue,
    previous_month_revenue,
    ROUND(monthly_revenue - previous_month_revenue, 2) AS revenue_change,
    TO_CHAR(CASE 
        WHEN previous_month_revenue IS NULL THEN NULL
        ELSE (monthly_revenue - previous_month_revenue) / previous_month_revenue * 100
    END, 'FM999999990.00%') AS revenue_change_percentage
FROM monthly_revenue_with_lag
ORDER BY order_month;

-- What is the cumulative revenue over time?

WITH monthly_revenue AS (
    SELECT 
        TO_CHAR(o.order_date, 'YYYY-MM') AS order_month,
        ROUND(SUM(oi.quantity * oi.unit_price), 2) AS monthly_revenue
    FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY TO_CHAR(o.order_date, 'YYYY-MM')
),
monthly_revenue_with_cumulative AS (
    SELECT
        order_month,
        monthly_revenue,
        SUM(monthly_revenue) OVER (ORDER BY order_month) AS cumulative_revenue
    FROM monthly_revenue
)
SELECT 
    order_month,
    monthly_revenue,
    cumulative_revenue
FROM monthly_revenue_with_cumulative
ORDER BY order_month;