-- The Analysis is based on a denormalized transactional table (pizza_sales) where each row represents a single pizza sold, 
-- including order timing, product attributes and sales metrics. -- This structure simplifies queries by reducing the needs for joins. 

SELECT *
FROM pizza_sales;

-- Data Overview --
DESCRIBE pizza_sales;

-- Check for NULL --
SELECT 
SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,
SUM(CASE WHEN pizza_name_id IS NULL THEN 1 ELSE 0 END) AS null_pizza_name_id,
SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS null_quantity,
SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS null_order_date,
SUM(CASE WHEN order_time IS NULL THEN 1 ELSE 0 END) AS null_order_time,
SUM(CASE WHEN unit_price IS NULL THEN 1 ELSE 0 END) AS null_unit_price,
SUM(CASE WHEN total_price IS NULL THEN 1 ELSE 0 END) AS null_total_price,
SUM(CASE WHEN pizza_size IS NULL THEN 1 ELSE 0 END) AS null_pizza_size,
SUM(CASE WHEN pizza_category IS NULL THEN 1 ELSE 0 END) AS null_pizza_category,
SUM(CASE WHEN pizza_ingredients IS NULL THEN 1 ELSE 0 END) AS null_pizza_ingredients,
SUM(CASE WHEN pizza_name IS NULL THEN 1 ELSE 0 END) AS null_pizza_name
FROM pizza_sales;
-- As Result none of the rows has nulls --

-- Convert Date/Time --
ALTER TABLE pizza_sales
MODIFY order_date date
;
SELECT order_date
FROM pizza_sales;

describe pizza_sales;

SELECT DISTINCT order_date
FROM pizza_sales;

ALTER TABLE pizza_sales
ADD COLUMN clean_order_date DATE;

-- To change Date format --
UPDATE pizza_sales
set clean_order_date = str_to_date(order_date, '%d/%m/%Y')
WHERE order_date LIKE '%/%';

UPDATE pizza_sales
set clean_order_date = str_to_date(order_date, '%d-%m-%Y')
WHERE order_date LIKE '%-%';

SELECT order_date, clean_order_date
FROM pizza_sales;
-- Now all the Date are in the same format (2015-01-07) --

-- Remove the wrong column --
ALTER TABLE pizza_sales
DROP COLUMN order_date;

ALTER TABLE pizza_sales
CHANGE clean_order_date order_date DATE;

SELECT order_date
FROM pizza_sales;

-- Verify if there are values that have not been converted --
SELECT *
FROM pizza_sales
WHERE clean_order_date IS NULL;

-- To know what type of data format we are dealing with --
SELECT DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'pizza_sales';

-- Checking hour format
SELECT DISTINCT order_time 
FROM pizza_sales;
-- Modify the Type
ALTER TABLE pizza_sales
MODIFY COLUMN order_time TIME;
-- Check is all correctly changed
DESCRIBE pizza_sales;
SHOW COLUMNS 
FROM pizza_sales LIKE 'order_time';

-- Check for anomalies
SELECT DISTINCT pizza_name_id
FROM pizza_sales;

SELECT DISTINCT quantity
FROM pizza_sales;

SELECT DISTINCT unit_price
FROM pizza_sales;

SELECT DISTINCT pizza_size
FROM pizza_sales;

SELECT DISTINCT pizza_category
FROM pizza_sales;

SELECT DISTINCT pizza_ingredients
FROM pizza_sales;

SELECT DISTINCT pizza_name
FROM pizza_sales;

-- Check for special characters --
-- Use ESCAPE for character that will otherwise be recognise as string ('%'(any character), '_'(any sequence of character)) --
SELECT DISTINCT pizza_name
FROM pizza_sales
WHERE pizza_name LIKE '%+%'
OR pizza_name LIKE '%/%'
OR pizza_name LIKE '%-%'
OR pizza_name LIKE '%%%' ESCAPE '%'
OR pizza_name LIKE '%#%'
OR pizza_name LIKE '%@%'
OR pizza_name LIKE '%_%' ESCAPE '_';

-- Get rid of extra spaces --
UPDATE pizza_sales
SET pizza_name = TRIM(pizza_name);

-- Set all names in Capital letters --
UPDATE pizza_sales
SET pizza_name = ucase(pizza_name);

SELECT REGEXP_REPLACE(
           LOWER(pizza_name),
           '(^| )([a-z])',
           CONCAT('\\1', UPPER('\\2'))
           ) AS formatted_name
           FROM pizza_sales; -- This didn`t work we need to install this function --
           
-- Install formula in MySQL-- CleanString
DELIMITER $$

CREATE FUNCTION CleanString (input TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN 
     DECLARE cleaned TEXT;
     -- Remove extra-space --
SET cleaned = TRIM(input);
  -- Multiple spaces replace with a single one --
SET cleaned = REPLACE (cleaned, '  ', ' ');
  -- Convert special characters in space --
SET cleaned = REPLACE(cleaned, '+', ' + ');
  -- Trim extra spaces created from previous formulas --
SET cleaned = REPLACE(cleaned, '   ', ' ');

RETURN cleaned;
END $$
DELIMITER;

-- Update table with cleaned values --
SELECT pizza_name, 
CleanString(pizza_name) AS Cleaned_PizzaName
FROM pizza_sales;

UPDATE pizza_sales 
SET 
    pizza_name = CLEANSTRING(pizza_name);
           
-- Save the table, Backup --
CREATE TABLE pizza_sales_backup AS SELECT * FROM
    pizza_sales;

SELECT 
    pizza_name
FROM
    pizza_sales;

-- Dataset Business Questions --
-- 1- Which Pizza type generate the highest sales? --
-- 2- What are the peak ordering hours during the day? --
-- 3- Which days of the week are the most profitable? --
-- 4- Are there specific days in the month when pizza sales peak? --
-- 5- Do customers prefer certain pizza size or categories? --
-- 1 - Top selling Pizza type -


SELECT 
    pizza_name, SUM(quantity) AS Total_pizzas
FROM
    pizza_sales
GROUP BY pizza_name
ORDER BY Total_pizzas DESC;
-- Analysis of total sales by Pizza type shows that the Classic Deluxe Pizza generates the highest revenue, with total sales of 2453.
-- It is followed closely by the Barbeque Chichen Pizza with 2432
-- While Hawaiian and Pepperoni Pizzas show similarly strong performance, trailing by only a small margin. --
-- This indicates a strong customer preference for Classic and Meat based pizzas, with limited variance among the top performing products.
-- Small pricing or promotional changes could significantly influence ranking among these leading pizza types. --

-- 2- Peak hours during the day --
SELECT 
      HOUR(order_time) AS Order_hour,
      SUM(quantity) AS Total_pizzas
FROM pizza_sales
GROUP BY HOUR(order_time)
ORDER BY Total_pizzas DESC;
-- Pizza demand shows two clear daily peaks: 
-- A strong lunch peak between 12:00 and 13:00 and the second evening peak between 17:00 and 19:00.
-- Sales decline sharply late at night and are almost negligible during early morning hours. --
-- The patterns highlight critical time windows for staffing, kitchen capacity and delivery operations.
-- Resources should be prioritised during lunch and dinner hours, while early morning and late night operations could be optimised to reduce costs.--

-- 3 - Which day recorded the highest number of orders -- 
SELECT order_date, COUNT(*) AS total_orders 
FROM pizza_sales
GROUP BY order_date
ORDER BY total_orders DESC
;
-- By analysing the daily order volume, we identified 11 June 2015 as the day with the highest number of orders, reaching a total of 261 orders,
-- which rapresents the peak daily demand in the dataset. --
-- This peak may indicate the impact of specific factors, such as promotions, seasonality or special events. 
-- Identifying similar patterns can help the businessreplicate high demand days through targeted marketing or operational planning. --

-- Most Profitable Day 
SELECT order_date, SUM(quantity *total_price) AS total_revenue
FROM pizza_sales
GROUP BY order_date
ORDER BY total_revenue DESC
LIMIT 1;
-- The highest Revenue was recorded on 27 November 2015, with total sale of £ 4,605.95
-- This shows that the day with the highest revenue does not necessarily coincide with the day with the highest number of orders, 
-- suggesting higher average order value on thid date. -- 

-- 4 - Peak Month in a year 
SELECT MONTH(order_date) AS order_month,
    COUNT(order_id) AS total_orders
FROM pizza_sales
GROUP BY order_month
ORDER BY total_orders DESC;
-- July records the highest order volume with 4301 orders, 
-- Followed closely by May (4,239 orders). October show the lowest demand with 3,797 orders.--
-- This pattern suggests seasonal demand, with higher activity during late spring and summer months.

-- 5 - Customers Pizza Size preference -- 
SELECT pizza_size, COUNT(order_id) AS total_orders
FROM pizza_sales
GROUP BY pizza_size
ORDER BY total_orders DESC;
-- Large Pizzas are the most popular size (18,526 orders), followed by Medium (15,385), Small (14,137).
-- Extra-Large (544), Extra-Extra-Large (28) pizzas show very limited demand. 
-- Customers clearly prefer standard portion sizes, indicating that extreme sizes add little value to overall sales.

-- Customers Pizza Category preference --
SELECT pizza_category, COUNT(order_id) AS total_orders
FROM pizza_sales
GROUP BY pizza_category
ORDER BY total_orders DESC;
-- The Classic category is the most popular (14,579), followed by Supreme (11,777), Veggie (11,449) and Chicken (10,815).
-- This indicates a strong customer preference for traditional flavours, while demand remains well distributed across categories.

-- Size and Category interaction --
SELECT pizza_category,
pizza_size, 
COUNT(order_id) AS total_orders
FROM pizza_sales
GROUP BY pizza_category, pizza_size
ORDER BY pizza_category, total_orders DESC;
-- Customer Preferences Insight:
-- Analysis of order data show clear customer preferences both in terms of pizza size and category.
-- Certain size consistently outperform others, indicating a dominanat portion preference. (LARGE)
-- Similarly, specific category attaract a higher share of total orders, highlighting customer taste patterns. (CLASSIC)
-- These insight can support menu optimization, inventory planning and targert promotions focused on the most popular combinations. 

 
 



















