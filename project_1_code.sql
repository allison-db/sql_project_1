-- User Growth --- 
Select 
	year(order_purchase_timestamp) AS "YEAR",
    month(order_purchase_timestamp) AS "MONTH",
    count(*) AS TOTAL_ORDERS
From orders
Group By YEAR, MONTH
order by YEAR desc, MONTH DESC;

-- CORRECT USER GROWTH 
SELECT
	year(order_purchase_timestamp) AS YEAR,
    month(order_purchase_timestamp) AS MONTH,
    count(customer_id) AS n_customers
From orders3
Group By YEAR, MONTH
order by YEAR desc, MONTH DESC;

-- products in products table --
select * from products;
Select DISTINCT count(product_id)
	From products;
    -- 32951 products

-- Categories with the most products --
Select
	product_category_name AS 'Category',
    count(*) AS 'Products'
From products
Group by Category
Order by Products desc;

-- How many products were present in actual transactions?
SELECT 
	count(DISTINCT product_id) AS n_products
From
	order_items;

-- most expensive vs cheapest product
SELECT 
	min(price),
    max(price)
From order_items;

-- payment values
SELECT 	
	min(payment_value),
    max(payment_value)
FROM order_payments
WHERE payment_value IS NOT NULL;

-- tech product categories
SELECT 
    product_category_name_english AS Category
FROM 
	product_category_name_translation;

-- # of products sold in tech CREATED tech_categories
CREATE TABLE tech_categories
AS
SELECT 
	product_category_name AS Category,
    Count(*) AS products_available
FROM products
WHERE product_category_name IN ('audio', 'eletronicos', 'informatica_acessorios', 'pc_gamer', 'pcs', 'tablets_impressao_imagem', 'telefonia')
GROUP BY Category
	Order by products_available desc;

select * from tech_categories;
-- percentage of tech in overall
SELECT 
	product_category_name AS categories,
    products_available,
    count(order_items.product_id) AS products_sold
FROM products
	Right JOIN tech_categories ON products.product_category_name = tech_categories.Category
    Right JOIN order_items ON products.product_id = order_items.product_id
WHERE product_category_name IN ('audio', 'eletronicos', 'informatica_acessorios', 'pc_gamer', 'pcs', 'tablets_impressao_imagem', 'telefonia')
GROUP BY categories, products_available
	ORDER BY products_sold desc;

-- temp table
CREATE TEMPORARY TABLE temp_per AS
SELECT 
	product_category_name AS categories,
    products_available,
    count(order_items.product_id) AS products_sold
FROM products
	Right JOIN tech_categories ON products.product_category_name = tech_categories.Category
    Right JOIN order_items ON products.product_id = order_items.product_id
WHERE product_category_name IN ('audio', 'eletronicos', 'informatica_acessorios', 'pc_gamer', 'pcs', 'tablets_impressao_imagem', 'telefonia')
GROUP BY categories, products_available
	Order by products_sold desc;

-- avg of cat in total sales
SELECT
	categories,
    products_available,
    products_sold,
    ROUND(((products_sold/32951) * 100),2) AS percent_total
FROM temp_per;

Select sum(products_sold) FROM temp_per;

-- avg price of items
SELECT ROUND(AVG(price),2) FROM order_items;

-- count sellers
select count(*) from sellers;

-- num of tech sellers
SELECT 
	product_category_name AS categories,
    count(DISTINCT order_items.seller_id) AS sellers
FROM products
	INNER JOIN order_items ON products.product_id = order_items.product_id
    INNER JOIN sellers ON order_items.seller_id = sellers.seller_id
WHERE product_category_name IN ('audio', 'eletronicos', 'informatica_acessorios', 'pc_gamer', 'pcs', 'tablets_impressao_imagem', 'telefonia')
GROUP BY categories
	Order by sellers desc;
    
-- earned by all sellers
CREATE TEMPORARY TABLE temp_profit AS
SELECT 
	product_category_name AS categories,
	Round(SUM(price),2) AS profit
FROM order_items
	Inner Join products
		ON 	products.product_id = order_items.product_id
WHERE product_category_name IN ('audio', 'eletronicos', 'informatica_acessorios', 'pc_gamer', 'pcs', 'tablets_impressao_imagem', 'telefonia')
GROUP BY categories
	Order by profit desc;
    
-- sum of tech profits
SELECT
	ROUND(SUM(profit),2)
FROM temp_profit;

SELECT * FROM tech_profit;

SELECT 
	product_category_name AS categories,
	Round(SUM(price),2) AS profit
FROM order_items
	Inner Join products
		ON 	products.product_id = order_items.product_id
WHERE product_category_name IN ('audio', 'eletronicos', 'informatica_acessorios', 'pc_gamer', 'pcs', 'tablets_impressao_imagem', 'telefonia')
GROUP BY categories
	Order by profit desc;

-- average monthly income
SELECT
	ROUND(AVG(monthly_income),2) AS avg_all_sellers_mm_income
FROM(
	SELECT oi.seller_id,
		YEAR(o.order_purchase_timestamp) AS year,
        MONTH(o.order_purchase_timestamp) AS month,
        SUM(oi.price) AS monthly_income
	From orders o
		JOIN order_items oi ON o.order_id = oi.order_id
		Join products p ON p.product_id = oi.product_id
	WHERE product_category_name IN ('audio', 'eletronicos', 'informatica_acessorios', 'pc_gamer', 'pcs', 'tablets_impressao_imagem', 'telefonia')
    Group By oi.seller_id, year, month) AS selller_monthly_income;
    
-- avg time between order placed and product delivery
SELECT
	ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)),1) AS avg_delivery_days
FROM orders;

-- how many delivered on time
SELECT
	order_id,
    order_estimated_delivery_date,
    order_delivered_customer_date,
	CASE
		WHEN order_delivered_customer_date < order_estimated_delivery_date THEN 'EARLY'
		WHEN order_delivered_customer_date = order_estimated_delivery_date THEN 'ON-TIME'
		WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'DELAYED'
		ELSE 'PENDING'
	END AS delivery_status
FROM orders;

-- delivery breakdown
SELECT
	CASE
		WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'ON-TIME'
		WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'DELAYED'
		ELSE 'PENDING'
	END AS delivery_status,
    COUNT(*) AS total_orders,
    ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM orders WHERE delivery_status <> 'PENDING'), 2) AS percentage
FROM orders
GROUP BY delivery_status;

-- delivery by category
SELECT
	product_category_name AS category,
	CASE
		WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'ON-TIME'
		WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'DELAYED'
		ELSE 'PENDING'
	END AS delivery_status,
    COUNT(*) AS total_orders,
    ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM orders WHERE delivery_status <> 'PENDING'), 2) AS percentage
FROM orders o
	JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
GROUP BY category, delivery_status;

-- price trends
SELECT
	product_category_name,
	MIN(price),
    MAX(price),
    ROUND(AVG(price),2) AS avg_price
FROM order_items oi
	JOIN products p ON oi.product_id = p.product_id
WHERE product_category_name IN ('audio', 'eletronicos', 'informatica_acessorios', 'pc_gamer', 'pcs', 'tablets_impressao_imagem', 'telefonia')
GROUP BY product_category_name
Order by avg_price desc;

-- all product sizing
SELECT
    CASE
		WHEN p.product_weight_g < 2000 THEN "SMALL"
        WHEN p.product_weight_g BETWEEN 2000 AND 10000 THEN "MEDIUM"
        WHEN p.product_weight_g BETWEEN 10000 AND 30000 THEN "LARGE"
        ELSE "X-LARGE"
	END AS size_category,
    ROUND(AVG(TIMESTAMPDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)), 2) AS avg_delivery_days,
    COUNT(*) AS total_orders
FROM orders o
	JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY size_category
ORDER BY avg_delivery_days DESC;

-- products avg size
SELECT
    CASE
		WHEN p.product_weight_g < 2000 THEN "SMALL"
        WHEN p.product_weight_g BETWEEN 2000 AND 10000 THEN "MEDIUM"
        WHEN p.product_weight_g BETWEEN 10000 AND 30000 THEN "LARGE"
        ELSE "X-LARGE"
	END AS size_category,
    ROUND(AVG(TIMESTAMPDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)), 2) AS avg_delivery_days,
    COUNT(*) AS total_orders
FROM orders o
	JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
WHERE o.order_delivered_customer_date IS NOT NULL
AND p.product_category_name IN ('audio', 'eletronicos', 'informatica_acessorios', 'pc_gamer', 'pcs', 'tablets_impressao_imagem', 'telefonia')
GROUP BY size_category
ORDER BY avg_delivery_days DESC;

select max(price) from order_items;
-- price/delivery 
WITH order_totals AS (
	SELECT
		o.order_id,
        SUM(oi.price) AS total_order_value
	FROM orders o
		JOIN order_items oi ON o.order_id = oi.order_id
	GROUP BY o.order_id)
SELECT
	CASE
		WHEN ot.total_order_value < 100 THEN 'LOW VALUE'
        WHEN ot.total_order_value BETWEEN 100 AND 500 THEN 'MID-VALUE'
        WHEN ot.total_order_value > 500 then 'HIGH VALUE'
	END AS order_value_categories,
	CASE
		WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'ON-TIME'
		WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'DELAYED'
		ELSE 'PENDING'
	END AS delivery_status,
    COUNT(*) AS total_orders
FROM orders o
	JOIN order_totals ot ON o.order_id = ot.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY order_value_categories, delivery_status
ORDER BY order_value_categories, delivery_status;

-- customer to seller zips
SELECT 
    COUNT(*) AS matching_zipcode_orders,
    ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM orders), 2) AS percentage
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN sellers s ON oi.seller_id = s.seller_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE s.seller_zip_code_prefix = c.customer_zip_code_prefix;

-- avg processing time
SELECT
	ROUND(AVG(DATEDIFF(order_delivered_carrier_date, order_purchase_timestamp)),1) AS avg_processing_time
FROM orders;

-- orders per date
SELECT
	DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(*) AS total_orders,
    ROUND(AVG(TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_carrier_date)), 2) AS avg_procesing_time,
    ROUND(AVG(TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date)), 2) AS avg_delivery_time,
	CASE
		WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'ON-TIME'
		WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'DELAYED'
		ELSE 'PENDING'
	END AS delivery_status
FROM orders o
WHERE order_delivered_customer_date IS NOT NULL
GROUP BY order_month
Order BY order_month ASC;

-- alternative 
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(*) AS total_orders,
    ROUND(AVG(TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_carrier_date)), 2) AS avg_processing_time,
    ROUND(AVG(TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date)), 2) AS avg_delivery_time,
    
    -- Count of On-Time and Delayed Deliveries (Excluding Pending)
    SUM(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 ELSE 0 END) AS on_time_deliveries,
    SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) AS delayed_deliveries,
    
    -- Percentage Calculations (Excluding Pending)
    ROUND(100 * SUM(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 ELSE 0 END) 
          / COUNT(order_delivered_customer_date), 2) AS on_time_percentage,
    
    ROUND(100 * SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) 
          / COUNT(order_delivered_customer_date), 2) AS delayed_percentage
          
FROM orders
WHERE order_delivered_customer_date IS NOT NULL  -- Excludes pending orders
GROUP BY order_month
ORDER BY order_month ASC;

SELECT 
	zip_code_prefix AS zipcode,
	count(*) AS orders
FROM orders o
	JOIN customers c ON c.customer_id = o.customer_id
    JOIN geo g ON c.customer_zip_code_prefix = g.zip_code_prefix
Group BY zipcode
Order By orders desc;

select * from order_payments;
-- order period magist
SELECT
	CONCAT(YEAR(o.order_purchase_timestamp), '-Q', QUARTER(o.order_purchase_timestamp)) AS quarter,
    ROUND(SUM(oi.price),2) AS total_revenue
FROM orders o
	JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_purchase_timestamp IS NOT NULL
GROUP BY quarter
ORDER BY quarter;

-- delivery breakdown
SELECT
	CASE
		WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'ON-TIME'
		WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'DELAYED'
		ELSE 'PENDING'
	END AS delivery_status,
    COUNT(*) AS total_orders,
    ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM orders WHERE delivery_status <> 'PENDING'), 2) AS percentage
FROM orders
GROUP BY delivery_status;

-- avg processing time
SELECT
	DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS month,
	ROUND(AVG(DATEDIFF(order_delivered_carrier_date, order_purchase_timestamp)), 1) AS avg_processing_time,
    ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1) AS avg_delivery_time,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders
WHERE order_delivered_carrier_date IS NOT NULL
	AND order_delivered_customer_date IS NOT NULL
group by month
order by month;
