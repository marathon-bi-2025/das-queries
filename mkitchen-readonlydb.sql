SHOW DATABASES;

SELECT DATABASE();

show tables;

SELECT * FROM sales_invoices;

SELECT 
    id,
    name,
    email,
    phone,
    address
FROM businesses;

-- to retrieve user counts from m kitchen
SELECT * FROM `das-db`.daily_business_analytics where business_id = '84093770-29ad-4e8e-9da1-babe583c0d69';

SELECT COUNT(*) AS total_businesses FROM businesses;

select * from businesses;

SELECT is_active, name, id FROM businesses;

-- retrieving the sales orders
Show TABLES like '%sales%';
Show TABLES like '%categories%';
Show TABLES like '%customer%';

SELECT * FROM customer_groups WHERE business_id = '84093770-29ad-4e8e-9da1-babe583c0d69';

select * from customers;

-- SELECT * FROM sales_orders 
-- WHERE order_date >= '2025-09-01' AND order_date < '2025-09-31' 
-- AND customer_id 
-- 	IN (SELECT id FROM customers WHERE group_id 
--     IN (SELECT id FROM customer_groups WHERE business_id = '84093770-29ad-4e8e-9da1-babe583c0d69' 
-- 		AND name IN ('B2B', 'Corporate')));

SELECT count(*)
FROM sales_orders AS so
JOIN customers       AS c ON c.id = so.customer_id
JOIN customer_groups AS g ON g.id = c.group_id
WHERE so.order_date >= '2025-09-01'            -- start (inclusive)
  AND so.order_date <  '2025-09-21'            -- next day (exclusive)
  AND g.business_id = '84093770-29ad-4e8e-9da1-babe583c0d69'
  AND g.name IN ('B2B', 'Corporate')
ORDER BY so.order_date DESC;

SELECT * FROM customers WHERE business_id = '84093770-29ad-4e8e-9da1-babe583c0d69';  

SELECT 
    so.order_number as sales_order_id,
    so.order_total_amount,
    so.order_date,
    so.expected_shipment_date,
    so.created_at,
    so.updated_at,
    so.current_status,
    so.order_total_amount,
    c.name AS customer_name,
    cg.name AS customer_group,
    CASE 
		WHEN cg.parent_group_id IS NULL THEN 'not defined'
        WHEN cg.parent_group_id = 0 THEN 'level 1'
        ELSE 'level 2'
	END AS customer_group_level
FROM sales_orders AS so
JOIN customers AS c 
      ON so.id = c.id
LEFT JOIN customer_groups AS cg
	  ON c.group_id = cg.id
WHERE so.business_id = '84093770-29ad-4e8e-9da1-babe583c0d69'
ORDER BY so.created_at ASC;

SELECT 
	p.sku,
	p.name,
    p.description,
    p.sales_price,
    p.purchase_price,
    pc.name as product_category    
FROM products AS p
JOIN product_categories as pc
	ON p.category_id = pc.id
WHERE p.business_id = '84093770-29ad-4e8e-9da1-babe583c0d69';

SELECT * FROM product_categories WHERE business_id = '84093770-29ad-4e8e-9da1-babe583c0d69';

SELECT * FROM sales_orders WHERE business_id = '84093770-29ad-4e8e-9da1-babe583c0d69';

SELECT * FROM purchase_orders WHERE business_id = '84093770-29ad-4e8e-9da1-babe583c0d69';

