-- Who are the top 10 customers by revenue?
SELECT
    c.customer_id,
    C.customer_name,
    round(SUM(oi.quantity * oi.unit_price), 2) AS total_revenue,
    RANK() OVER (ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS revenue_rank
FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.customer_name
ORDER BY revenue_rank
LIMIT 10;

-- Which customers are returning customers?

SELECT c.customer_id,
    c.customer_name,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(DISTINCT o.order_id) >= 2
ORDER BY total_orders DESC;

-- What percentage of customers are returning customers?

WITH customer_order AS (
    SELECT c.customer_id,
           c.customer_name,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM customers c
        JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status = 'Completed'
    GROUP BY c.customer_id, c.customer_name
),
customer_type AS (
    SELECT 
        customer_id,
        CASE
            WHEN total_orders >= 2 THEN 'Returning'
            ELSE 'One-time'
        END AS customer_type

    FROM customer_order
)
SELECT 
    customer_type,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS percentage_of_customers
FROM customer_type
GROUP BY customer_type
ORDER BY percentage_of_customers DESC;

-- How many customers made 1, 2, 3, 4+ completed orders?

WITH customer_orders AS (
    SELECT 
        c.customer_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM orders o
        JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.status = 'Completed'
    GROUP BY c.customer_id
),
order_frequency AS (
    SELECT 
        customer_id,
        CASE 
            WHEN total_orders = 1 THEN '1 order'
            WHEN total_orders = 2 THEN '2 orders'
            WHEN total_orders = 3 THEN '3 orders'
            ELSE '4+ orders'
        END AS frequency
    FROM customer_orders
)
SELECT 
    frequency,
    COUNT (*) AS customer_count
FROM order_frequency
GROUP BY frequency
ORDER BY CASE frequency
        WHEN '1 order' THEN 1
        WHEN '2 orders' THEN 2
        WHEN '3 orders' THEN 3
        ELSE 4
    END;

-- Which customers increased or decreased their spending over time?

WITH customer_monthly_spending AS (
    SELECT
        c.customer_id,
        c.customer_name,
        TO_CHAR(o.order_date, 'YYYY-MM') AS order_month,
        ROUND(SUM(oi.quantity * oi.unit_price), 2) AS monthly_spending
    FROM customers c
        JOIN orders o ON c.customer_id = o.customer_id
        JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY c.customer_id, c.customer_name, TO_CHAR(o.order_date, 'YYYY-MM')
),
customer_spending_with_lag AS (
    SELECT
        customer_id,
        customer_name,
        order_month,
        monthly_spending,
        LAG(monthly_spending) OVER (
            PARTITION BY customer_id
            ORDER BY order_month
        ) AS previous_monthly_spending
    FROM customer_monthly_spending
)
SELECT
    customer_id,
    customer_name,
    order_month,
    monthly_spending,
    previous_monthly_spending,
    ROUND(monthly_spending - previous_monthly_spending, 2) AS spending_change,
    CASE
        WHEN monthly_spending - previous_monthly_spending > 0
            THEN 'Increased'
        WHEN monthly_spending - previous_monthly_spending < 0
            THEN 'Decreased'
        ELSE 'No change'
    END AS spending_trend
FROM customer_spending_with_lag
WHERE previous_monthly_spending IS NOT NULL
ORDER BY customer_id, order_month;

-- When did each customer make their first and last completed purchase?

SELECT 
    c.customer_id,
    c.customer_name,
    MIN(o.order_date) AS first_purchase_date,
    MAX(o.order_date) AS last_purchase_date
FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.customer_name
ORDER BY first_purchase_date;

-- How many days did each customer remain active between their first and last purchase?

SELECT 
    c.customer_id,
    c.customer_name,
    MIN(o.order_date) AS first_purchase_date,
    MAX(o.order_date) AS last_purchase_date,
    (MAX(o.order_date) - MIN(o.order_date)) AS customer_lifetime_days
FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.customer_name
ORDER BY first_purchase_date;

-- Which customers have been active for at least 1 year between their first and last completed purchase?
SELECT 
    c.customer_id,
    c.customer_name,
    MIN(o.order_date) AS first_purchase_date,
    MAX(o.order_date) AS last_purchase_date,
    (MAX(o.order_date) - MIN(o.order_date)) AS customer_lifetime_days
FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.customer_name
HAVING (MAX(o.order_date) - MIN(o.order_date)) >= 365
ORDER BY first_purchase_date;

-- How can we segment customers based on their purchasing behavior?

WITH customer_rfm AS (
    SELECT
        c.customer_id,
        c.customer_name,
        MAX(o.order_date) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(oi.quantity * oi.unit_price), 2) AS monetary_value
    FROM customers c
        JOIN orders o ON c.customer_id = o.customer_id
        JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY c.customer_id, c.customer_name
)
SELECT *
FROM customer_rfm
ORDER BY monetary_value DESC;

-- How many days have passed since each customer's last purchase?

SELECT 
    c.customer_id,
    c.customer_name,
    MAX(o.order_date) AS last_purchase_date,
    (DATE '2025-12-31' - MAX(o.order_date)) AS days_since_last_purchase
FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.customer_name
ORDER BY days_since_last_purchase DESC;
