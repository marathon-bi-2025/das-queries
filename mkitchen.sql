SHOW DATABASES;

USE `das-db`;

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

SELECT * FROM `das-db`.daily_business_analytics where business_id = '84093770-29ad-4e8e-9da1-babe583c0d69';

SELECT COUNT(*) AS total_businesses FROM businesses;

select * from businesses;

SELECT is_active, name, id FROM businesses;

-- retrieving the sales orders
Show TABLES like '%sales%';
Show TABLES like '%product%';
Show TABLES like '%histories%';

SELECT * FROM customer_groups WHERE business_id = '84093770-29ad-4e8e-9da1-babe583c0d69';
SELECT * FROM sales_orders 
WHERE business_id = '84093770-29ad-4e8e-9da1-babe583c0d69'
AND id = '85';

select * from customers;

SELECT * FROM histories 
WHERE business_id = '84093770-29ad-4e8e-9da1-babe583c0d69'
AND action_type = 'CREATE';

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

USE `das-db`;  -- or USE das; depending on your database name

SELECT 
    so.id AS order_id,
    so.business_id,
    so.order_number,
    so.order_total_amount,
    so.order_date,
    so.expected_shipment_date,
    so.created_at,
    so.updated_at,
    so.current_status,
    so.order_total_amount,
    c.id AS customer_id,
    c.name AS customer_name
FROM sales_orders AS so
JOIN customers AS c 
      ON so.id = c.id
WHERE so.business_id = '84093770-29ad-4e8e-9da1-babe583c0d69'
ORDER BY so.created_at DESC;

SELECT * FROM products;

WITH creators AS (
  SELECT reference_id, user_name
  FROM (
    SELECT
      his.reference_id,
      his.user_name,
      ROW_NUMBER() OVER (
        PARTITION BY his.reference_id
        ORDER BY his.created_at ASC  -- earliest CREATE
      ) AS rn
    FROM histories his
    WHERE his.reference_type = 'SalesOrder'
      AND his.action_type = 'CREATE'
      AND his.business_id = '84093770-29ad-4e8e-9da1-babe583c0d69'
  ) t
  WHERE t.rn = 1
)
SELECT
  so.order_number                        AS so_number,
  so.order_date                          AS creation_date,
  cr.user_name 							 AS creator_name,
  c.name								 AS customer_name,
  cg.name                                AS so_customer_group,
  CASE 
	WHEN cg.parent_group_id IS NULL THEN 'not definded'
    WHEN cg.parent_group_id = 0 THEN 'level 1'
    ELSE 'level 2'
  END AS customer_group_level,
  dm.name								 AS so_delivery,
  ba.address							 AS billing_address,
  so.current_status                      AS so_status,
  p.sku                                  AS so_line_sku,
  p.name                                 AS so_line_sku_name,
  pg.name                                AS so_line_sku_category,
  CASE 
	WHEN pg.parent_category_id = 0 THEN pg.name
  END AS category_level_1,
  CASE
    WHEN pg.parent_category_id IS NULL THEN 'not defined'
  END AS category_not_defined,
  CASE
    WHEN pg.name = 'Rice bag' THEN pg.name
    WHEN pg.name = 'Oil bottle' THEN pg.name
    WHEN pg.name = 'Household' THEN pg.name
    WHEN pg.name = 'Snacks' THEN pg.name
    WHEN pg.name = 'Rice' THEN pg.name
    WHEN pg.name = 'Oil' THEN pg.name
    WHEN pg.name = 'Cooking' THEN pg.name
    WHEN pg.name = 'Beverage' THEN pg.name
    WHEN pg.name = 'Transport' THEN pg.name
  END AS category_level_2,
  sod.detail_qty                         AS so_line_qty,
  sod.detail_total_amount                AS so_line_total_amount
FROM sales_orders AS so
JOIN sales_order_details AS sod
  ON sod.sales_order_id = so.id
JOIN products AS p
  ON p.id = sod.product_id
LEFT JOIN product_categories AS pg
  ON pg.id = p.category_id               
LEFT JOIN customers AS c
  ON c.id = so.customer_id
LEFT JOIN customer_groups AS cg
  ON cg.id = c.group_id
LEFT JOIN delivery_methods AS dm
  ON dm.id = so.delivery_method_id
LEFT JOIN billing_addresses AS ba
  ON ba.reference_id = c.id
LEFT JOIN creators AS cr
  ON cr.reference_id = so.id
WHERE so.business_id = '84093770-29ad-4e8e-9da1-babe583c0d69'
--  AND so.order_date >= '2025-01-01'
--  AND his.action_type = 'CREATE' 
ORDER BY so.order_date ASC, so.order_number, p.sku;
