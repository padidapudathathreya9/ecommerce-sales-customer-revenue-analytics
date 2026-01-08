# Import the dataset and do usual exploratory analysis steps like checking the structure & characteristics of the dataset:

# 1.Exploratory Data Analysis (EDA)

#1.1 Data type of all columns in the "customers" table &  Get the time range between which the orders were placed.
select*
from `youtube-483507.Target_SQL.customers`
Limit 10

select*
from `youtube-483507.Target_SQL.geoloaction`
limit 5

# 1.2 Time range of orders
SELECT
  MIN(order_purchase_timestamp) AS first_order_date,
  MAX(order_purchase_timestamp) AS last_order_date
FROM `youtube-483507.Target_SQL.orders`;

#1.3 Count of cities & states of customers who placed orders
SELECT
  COUNT(DISTINCT c.customer_city)  AS total_cities,
  COUNT(DISTINCT c.customer_state) AS total_states
FROM `youtube-483507.Target_SQL.customers` c
JOIN `youtube-483507.Target_SQL.orders` o
ON c.customer_id = o.customer_id;

# 2 In-Depth Exploration
# 2.1 Year-wise order trend
SELECT
  EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
  COUNT(order_id) AS total_orders
FROM `youtube-483507.Target_SQL.orders`
GROUP BY year
ORDER BY year;

# 2.2 Monthly seasonality of orders
SELECT
  EXTRACT(YEAR FROM order_purchase_timestamp)  AS year,
  EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
  COUNT(order_id) AS total_orders
FROM `youtube-483507.Target_SQL.orders`
GROUP BY year, month
ORDER BY year, month;

# 2.3 Orders by time of day
SELECT
  CASE
    WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 0 AND 6  THEN 'Dawn'
    WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 7 AND 12 THEN 'Morning'
    WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 13 AND 18 THEN 'Afternoon'
    ELSE 'Night'
  END AS time_of_day,
  COUNT(order_id) AS total_orders
FROM `youtube-483507.Target_SQL.orders`
GROUP BY time_of_day
ORDER BY total_orders DESC;

# 3️ Brazil Region – Orders Evolution
# 3.1 Month-on-month orders by state
SELECT
  c.customer_state,
  FORMAT_DATE('%Y-%m', DATE(o.order_purchase_timestamp)) AS year_month,
  COUNT(o.order_id) AS total_orders
FROM `youtube-483507.Target_SQL.orders` o 
JOIN `youtube-483507.Target_SQL.customers` c
ON o.customer_id = c.customer_id
GROUP BY c.customer_state, year_month
ORDER BY c.customer_state, year_month;

# 3.2 Customer distribution by state
SELECT
  customer_state,
  COUNT(DISTINCT customer_id) AS total_customers
FROM `youtube-483507.Target_SQL.customers`
GROUP BY customer_state
ORDER BY total_customers DESC;

# 4️ Impact on Economy (Money Flow)
# 4.1 % increase in order cost (2017 → 2018, Jan–Aug)

WITH yearly_cost AS (
  SELECT
    EXTRACT(YEAR FROM o.order_purchase_timestamp) AS year,
    SUM(p.payment_value) AS total_cost
  FROM `youtube-483507.Target_SQL.orders` o
  JOIN `youtube-483507.Target_SQL.Payments` p
    ON o.order_id = p.order_id
  WHERE EXTRACT(MONTH FROM o.order_purchase_timestamp) BETWEEN 1 AND 8
    AND EXTRACT(YEAR FROM o.order_purchase_timestamp) IN (2017, 2018)
  GROUP BY year
)

SELECT
  ROUND(
    (MAX(CASE WHEN year = 2018 THEN total_cost END) -
     MAX(CASE WHEN year = 2017 THEN total_cost END))
    / MAX(CASE WHEN year = 2017 THEN total_cost END) * 100,
    2
  ) AS percentage_increase
FROM yearly_cost;

# 4.2 Total & Average order price per state
SELECT
  c.customer_state,
  ROUND(SUM(oi.price),2) AS total_order_price,
  ROUND(AVG(oi.price),2) AS avg_order_price
FROM `youtube-483507.Target_SQL.order_items` oi
JOIN `youtube-483507.Target_SQL.orders` o
ON oi.order_id = o.order_id
JOIN `youtube-483507.Target_SQL.customers` c
ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY total_order_price DESC;

# 4.3 Total & Average freight per state
SELECT
  c.customer_state,
  ROUND(SUM(oi.freight_value),2) AS total_freight,
  ROUND(AVG(oi.freight_value),2) AS avg_freight
FROM `youtube-483507.Target_SQL.order_items` oi
JOIN `youtube-483507.Target_SQL.orders` o
ON oi.order_id = o.order_id
JOIN `youtube-483507.Target_SQL.customers` c
ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY total_freight DESC;

# 5️ Sales, Freight & Delivery Performance
# 5.1 Delivery time & delay (single query)
SELECT
  order_id,
  DATE_DIFF(order_delivered_customer_date, order_purchase_timestamp, DAY)
    AS time_to_deliver,
  DATE_DIFF(order_delivered_customer_date, order_estimated_delivery_date, DAY)
    AS diff_estimated_delivery
FROM `youtube-483507.Target_SQL.orders`
WHERE order_delivered_customer_date IS NOT NULL;

# 5.2 Top 5 states – highest & lowest average freight
WITH freight AS (
  SELECT
    c.customer_state,
    AVG(oi.freight_value) AS avg_freight
  FROM `youtube-483507.Target_SQL.order_items` oi
JOIN `youtube-483507.Target_SQL.orders` o
ON oi.order_id = o.order_id
JOIN `youtube-483507.Target_SQL.customers` c
  ON o.customer_id = c.customer_id
  GROUP BY c.customer_state
)
SELECT * FROM freight
ORDER BY avg_freight DESC
LIMIT 5;

# 5.3 Top 5 states – highest & lowest delivery time
WITH delivery AS (
  SELECT
    c.customer_state,
    AVG(DATE_DIFF(o.order_delivered_customer_date,
                  o.order_purchase_timestamp, DAY)) AS avg_delivery_time
  FROM `youtube-483507.Target_SQL.orders` o 
JOIN `youtube-483507.Target_SQL.customers` c
  ON o.customer_id = c.customer_id
  WHERE o.order_delivered_customer_date IS NOT NULL
  GROUP BY c.customer_state
)
SELECT * FROM delivery
ORDER BY avg_delivery_time DESC
LIMIT 5;

# 5.4 Fastest delivery vs estimated date
SELECT
  c.customer_state,
  AVG(DATE_DIFF(o.order_estimated_delivery_date,
                o.order_delivered_customer_date, DAY)) AS delivery_gain_days
FROM `youtube-483507.Target_SQL.orders` o 
JOIN `youtube-483507.Target_SQL.customers` c
ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY delivery_gain_days DESC
LIMIT 5;

# 6️ Payment Analysis
# 6.1 Month-on-month orders by payment type
SELECT
  FORMAT_DATE('%Y-%m', DATE(o.order_purchase_timestamp)) AS year_month,
  p.payment_type,
  COUNT(DISTINCT o.order_id) AS total_orders
FROM `youtube-483507.Target_SQL.orders` o
  JOIN `youtube-483507.Target_SQL.Payments` p
ON o.order_id = p.order_id
GROUP BY year_month, p.payment_type
ORDER BY year_month;


# 6.2 Orders by payment installments
SELECT
  payment_installments,
  COUNT(DISTINCT order_id) AS total_orders
FROM `youtube-483507.Target_SQL.Payments`
GROUP BY payment_installments
ORDER BY payment_installments;
















