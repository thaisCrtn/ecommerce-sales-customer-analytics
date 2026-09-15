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

-- Which product categories generate the most revenue?

SELECT 
    p.category,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue
FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY p.category
ORDER BY revenue DESC;

-- What percentage of total revenue comes from each product category?

WITH category_revenue AS (
    SELECT 
    p.category,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue
FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY p.category
)
SELECT
    category,
    revenue,
    ROUND(revenue / SUM(revenue) OVER () * 100.0, 2) AS percentage_category
FROM category_revenue cr
ORDER BY percentage_category DESC;

-- What is the top-selling product in each category?

WITH product_revenue AS (
    SELECT
        p.category,
        p.product_name,
        ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue
    FROM products p
        JOIN order_items oi ON p.product_id = oi.product_id
        JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status = 'Completed'
    GROUP BY p.category, p.product_name
),
ranked_products AS (
    SELECT 
        category,
        product_name,
        revenue,
        RANK() OVER (
            PARTITION BY category
            ORDER BY revenue DESC
        ) AS product_rank
    FROM product_revenue
)
SELECT 
    category,
    product_name,
    revenue,
    product_rank
FROM ranked_products
WHERE product_rank = 1
ORDER BY category;

-- Which product generates the most revenue in each category?

WITH product_revenue AS (
    SELECT
        p.category,
        p.product_id,
        p.product_name,
        ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue
    FROM products p
        JOIN order_items oi ON p.product_id = oi.product_id
        JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status = 'Completed'
    GROUP BY p.category, p.product_id, p.product_name
),
ranked_products AS (
    SELECT 
        category,
        product_id,
        product_name,
        revenue,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY revenue DESC, product_id
        ) AS product_row_number
    FROM product_revenue
)
SELECT 
    category,
    product_name,
    revenue,
    product_row_number
FROM ranked_products
WHERE product_row_number = 1
ORDER BY category;

-- How do products rank within each category based on revenue?

WITH product_revenue AS (
    SELECT
        p.category,
        p.product_id,
        p.product_name,
        ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue
    FROM products p
        JOIN order_items oi ON p.product_id = oi.product_id
        JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status = 'Completed'
    GROUP BY p.category, p.product_id, p.product_name
),
ranked_products AS (
    SELECT 
        category,
        product_id,
        product_name,
        revenue,
        RANK() OVER (
            PARTITION BY category
            ORDER BY revenue DESC
        ) AS revenue_rank,
        DENSE_RANK() OVER (
            PARTITION BY category
            ORDER BY revenue DESC
        ) AS revenue_dense_rank,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY revenue DESC
        ) AS revenue_row_number
    FROM product_revenue
)
SELECT 
    category,
    product_name,
    revenue,
    revenue_rank,
    revenue_dense_rank,
    revenue_row_number
FROM ranked_products
WHERE revenue_rank <= 5
ORDER BY category, revenue_rank;
