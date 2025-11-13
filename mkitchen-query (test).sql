use `das-db`;
set @mk := '84093770-29ad-4e8e-9da1-babe583c0d69';

-- TABLE SEARCH
show tables like '%order%';
show tables like '%product%';
show tables like '%histories%';
show tables like '%reference%';
show tables like '%user%';
show tables like '%sale%';
desc histories;
show tables like '%categories%';
show tables like '%customer%';
show tables like '%township%';

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


-- EXECUTIONS
select * from sales_order_details
where id = @mk;

select * from sales_order_details;

set @mk := '84093770-29ad-4e8e-9da1-babe583c0d69';
select * from sales_order_details as s
left join products as p
on s.product_id = p.id
where p.business_id = @mk;