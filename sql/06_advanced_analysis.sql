WITH customer_rfm AS (

    SELECT
        c.customer_id,
        c.customer_name,

        MAX(o.order_date) AS last_purchase_date,

        DATE '2025-12-31' - MAX(o.order_date) AS recency,

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