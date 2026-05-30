USE pizza_hut
SELECT *
FROM sys.tables;


SELECT *
FROM order_details

SELECT *
FROM pizza_orders

SELECT *
FROM pizza_types

SELECT *
FROM pizzas 

-- Retrieve the total number of orders placed

SELECT count(*) AS total_order_placed
FROM pizza_orders 

-- Calculate the total revenue generated from pizza sales.

SELECT floor(sum(od.quantity*p.price)) AS total_revenue
FROM order_details AS od
JOIN pizzas AS p ON od.pizza_id = p.pizza_id 

-- Identify the highest-priced pizza.

SELECT max(price) AS high_price
FROM pizzas WITH cte AS
  (SELECT pt.name,
          round((p.price),2) AS Pizza,
          rank() over(
                      ORDER BY p.price DESC) AS rnk
   FROM pizza_types AS pt
   JOIN pizzas AS p ON pt.pizza_type_id = p.pizza_type_id)
SELECT *
FROM cte
WHERE rnk=1 

-- Identify the most common pizza size ordered.

  SELECT count(od.order_id) AS total_count,
         p.size
  FROM order_details AS od
  JOIN pizzas AS p ON od.pizza_id = p.pizza_id
GROUP BY p.size
ORDER BY total_count DESC 

-- List the top 5 most ordered pizza types along with their quantities.

SELECT top 5 pt.name,
           sum(od.quantity) AS total_quantity
FROM order_details AS od
JOIN pizzas AS p ON p.pizza_id = od.pizza_id
JOIN pizza_types AS pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY pt.name
ORDER BY total_quantity DESC 


-- Find the total quantity of each pizza category ordered (this will help us to understand the category which customers prefer the most).

SELECT top 5 pt.category,
           sum(od.quantity) AS total_quantity
FROM order_details AS od
JOIN pizzas AS p ON p.pizza_id = od.pizza_id
JOIN pizza_types AS pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY pt.category
ORDER BY total_quantity DESC 


-- Determine the distribution of orders by hour of the day (at which time the orders are maximum (for inventory management and resource allocation).

SELECT datepart(HOUR, TIME) AS hour_of_the_day,
       count(order_id) AS total_orders
FROM pizza_orders
GROUP BY datepart(HOUR, TIME)
ORDER BY total_orders DESC


-- Find the category-wise distribution of pizzas (to understand customer behaviour).

SELECT category,
       count(distinct(pizza_type_id)) AS total_count
FROM pizza_types
GROUP BY category


-- Group the orders by date and calculate the average number of pizzas ordered per day.
 WITH cte AS
  (SELECT po.date,
          sum(od.quantity) AS total
   FROM pizza_orders AS po
   JOIN order_details AS od ON po.order_id = od.order_id
   GROUP BY po.date)
SELECT avg(total) AS average
FROM cte 


-- using subquery

SELECT avg(total_orders) AS average
FROM
  (SELECT po.date,
          sum(od.quantity) AS total_orders
   FROM pizza_orders AS po
   JOIN order_details AS od ON po.order_id = od.order_id
   GROUP BY po.date) AS total_quantity 
   
   
--Determine the top 3 most ordered pizza types based on revenue 
--(let's see the revenue wise pizza orders to understand from sales perspective which pizza is the best selling)
 
SELECT top 3 pt.name, 
           sum(p.price * od.quantity) AS revenue
FROM pizzas AS p
JOIN pizza_types AS pt ON p.pizza_type_id = pt.pizza_type_id
JOIN order_details AS od ON od.pizza_id = p.pizza_id
GROUP BY pt.name
ORDER BY revenue DESC 


-- Calculate the percentage contribution of each pizza type to total revenue 
-- (to understand % of contribution of each pizza in the total revenue)
 
SELECT pt.name, 
       concat(sum(p.price * od.quantity) / 
                (SELECT sum(p.price * od.quantity) AS revenue
                 FROM order_details AS od
                 JOIN pizzas AS p ON od.pizza_id = p.pizza_id)*100, '%') AS revenue_contribuation_from_pizza
FROM order_details AS od
JOIN pizzas AS p ON od.pizza_id = p.pizza_id
JOIN pizza_types AS pt ON pt.pizza_type_id =p.pizza_type_id
GROUP BY pt.name
ORDER BY revenue_contribuation_from_pizza DESC

-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.

 WITH cte AS
  (SELECT category,
          name,
          cast(sum(quantity*price) AS decimal(10, 2)) AS Revenue
   FROM order_details
   JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
   JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
   GROUP BY category,
            name -- order by category, name, Revenue desc
),
      cte1 AS
  (SELECT category,
          name,
          Revenue,
          rank() OVER (PARTITION BY category
                       ORDER BY Revenue DESC) AS rnk
   FROM cte)
SELECT category,
       name,
       Revenue
FROM cte1
WHERE rnk IN (1,
              2,
              3)
ORDER BY category,
         name,
         Revenue
		 
		 
-- Analyze the cumulative revenue generated over time.
-- use of aggregate window function (to get the cumulative sum)
 WITH cte AS
  (SELECT date AS 'Date',
          cast(sum(quantity*price) AS decimal(10, 2)) AS Revenue
   FROM order_details
   JOIN pizza_orders ON order_details.order_id = pizza_orders.order_id
   JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
   GROUP BY date -- order by [Revenue] desc
)
SELECT Date, Revenue,
             sum(Revenue) OVER (
                                ORDER BY date) AS 'Cumulative Sum'
FROM cte
GROUP BY date, Revenue