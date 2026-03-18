create database sales_analysis_db;
use sales_analysis_db;

create table customers (
	customer_id int primary key not null,
    customer_name varchar(30) not null,
    city varchar(30),
	region varchar(30)
);

create table products (
	product_id int primary key not null,
    product_name varchar(30) not null,
    category varchar(20),
	price decimal(10,2)
);

create table orders(
	order_id int primary key not null,
    customer_id int not null,
    order_date date not null,
	ship_date date not null,
    order_status varchar(20),
    
    constraint fk_custid foreign key (customer_id) references customers(customer_id)
);

create table order_items(
	order_item_id int primary key not null,
    order_id int not null,
    product_id int not null,
    quantity int check(quantity > 0),
    sales_amount decimal(10,2),
    
    constraint fk_oid foreign key (order_id) references  orders(order_id),
	constraint fk_pid foreign key (product_id) references  products(product_id)
);

show tables;
desc orders;

select * from customers;
select * from products;
select * from orders;
select * from order_items;

select sum(sales_amount) from order_items;
select count(order_id) from orders;
select count(distinct customer_id) from orders;

select order_id, sales_amount
from order_items
where order_id = 2;

select avg(order_tot) as avg_order_value
from (
select order_id,sum(sales_amount)  as order_tot from order_items
group by order_id)x ;

select sum(quantity) as tot_quantity_sold from order_items;

select order_status, sum(sales_amount)
from orders o join order_items ot
on o.order_id = ot.order_id
group by order_status;

select c.customer_id, customer_name,sum(sales_amount) as cust_sales     #---------Top 5 customers by sales
from customers c
join orders o
on c.customer_id = o.customer_id
join order_items oi
on o.order_id = oi.order_id
group by customer_id,customer_name
order by sum(sales_amount) desc
limit 5;


select p.product_id,product_name,sum(sales_amount)		#---------Top 5 products by revenue
from products p
join order_items oi
on p.product_id = oi.product_id
group by p.product_id,product_name
order by sum(sales_amount) desc
limit 5;


select region,sum(sales_amount)		#---------Sales by region
from customers c
join orders o
on c.customer_id = o.customer_id
join order_items oi
on o.order_id = oi.order_id
group by region
order by sum(sales_amount) desc;

select date_format(order_date, "%b-%y") as yearmonth, sum(sales_amount)    #-------Monthly sales trend
from orders o
join order_items oi
on o.order_id = oi.order_id
group by yearmonth
order by date_format(order_date, '%Y-%m');

#------------------

select c.customer_id,count(o.order_id),
CASE WHEN count(o.customer_id)>1 THEN 'repeat customers' ELSE 'one-time customer' end as cust_perf
from customers c
join orders o 
on c.customer_id = o.customer_id
group by c.customer_id;

select c.customer_id,count(o.order_id)
from customers c
join orders o 
on c.customer_id = o.customer_id
group by o.customer_id;




#--------------- Repeat vs one-time customers ----------------

with cust_rnk as (
	select c.customer_id,count(o.order_id),
CASE WHEN count(o.order_id)>1 THEN 'repeat customers' ELSE 'one-time customer' end as cust_perf
from customers c
join orders o 
on c.customer_id = o.customer_id
group by c.customer_id
)

select cust_perf,count(cust_perf) as customer_type_count
from cust_rnk
group by cust_perf;


#--------- Delayed shipments count ----------
#---------- shipping took more than 7 days

with ship_days as (
select order_id,datediff(ship_date,order_date) as diff_days
from orders
where datediff(ship_date,order_date)  > 7
)

select count(order_id) as delayed_shipment_count
from ship_days;


#------- Customers whose spend is above average customer spend ----

with cust_spent as (
    select 
        c.customer_id, 
        c.customer_name,  
        sum(oi.sales_amount) as cust_tot
    from customers c
    join orders o on c.customer_id = o.customer_id
    join order_items oi on o.order_id = oi.order_id
    group by c.customer_id, c.customer_name  
)
select customer_name, cust_tot
from cust_spent
where cust_tot > (select avg(cust_tot) from cust_spent);



# ---------- Rank products within each category by revenue ---------

with prod_rev as (
	select product_name,sum(sales_amount)as total_revenue,category
    from products p
    join order_items oi
	on p.product_id = oi.product_id
    group by category,product_name
)

select *,dense_rank() over(partition by category order by  total_revenue desc) as rn
from prod_rev;



# -------------------- Month-over-month sales growth ------------

with month_sales as (
    select 
        date_format(order_date, '%b-%y') as yearmonth, 
        sum(oi.sales_amount) as amount,
        min(order_date) as sort_date 
    from orders o
    join order_items oi on o.order_id = oi.order_id
    group by date_format(order_date, '%b-%y'), date_format(order_date, '%Y-%m')
)
select 
    yearmonth, 
    amount, 
    lag(amount) over(order by sort_date) as prev_month_sales,
    amount - lag(amount) over(order by sort_date) as month_on_month_diff
from month_sales
order by sort_date;


# ------------ Best-performing region each month ---------------
select region,sum(sales_amount)		#---------Sales by region
from customers c
join orders o
on c.customer_id = o.customer_id
join order_items oi
on o.order_id = oi.order_id
group by region
order by sum(sales_amount) desc;

select 
        date_format(order_date, '%b-%y') as yearmonth, 
        sum(oi.sales_amount) as amount,region
        from orders o
        join customers c
        on c.customer_id = o.customer_id
		join order_items oi 
        on o.order_id = oi.order_id
        group by yearmonth;
