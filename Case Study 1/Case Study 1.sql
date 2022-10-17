-- Title:-       Case Study #1 - Danny's Diner
-- Created By:-  Mohit Anand
-- Date :-       16-10-2022
-- Tool used:-   MySQL


USE dannys_diner;

/* --------------------
   Case Study Questions
   --------------------*/
   
-- 1. What is the total amount each customer spent at the restaurant?
SELECT
	DISTINCT(customer_id),
    SUM(price) AS total_spendings
FROM sales s
JOIN menu m 
ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT
	DISTINCT(customer_id),
    COUNT(*) AS total_no_of_days_visited
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
SELECT
	customer_id,
    product_name,
    order_date
FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) rn
  FROM sales s
) r
JOIN menu m 
ON r.product_id = m.product_id
WHERE rn = 1
GROUP BY customer_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
    product_name,
    COUNT(*) total_no_of_times_purchased
FROM sales s
JOIN menu m 
ON s.product_id = m.product_id
GROUP BY product_name
ORDER BY total_no_of_times_purchased DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH r AS 
(
SELECT 
	s.customer_id,
    m.product_name,
	COUNT(s.product_id) as count,
	DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS r -- Inspired to use DENSE_RANK() function from Orkun Aran's code
FROM menu m 
JOIN sales s 
ON s.product_id = m.product_id
GROUP BY s.customer_id, s.product_id, m.product_name
) 
SELECT 
	customer_id, 
    product_name, 
    count
FROM r
WHERE r = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH ranks AS
(
SELECT
	s.customer_id,
	m.product_name,
    DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS ranks -- Inspired to use DENSE_RANK() function from Orkun Aran's code
FROM sales s
JOIN menu m ON s.product_id = m.product_id
JOIN members mbr
ON mbr.customer_id = s.customer_id
WHERE s.order_date >= mbr.join_date
)
SELECT * FROM ranks
WHERE ranks = 1;

-- 7. Which item was purchased just before the customer became a member?
WITH ranks AS
(
SELECT 
	s.customer_id,
    s.order_date,
	m.product_name,
    DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS ranks, 
    mbr.join_date
FROM sales s
JOIN menu m ON s.product_id = m.product_id
JOIN members mbr
ON mbr.customer_id = s.customer_id
WHERE s.order_date < mbr.join_date
)
SELECT * FROM ranks
WHERE ranks = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT 
	s.customer_id,
	COUNT(s.product_id) AS total_items, 
	SUM(price) AS spending
FROM sales s
JOIN menu m 
ON m.product_id = s.product_id
JOIN members mbr
ON s.customer_id = mbr.customer_id
WHERE s.order_date < mbr.join_date
GROUP BY s.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH points AS
(
SELECT *,
	CASE
	WHEN m.product_name = 'sushi' THEN price * 20
	WHEN m.product_name != 'sushi' THEN price * 10
    END AS points
FROM menu m
)
SELECT customer_id, SUM(points) AS points
FROM sales s
JOIN points p ON p.product_id = s.product_id
GROUP BY s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT customer_id, SUM(total_points)
FROM 
(WITH points AS
(
SELECT s.customer_id, 
       (s.order_date - mem.join_date) AS first_week,
       m.price,
       m.product_name,
       s.order_date
FROM sales s
JOIN menu m 
ON s.product_id = m.product_id
JOIN members AS mem
ON mem.customer_id = s.customer_id
)
SELECT customer_id,
       order_date,
       CASE 
       WHEN first_week BETWEEN 0 AND 7 THEN price * 20
       WHEN (first_week > 7 OR first_week < 0) AND product_name = 'sushi' THEN price * 20
       WHEN (first_week > 7 OR first_week < 0) AND product_name != 'sushi' THEN price * 10
       END AS total_points
FROM points
WHERE EXTRACT(MONTH FROM order_date) = 1
) as t
GROUP BY customer_id;