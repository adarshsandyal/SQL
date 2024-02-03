/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant? 
SELECT
  	customer_id, 
    sum(price) as total_price
FROM dannys_diner.sales s 
INNER JOIN dannys_diner.menu m on s.product_id = m.product_id
GROUP BY customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS no_days
FROM dannys_diner.sales s
GROUP BY customer_id;
 
-- 3. What was the first item from the menu purchased by each customer?

SELECT
    DISTINCT product_name,
    customer_id,
    order_date
FROM
    (
        SELECT
            s.customer_id,
            s.order_date,
            m.product_name,
            DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS rnk
        FROM
            dannys_diner.sales s
        INNER JOIN
            dannys_diner.menu m ON s.product_id = m.product_id
    ) s
WHERE
    rnk = 1;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
    product_name,
    s.customer_id,
    COUNT(s.product_id) AS total_purchases
FROM
    dannys_diner.sales s
INNER JOIN
    dannys_diner.menu m ON s.product_id = m.product_id
WHERE
    product_name IN (
        SELECT
            product_name
        FROM
            (
                SELECT
                    m.product_name,
                    COUNT(s.product_id) AS total_purchases
                FROM
                    dannys_diner.sales s
                INNER JOIN
                    dannys_diner.menu m ON s.product_id = m.product_id
                GROUP BY
                    m.product_name
                ORDER BY
                    total_purchases DESC
                LIMIT 1
            ) a
    )
GROUP BY
    customer_id, product_name
ORDER BY
    total_purchases DESC;


-- 5. Which item was the most popular for each customer?
WITH most_ordered AS (
    SELECT
        customer_id,
        product_id,
        COUNT(product_id) AS product_count,
        DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(product_id) DESC) AS rnk
    FROM
        dannys_diner.sales s
    GROUP BY
        customer_id, product_id
)
SELECT
    customer_id,
    product_name
FROM
    most_ordered
INNER JOIN
    dannys_diner.menu m ON most_ordered.product_id = m.product_id
WHERE
    rnk = 1
ORDER BY
    customer_id;
ORDER BY customer_id;

-- 6. Which item was purchased first by the customer after they became a member?

SELECT
    m.customer_id,
    m.join_date,
    menu.product_name,
    MIN(m.order_date) AS first_purchase_date
FROM
    (
        SELECT
            m.customer_id,
            m.join_date,
            s.product_id,
            s.order_date,
            RANK() OVER (PARTITION BY m.customer_id ORDER BY s.order_date) AS rnk
        FROM
            members m
        INNER JOIN
            sales s ON m.customer_id = s.customer_id
        WHERE
            s.order_date >= m.join_date
    ) m
JOIN
    menu ON m.product_id = menu.product_id
WHERE
    rnk = 1
GROUP BY
    m.customer_id, m.join_date, menu.product_name
ORDER BY
    m.customer_id, first_purchase_date;



-- 7. Which item was purchased just before the customer became a member?
SELECT
    m.customer_id,
    m.join_date,
    menu.product_name,
    MIN(m.order_date) AS first_purchase_date
FROM
    (
        SELECT
            m.customer_id,
            m.join_date,
            s.product_id,
            s.order_date,
            RANK() OVER (PARTITION BY m.customer_id ORDER BY s.order_date) AS rnk
        FROM
            members m
        INNER JOIN
            sales s ON m.customer_id = s.customer_id
        WHERE
            s.order_date <= m.join_date
    ) m
JOIN
    menu ON m.product_id = menu.product_id
WHERE
    rnk = 1
GROUP BY
    m.customer_id, m.join_date, menu.product_name
ORDER BY
    m.customer_id, first_purchase_date;
    
    
-- 8. What is the total items and amount spent for each member before they became a member?
SELECT
    m.customer_id,
    COUNT(s.product_id) AS total_items,
    SUM(me.price) AS total_amount_spent
FROM
    members m
LEFT JOIN
    sales s ON m.customer_id = s.customer_id AND s.order_date < m.join_date
LEFT JOIN
    menu me ON s.product_id = me.product_id
GROUP BY
    m.customer_id
ORDER BY
    m.customer_id;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT
    customer_id, 
    sum(CASE WHEN product_name='sushi' THEN price*20 ELSE price*10 END) AS total_amount_spent
FROM
    dannys_diner.sales s
inner JOIN
    dannys_diner.menu me ON s.product_id = me.product_id
group by customer_id
ORDER BY
    customer_id;
    
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT
    s.customer_id,
    SUM(
        CASE 
            WHEN s.order_date NOT BETWEEN m.join_date AND DATE_ADD(m.join_date, INTERVAL 7 DAY) AND product_name = 'sushi' THEN price * 20
            WHEN s.order_date BETWEEN m.join_date AND DATE_ADD(m.join_date, INTERVAL 7 DAY) THEN price * 20
            WHEN s.order_date NOT BETWEEN m.join_date AND DATE_ADD(m.join_date, INTERVAL 7 DAY) AND product_name <> 'sushi' THEN price * 10
            ELSE 0
        END
    ) AS total_amount_spent
FROM
    dannys_diner.sales s
INNER JOIN
    dannys_diner.menu me ON s.product_id = me.product_id
INNER JOIN
    dannys_diner.members m ON s.customer_id = m.customer_id
GROUP BY
    customer_id
ORDER BY
    customer_id;