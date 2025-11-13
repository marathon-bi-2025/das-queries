use `das-db`;

-- TABLE SEARCH
show tables like '%order%';
show tables like '%product%';
show tables like '%histories%';
show tables like '%reference%';
show tables like '%user%';
show tables like '%sale%';
show tables like '%categories%';
show tables like '%customer%';
show tables like '%township%';
show tables like '%branch%';
show tables like '%delivery%';


-- TABLES

select * from products;
select * from histories;
select * from businesses;
select * from users;
select * from sales_order_details;
select * from sales_orders
where business_id = '84093770-29ad-4e8e-9da1-babe583c0d69';
select * from product_categories;
select * from customers
where business_id = '84093770-29ad-4e8e-9da1-babe583c0d69';
select * from customer_groups
where business_id = '84093770-29ad-4e8e-9da1-babe583c0d69';
select * from price_lists;
select * from billing_addresses;
select * from townships;
select * from states;
select * from sales_people;
select * from branches;
select * from delivery_methods;


