select 
sod.sales_order_id, so.current_status, so.updated_at, h.action_type, h.user_name, h.created_at, sod.name, sp.name,
sod.batch_number, sod.detail_qty, sod.detail_unit_rate, sod.detail_discount, p.sku, 
pc.name, pc1.name, pc2.name, so.customer_id, cus.name,
cusg.name, pl.name, ba.attention, ba.address, ba.country, ba.city,
ba.phone, ba.mobile, ba.email, st.state_name_en, ts.township_name_en from histories as h
-- select * from histories as h

left join sales_order_details as sod
on h.reference_id = sod.sales_order_id
left join products as p
on sod.product_id = p.id
left join product_categories as pc
on p.category_id = pc.id
left join product_categories as pc1
on pc.parent_category_id = pc1.id
left join product_categories as pc2
on pc1.parent_category_id = pc2.id
left join sales_orders as so
on sod.sales_order_id = so.id
left join customers as cus
on so.customer_id = cus.id
left join customer_groups as cusg
on cus.group_id = cusg.id
left join price_lists as pl
on cusg.price_list_id = pl.id
left join billing_addresses as ba
on so.customer_id = ba.id
left join states as st
on ba.state_id = st.id
left join townships as ts
on ba.township_id = ts.id
left join sales_people as sp
on so.sales_person_id = sp.id

where h.reference_type = 'sales_orders'
and h.business_id = '84093770-29ad-4e8e-9da1-babe583c0d69'
order by h.reference_id asc;