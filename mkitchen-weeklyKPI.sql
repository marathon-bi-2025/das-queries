USE `das-db`;

SHOW TABLES like '%users%';

SELECT * FROM users WHERE business_id = '84093770-29ad-4e8e-9da1-babe583c0d69';

SELECT * FROM account_transactions;

SELECT * FROM businesses;

SELECT * FROM branches WHERE business_id = '84093770-29ad-4e8e-9da1-babe583c0d69';

SELECT * FROM warehouses WHERE business_id = '84093770-29ad-4e8e-9da1-babe583c0d69';

WITH Purchase AS
(SELECT 
    bill_details.product_id,
    bill_details.product_type,
    bill_details.batch_number,
    MIN(bills.bill_date) purchase_date,
    SUM(bill_details.detail_qty) total_purchase_qty,
    MIN(bill_details.expiry_date) expiry_date
FROM
    bill_details
        LEFT JOIN
    bills ON bills.id = bill_details.bill_id
    where bills.current_status != 'Draft'
    AND bills.business_id = '84093770-29ad-4e8e-9da1-babe583c0d69'
    AND bills.bill_date <= '2025-06-26'
    {{ if .BranchId }} AND bills.branch_id = '34' {{end}}
    {{ if .WarehouseId }} AND bills.warehouse_id = '47' {{end}}
GROUP BY bill_details.product_id , bill_details.product_type , bill_details.batch_number),

Sale AS
(SELECT 
    details.product_id,
    details.product_type,
    details.batch_number,
    MAX(invoices.invoice_date) last_sale_date,
    SUM(details.detail_qty) total_sale_qty
FROM
    sales_invoice_details details
        LEFT JOIN
    sales_invoices invoices ON invoices.id = details.sales_invoice_id
WHERE
    invoices.current_status != 'Draft'
    AND invoices.business_id = '84093770-29ad-4e8e-9da1-babe583c0d69'
    AND invoices.invoice_date <= '2025-09-26'
	{{ if .BranchId }} AND invoices.branch_id = '34' {{end}}
	{{ if .WarehouseId }} AND invoices.warehouse_id = '47' {{end}}
GROUP BY details.product_id , details.product_type , details.batch_number)

SELECT 
    Purchase.product_id,
    Purchase.product_type,
    Purchase.batch_number,
    Purchase.purchase_date,
    Purchase.total_purchase_qty,
    Purchase.expiry_date,
    Sale.last_sale_date,
    COALESCE(Sale.total_sale_qty, 0) total_sale_qty,
    COALESCE(Purchase.total_purchase_qty - Sale.total_sale_qty, Purchase.total_purchase_qty) remaining_qty,
    DATEDIFF('2025-09-26', Purchase.purchase_date) age,
    COALESCE(products.name, product_variants.name, raw_materials.name) product_name,
    COALESCE(products.sku, product_variants.sku, raw_materials.sku) sku
FROM
    Purchase
        LEFT JOIN
    Sale ON Purchase.product_id = Sale.product_id
        AND Purchase.product_type = Sale.product_type
        AND Purchase.batch_number = Sale.batch_number
        LEFT JOIN products ON products.id = Purchase.product_id AND Purchase.product_type = 'S'
        LEFT JOIN product_variants ON product_variants.id = Purchase.product_id AND Purchase.product_type = 'V'
        LEFT JOIN raw_materials ON raw_materials.id = Purchase.product_id AND Purchase.product_type = 'R'
    ORDER BY product_name;

-- sales order with products detail
SELECT 
    so.id              AS sales_order_id,
    so.order_number,
    so.order_date,
    so.customer_id,
    sod.id             AS sales_order_detail_id,
    sod.detail_qty,
    sod.detail_unit_rate,
    sod.detail_total_amount,
    p.id               AS product_id,
    p.name             AS product_name,
    p.sku,
    p.barcode,
    p.sales_price,
    p.category_id
FROM sales_orders so
JOIN sales_order_details sod 
    ON so.id = sod.sales_order_id
JOIN products p 
    ON sod.product_id = p.id
WHERE so.business_id = '84093770-29ad-4e8e-9da1-babe583c0d69'
  AND so.order_date BETWEEN '2025-09-22' AND '2025-09-28'
ORDER BY so.order_date DESC, so.id, sod.id;

-- sales order with customer name and customer group
SELECT 
    so.id             AS sales_order_id,
    so.order_number,
    so.order_date,
    so.order_total_amount,
    c.id              AS customer_id,
    c.name            AS customer_name,
    cg.name           AS customer_group
FROM sales_orders so
JOIN customers c 
    ON so.customer_id = c.id
JOIN customer_groups cg 
    ON c.group_id = cg.id
WHERE so.business_id = '84093770-29ad-4e8e-9da1-babe583c0d69'
  AND so.order_date BETWEEN '2025-09-22' AND '2025-09-28'
ORDER BY so.order_date DESC;

-- customer name and customer group
SELECT 
    c.id           AS customer_id,
    c.name         AS customer_name,
    cg.name        AS customer_group
FROM customers c
JOIN customer_groups cg 
    ON c.group_id = cg.id
WHERE cg.business_id = '84093770-29ad-4e8e-9da1-babe583c0d69'
ORDER BY cg.name, c.name;

-- b2b, b2c, coporate sales order
SELECT
  CASE
    WHEN LOWER(TRIM(cg.name)) IN ('modern trade','horeca','wholesale','grocery store','intercompany') THEN 'B2B'
    WHEN LOWER(TRIM(cg.name)) IN ('employee b2c','individual b2c')                                       THEN 'B2C'
    WHEN LOWER(TRIM(cg.name)) IN ('individual corp','employee corp')                                     THEN 'Corporate'
    ELSE 'Other'
  END AS channel,
  COUNT(DISTINCT so.id)              AS sales_orders,
  SUM(so.order_total_amount)         AS total_amount
FROM sales_orders so
JOIN customers c       ON c.id = so.customer_id
JOIN customer_groups cg ON cg.id = c.group_id
WHERE so.order_date >= CURDATE() - INTERVAL 60 DAY
  -- Optional: scope to one business
  AND so.business_id = '84093770-29ad-4e8e-9da1-babe583c0d69'
  -- Only include the groups you mapped (drop this line if you want to keep "Other")
  AND LOWER(TRIM(cg.name)) IN (
      'modern trade','horeca','wholesale','grocery store','intercompany',
      'employee b2c','individual b2c',
      'individual corp','employee corp'
  )
GROUP BY channel
ORDER BY channel;

/* Counts customers with NO orders in the last 60 days, by umbrella group */
SELECT
  t.umbrella_group,
  COUNT(*) AS customers_without_orders_60d
FROM (
  SELECT 
    c.id AS customer_id,
    CASE
      WHEN LOWER(cg.name) IN ('modern trade','horeca','wholesale','grocery store','intercompany')
        THEN 'B2B'
      WHEN LOWER(cg.name) IN ('employee b2c','individual b2c')
        THEN 'B2C'
      WHEN LOWER(cg.name) IN ('individual corp','employee corp')
        THEN 'Corporate'
      ELSE 'Other'
    END AS umbrella_group
  FROM customers c
  JOIN customer_groups cg
    ON c.group_id = cg.id
  /* recent orders in last 60 days */
  LEFT JOIN (
    SELECT DISTINCT so.customer_id
    FROM sales_orders so
    WHERE so.order_date >= (CURRENT_DATE - INTERVAL 60 DAY)
      AND so.business_id = '84093770-29ad-4e8e-9da1-babe583c0d69'
      /* optionally exclude cancelled/etc.:
         AND so.current_status NOT IN ('Cancelled') */
  ) recent ON recent.customer_id = c.id
  WHERE cg.business_id = '84093770-29ad-4e8e-9da1-babe583c0d69'
    AND recent.customer_id IS NULL   -- no orders in last 60 days
) AS t
WHERE t.umbrella_group IN ('B2B','B2C','Corporate')
GROUP BY t.umbrella_group
ORDER BY t.umbrella_group;

-- active SKU count
SELECT 
    COUNT(*) AS active_sku_count
FROM products
WHERE is_active = 1
  AND business_id = '84093770-29ad-4e8e-9da1-babe583c0d69';
-- end active SKU count

SHOW TABLES LIKE '%stock%';

SELECT * FROM opening_stocks;

-- SKU at least 1 in stock
SELECT count(*) AS SKU_at_least_1_instock
FROM products AS p
JOIN opening_stocks AS os
  ON os.product_id = p.id          
WHERE p.is_active = 1
  AND p.business_id = '84093770-29ad-4e8e-9da1-babe583c0d69'
  AND os.qty > 1;

-- how many SKUs with at least 1 sales order last week
SELECT 
    COUNT(DISTINCT sod.product_id) AS skus_with_sales_last_week
FROM sales_orders so
JOIN sales_order_details sod 
    ON so.id = sod.sales_order_id
JOIN products p 
    ON sod.product_id = p.id
WHERE so.business_id = '84093770-29ad-4e8e-9da1-babe583c0d69'
  AND so.order_date >= CURDATE() - INTERVAL 7 DAY
  AND so.order_date < CURDATE();
  -- optionally exclude cancelled orders:
  -- AND so.current_status NOT IN ('Cancelled');
  
-- All B2B sales orders in the last 60 days
SELECT COUNT(*) AS b2b_orders_last_60d
FROM sales_orders AS so
JOIN customers        AS c  ON c.id = so.customer_id
JOIN customer_groups  AS cg ON cg.id = c.group_id
WHERE cg.name IN ('B2B', 'Modern Trade', 'Horeca', 'Wholesale', 'Grocery Store', 'Intercompany')
  AND so.order_date >= NOW() - INTERVAL 60 DAY
  AND so.order_date <  NOW() -- optional, keeps range half-open
  AND so.business_id = '84093770-29ad-4e8e-9da1-babe583c0d69';
 -- AND so.current_status = 'confirmed';  
 
-- All B2C sales orders in the last 60 days
SELECT COUNT(*) AS b2b_orders_last_60d
FROM sales_orders AS so
JOIN customers        AS c  ON c.id = so.customer_id
JOIN customer_groups  AS cg ON cg.id = c.group_id
WHERE cg.name IN ('B2C', 'Employee B2C', 'Individual B2C')
  AND so.order_date >= NOW() - INTERVAL 60 DAY
  AND so.order_date <  NOW() -- optional, keeps range half-open
  AND so.business_id = '84093770-29ad-4e8e-9da1-babe583c0d69';
 
-- all coporate sales orders in the last 60 days
SELECT COUNT(*) AS b2b_orders_last_60d
FROM sales_orders AS so
JOIN customers        AS c  ON c.id = so.customer_id
JOIN customer_groups  AS cg ON cg.id = c.group_id
WHERE cg.name IN ('Coporate', 'Employee Corp', 'Individual Corp')
  AND so.order_date >= NOW() - INTERVAL 60 DAY
  AND so.order_date <  NOW() -- optional, keeps range half-open
  AND so.business_id = '84093770-29ad-4e8e-9da1-babe583c0d69';
  
-- Customer misconfiguration
SELECT COUNT(*) AS customer_misconfiguration
FROM customers AS c
JOIN customer_groups AS cg ON c.group_id = cg.id
WHERE cg.name IN ('B2B', 'B2C', 'Coporate')
AND c.business_id = '84093770-29ad-4e8e-9da1-babe583c0d69';
  
SELECT 
    COUNT(DISTINCT pv.sku) AS skus_in_stock
FROM product_variants pv
JOIN product_variant_branches pvb 
    ON pv.id = pvb.product_variant_id
WHERE pvb.current_stock > 0
  AND pv.business_id = '84093770-29ad-4e8e-9da1-babe583c0d69';
  
SHOW TABLES LIKE '%address%';
SELECT * FROM delivery_methods;
SELECT * FROM sales_orders;
SELECT * FROM customers WHERE business_id = '84093770-29ad-4e8e-9da1-babe583c0d69';
SELECT * FROM billing_addresses WHERE reference_type = 'customers';



-- B2B prospect, B2C prospect, Coporate Prospect
SELECT COUNT(*) AS b2b_customers_zero_orders_90d
FROM customers c
JOIN customer_groups cg
  ON cg.id = c.group_id
  AND cg.business_id = '84093770-29ad-4e8e-9da1-babe583c0d69'
  AND cg.name IN ('B2B', 'Modern Trade', 'Horeca', 'Wholesale', 'Grocery Store', 'Intercompany')
  -- AND cg.name IN ('B2C', 'Employee B2C', 'Individual B2C')
  -- AND cg.name IN ('B2B', 'Modern Trade', 'Horeca', 'Wholesale', 'Grocery Store', 'Intercompany')
LEFT JOIN sales_orders so
  ON so.customer_id = c.id
  AND so.business_id = '84093770-29ad-4e8e-9da1-babe583c0d69'
  AND so.order_date >= NOW() - INTERVAL 90 DAY  -- last 60 days
WHERE c.business_id ='84093770-29ad-4e8e-9da1-babe583c0d69'
  AND so.id IS NULL;            -- no orders in the window
  
-- b2b sales order created last week
SET @biz := '84093770-29ad-4e8e-9da1-babe583c0d69';
SELECT COUNT(*) AS sales_orders_last_week
FROM sales_orders AS so
JOIN customers AS c
      ON so.customer_id = c.id
JOIN customer_groups AS cg
      ON c.group_id = cg.id
WHERE so.business_id = @biz
  -- AND cg.name IN ('B2B', 'Modern Trade', 'Horeca', 'Wholesale', 'Grocery Store', 'Intercompany')
  -- AND cg.name IN ('B2C', 'Employee B2C', 'Individual B2C')
  AND cg.name IN ('Coporate', 'Employee Corp', 'Individual Corp')
  AND YEARWEEK(so.order_date, 1) = YEARWEEK(CURDATE() - INTERVAL 1 WEEK, 1)
ORDER BY so.order_date ASC;
