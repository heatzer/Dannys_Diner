/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

SELECT customer_id, SUM(menu.price) AS Total_Spent
FROM dannys_diner..sales
JOIN menu ON
sales.product_id = menu.product_id
GROUP BY customer_id


-- 2. How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT order_date) AS Days_Attended
FROM dannys_diner..sales
GROUP BY customer_id


-- 3. What was the first item from the menu purchased by each customer?

with RankedEarliestDates AS (
SELECT sales.customer_id, menu.product_name , sales.order_date,
	RANK() OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date) AS rank_by_dates
FROM dannys_diner..sales
JOIN menu ON
sales.product_id = menu.product_id
)
SELECT DISTINCT customer_id, product_name, order_date
FROM RankedEarliestDates
WHERE rank_by_dates = 1


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

--	Most Purchased Product was Ramen and was purchased 8 times by all customers
SELECT menu.product_name, COUNT(menu.product_name) AS Times_Purchased
FROM dannys_diner..sales
JOIN menu ON
sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY Times_Purchased DESC


-- 5. Which item was the most popular for each customer?

WITH CTE AS (
SELECT sales.customer_id, menu.product_name, COUNT(menu.product_name) AS Times_Purchased
FROM dannys_diner..sales
JOIN menu ON
sales.product_id = menu.product_id
GROUP BY sales.customer_id, menu.product_name
),
RankedItems AS (
SELECT customer_id, product_name, Times_Purchased,
	RANK() OVER (PARTITION BY customer_id ORDER BY Times_Purchased DESC) AS Popularity
FROM CTE
)
SELECT customer_id, product_name
FROM RankedItems
WHERE Popularity = 1


-- 6. Which item was purchased first by the customer after they became a member?

WITH CTE AS (
	SELECT members.customer_id,
	sales.order_date,
	menu.product_name,
	RANK() OVER (PARTITION BY members.customer_id ORDER BY sales.order_date) AS order_rank
	FROM dannys_diner..members
	JOIN sales ON
	sales.customer_id = members.customer_id
	JOIN menu ON
	sales.product_id = menu.product_id
	WHERE sales.order_date > members.join_date
)
SELECT customer_id, product_name
FROM CTE
WHERE order_rank = 1


-- 7. Which item was purchased just before the customer became a member?

WITH CTE AS (
SELECT members.customer_id,
	sales.order_date,
	menu.product_name,
	RANK() OVER (PARTITION BY members.customer_id ORDER BY sales.order_date DESC) AS order_rank
	FROM dannys_diner..members
	JOIN sales ON
	sales.customer_id = members.customer_id
	JOIN menu ON
	sales.product_id = menu.product_id
	WHERE sales.order_date < members.join_date
)
SELECT customer_id, product_name
FROM CTE
WHERE order_rank = 1


-- 8. What is the total items and amount spent for each member before they became a member?

SELECT sales.customer_id, 
	COUNT(menu.product_name) AS Total_Items, 
	SUM(menu.price) AS Total_Spent
FROM dannys_diner..sales
JOIN menu ON
sales.product_id = menu.product_id
JOIN members ON
sales.customer_id = members.customer_id
WHERE sales.order_date < members.join_date
GROUP BY sales.customer_id


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH CTE AS (
SELECT sales.customer_id, 
	CASE
		WHEN menu.product_name = 'sushi' THEN menu.price*10*2
		ELSE menu.price*10
	END AS Points
FROM dannys_diner..sales
JOIN menu ON
sales.product_id = menu.product_id
JOIN members ON
sales.customer_id = members.customer_id
WHERE sales.order_date > members.join_date
)
SELECT customer_id, SUM(Points) AS TotalPoints
FROM CTE
GROUP BY customer_id


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH CTE AS (
SELECT sales.customer_id,
	members.join_date,
	sales.order_date,
	CASE
		WHEN menu.product_name = 'sushi' THEN menu.price*10*2
		ELSE menu.price*10
	END AS Points
FROM dannys_diner..sales
JOIN menu ON
sales.product_id = menu.product_id
JOIN members ON
sales.customer_id = members.customer_id
WHERE sales.order_date > members.join_date
),
FirstWeekBonus AS (
	SELECT customer_id,
	CASE
		WHEN order_date <= DATEADD(DAY, 7, join_date) THEN Points*2
		ELSE Points
		END TotalPoints
	FROM CTE
)
SELECT customer_id, SUM(TotalPoints) AS Points_with_first_week_promo
FROM FirstWeekBonus
GROUP BY customer_id
