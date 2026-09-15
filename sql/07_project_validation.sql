-- ============================================
-- 1. DATASET COUNTS
-- ============================================

SELECT
    (SELECT COUNT(*) FROM customers) AS total_customers,
    (SELECT COUNT(*) FROM products) AS total_products,
    (SELECT COUNT(*) FROM orders) AS total_orders,
    (SELECT COUNT(*) FROM order_items) AS total_order_items;

-- ============================================
-- 2. ORDER STATUS VALIDATION
-- ============================================

SELECT
    status,
    COUNT(*) AS order_count
FROM orders
GROUP BY status
ORDER BY order_count DESC;

-- ============================================
-- 3. COMPLETED ORDERS
-- ============================================

SELECT
    COUNT(*) AS completed_orders
FROM orders
WHERE status = 'Completed';

-- ============================================
-- 4. TOTAL REVENUE
-- ============================================

SELECT
    ROUND(
        SUM(oi.quantity * oi.unit_price),
        2
    ) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.status = 'Completed';

-- ============================================
-- 5. AVERAGE ORDER VALUE
-- ============================================

SELECT
    ROUND(
        SUM(oi.quantity * oi.unit_price)
        / COUNT(DISTINCT o.order_id),
        2
    ) AS average_order_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.status = 'Completed';

-- ============================================
-- 6. RETURNING CUSTOMERS
-- ============================================

WITH customer_orders AS (

    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS completed_orders

    FROM orders

    WHERE status = 'Completed'

    GROUP BY customer_id
)

SELECT
    COUNT(*) AS returning_customers
FROM customer_orders
WHERE completed_orders >= 2;

-- ============================================
-- 6.1 RETURNING CUSTOMER RATE
-- ============================================

WITH customer_orders AS (

    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS completed_orders

    FROM orders

    WHERE status = 'Completed'

    GROUP BY customer_id
),

customer_types AS (

    SELECT
        customer_id,

        CASE
            WHEN completed_orders >= 2
                THEN 'Returning'
            ELSE 'One-time'
        END AS customer_type

    FROM customer_orders
)

SELECT
    customer_type,
    COUNT(*) AS customer_count,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_customers

FROM customer_types

GROUP BY customer_type

ORDER BY customer_count DESC;

-- ============================================
-- 7. RFM SEGMENT DISTRIBUTION
-- ============================================

WITH customer_rfm AS (

    SELECT
        c.customer_id,
        c.customer_name,

        MAX(o.order_date) AS last_purchase_date,

        DATE '2025-12-31'
            - MAX(o.order_date) AS recency,

        COUNT(DISTINCT o.order_id) AS frequency,

        ROUND(
            SUM(oi.quantity * oi.unit_price),
            2
        ) AS monetary_value

    FROM customers c

    JOIN orders o
        ON c.customer_id = o.customer_id

    JOIN order_items oi
        ON o.order_id = oi.order_id

    WHERE o.status = 'Completed'

    GROUP BY
        c.customer_id,
        c.customer_name
),

rfm_scores AS (

    SELECT
        customer_id,
        customer_name,
        last_purchase_date,
        recency,
        frequency,
        monetary_value,

        6 - NTILE(5) OVER (
            ORDER BY recency ASC, customer_id
        ) AS recency_score,

        6 - NTILE(5) OVER (
            ORDER BY frequency DESC, customer_id
        ) AS frequency_score,

        6 - NTILE(5) OVER (
            ORDER BY monetary_value DESC, customer_id
        ) AS monetary_score

    FROM customer_rfm
),

rfm_segments AS (

    SELECT
        customer_id,
        customer_name,
        last_purchase_date,
        recency,
        frequency,
        monetary_value,
        recency_score,
        frequency_score,
        monetary_score,

        recency_score
        + frequency_score
        + monetary_score AS rfm_score,

        CASE
            WHEN (
                recency_score
                + frequency_score
                + monetary_score
            ) >= 13
                THEN 'High Value'

            WHEN (
                recency_score
                + frequency_score
                + monetary_score
            ) >= 10
                THEN 'Engaged'

            WHEN (
                recency_score
                + frequency_score
                + monetary_score
            ) >= 7
                THEN 'Regular'

            ELSE 'At Risk'
        END AS rfm_segment

    FROM rfm_scores
)

SELECT
    rfm_segment,
    COUNT(*) AS customer_count,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_customers

FROM rfm_segments

GROUP BY rfm_segment

ORDER BY
    CASE rfm_segment
        WHEN 'High Value' THEN 1
        WHEN 'Engaged' THEN 2
        WHEN 'Regular' THEN 3
        WHEN 'At Risk' THEN 4
    END;

-- ============================================
-- 8.1 ORPHAN ORDER ITEMS
-- Expected result: 0
-- ============================================

SELECT COUNT(*) AS orphan_order_items
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- ============================================
-- 8.2 ORPHAN PRODUCTS
-- Expected result: 0
-- ============================================

SELECT COUNT(*) AS orphan_product_items
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;