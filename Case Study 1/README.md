# 8 WEEKS SQL Challange - Week 1

 <a href="https://github.com/orkunaran/8weekSQLchallenge_week1/issues">
  <img alt="GitHub issues" src="https://img.shields.io/github/issues/orkunaran/8weekSQLchallenge_week1">
 </a>
 
 
<img src = 'https://8weeksqlchallenge.com/images/case-study-designs/1.png' >
<p>



## WEEK 1 - Danny's Dinner
	
This challenge needs us to determine customer movements with 10 different questions. You may find my approaches to these challenges below. But first let's summarize the challenge description. You can find the link to the challenge [here](https://8weeksqlchallenge.com/case-study-1/).
	
	
## Challenge Description
	
We have 3 tables from a restaurant database: sales, menu and members. Each table includes specific information (see diagram below). Our mission is to assist the restaurant about customers visiting patterns, how much they have spent and their favourite items.

Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.

	
<img src = 'https://miro.medium.com/max/595/1*fEmZXjnIof5BHL_sLGDVUg.png' >
<p>

	
You may find the .sql file that creates the tables in the repository (MySQL).

## Challanges and Solutions

You may find my solutions in MySQL and my intuition on them with some comments.  


**Question-1 : What is the total amount each customer spent at the restaurant?**

Code:
	
``` sql
SELECT
    DISTINCT(customer_id),
    SUM(price) AS total_spendings
FROM sales s
JOIN menu m 
ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY customer_id;
```
**Output**

![1](https://user-images.githubusercontent.com/87641079/196190917-cb5463a5-7972-4da2-89d7-831ea3c06012.png)


**Question-2. How many days has each customer visited the restaurant?**
	
Code:
	
	
``` sql
SELECT
    DISTINCT(customer_id),
    COUNT(*) AS total_no_of_days_visited
FROM sales
GROUP BY customer_id;
```
**Output**

![2](https://user-images.githubusercontent.com/87641079/196192433-6ed9f5df-ef0e-401d-b722-21058ec9d3f5.png)

**Question-3. What was the first item from the menu purchased by each customer?**
	
Code: 
	
```sql
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
```
**Output**

![3](https://user-images.githubusercontent.com/87641079/196192522-c4ef5125-2c82-42d7-a099-34f56b33e4f9.png)

**Question-4. What is the most purchased item on the menu and how many times was it purchased by all customers?**
	
Code:  
	
```sql
SELECT
    product_name,
    COUNT(*) total_no_of_times_purchased
FROM sales s
JOIN menu m 
ON s.product_id = m.product_id
GROUP BY product_name
ORDER BY total_no_of_times_purchased DESC
LIMIT 1;
```
**Output**

![4](https://user-images.githubusercontent.com/87641079/196192581-c87b0645-8f1d-4ff9-8481-efd149f5eb2d.png)

**Question-5. Which item was the most popular for each customer?**
	
Code: 

```sql
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
```
**Output**

![5](https://user-images.githubusercontent.com/87641079/196192635-c3947b86-aa47-4eec-9516-53d977d76944.png)

**Question-6. Which item was purchased first by the customer after they became a member?**
	
Code: 

```sql
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
```
**Output**

![6](https://user-images.githubusercontent.com/87641079/196192686-ab25fb94-5e8d-4536-91c3-ff4fe874f79a.png)

**Question-7. Which item was purchased just before the customer became a member?**
	
Code: 

````sql
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
````
**Output**

![7](https://user-images.githubusercontent.com/87641079/196192738-b1c1ed21-5baf-4048-942e-521b0557c74d.png)

**Question-8. What is the total items and amount spent for each member before they became a member?**

Code: 

````sql
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
````
**Output**

![8](https://user-images.githubusercontent.com/87641079/196192776-f59841af-b161-41af-86ea-01a3bbaf21e3.png)
	
**Question-9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?**
	
Code:
	
````sql
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
````

**Output**

![9](https://user-images.githubusercontent.com/87641079/196192873-f3ac7195-71ce-4950-8640-169b55966d99.png)


**Question-10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?**

Code:  

````sql
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
````
**Output**

![10](https://user-images.githubusercontent.com/87641079/196192929-04f5358e-884c-462f-aa3d-c5c6ca46cacf.png)
						       
##BONUS QUESTIONS

**Recreate the following table.**
						       
````sql
SELECT 
	s.customer_id,
	s.order_date,
        m.product_name,
        m.price,
        CASE 
        WHEN s.order_date >= mem.join_date THEN 'Y'
        ELSE 'N' 
        END AS member
FROM sales s
LEFT JOIN menu m ON m.product_id = s.product_id
LEFT JOIN members mem ON mem.customer_id = s.customer_id
ORDER BY customer_id, order_date, price DESC
````
	
**Rank Members - fill non-members with null**

````sql
WITH membership AS
(
SELECT 
	s.customer_id,
	s.order_date,
        m.product_name,
        m.price,
        CASE 
        WHEN s.order_date >= mem.join_date THEN 'Y'
        ELSE 'N' 
        END AS member
FROM sales s
LEFT JOIN menu m ON m.product_id = s.product_id
LEFT JOIN members mem ON mem.customer_id = s.customer_id
ORDER BY customer_id, order_date, price DESC)
SELECT *, 
CASE WHEN member = 'N' THEN 'null'
ELSE 
RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
END AS ranking
FROM membership
````
