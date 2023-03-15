CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 
INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');
 
CREATE TABLE users(userid integer,signup_date date); 
INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');
 
CREATE TABLE sales(userid integer,created_date date,product_id integer); 
INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);
 
CREATE TABLE product(product_id integer,product_name text,price integer); 
INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);

--What is the total amount each customer spent on zomato?
with cte as(
select a.userid,s.product_id
from users as a
join sales as s
on a.userid=s.userid),
cte2 as(
select a.userid,p.price
from cte as a
join product as p
on a.product_id=p.product_id)
select userid,sum(price) as amt
from cte2
group by userid;

--How many days has each customer visited zomato?
select a.userid,count(distinct created_date) as m
from users as a
join sales as b
on a.userid=b.userid
group by a.userid;

--What was the first product purchased by each customer?
with cte as(
select a.userid,min(created_date) as mn
from users as a
join sales as b
on a.userid=b.userid
group by a.userid),
cte2 as(
select a.userid,b.product_id,a.mn
from cte as a
join sales as b
on a.mn=b.created_date
and a.userid=b.userid)
select a.userid,b.product_name,a.mn,a.product_id
from cte2 as a
join product as b
on a.product_id=b.product_id;

--What is the most purchased item on the menu & how many times was it purchased by all customers?
with cte as(
select product_id,count(*) as m
from sales
group by product_id),
cte2 as(
select max(m) as mx from cte),
cte3 as(
select a.product_id
from cte as a
join cte2 as b
on a.m=b.mx)
select b.userid,count(*) as total
from cte3 as a
join sales as b
on a.product_id=b.product_id
group by b.userid;

--Which item was most popular for each customer?
with cte as(
select userid,product_id,count(*) as mx
from sales 
group by userid,product_id),
cte2 as(
select userid,max(mx) as m
from cte
group by userid)
select a.userid,a.product_id,a.mx
from cte as a
join cte2 as b
on a.mx=b.m
and a.userid=b.userid;

--Which item was purchased first by customers after they become a member?
with cte as(
select a.userid,a.signup_date,b.created_date,b.product_id
from users as a
join sales as b
on a.userid=b.userid),
cte2 as(
select userid,min(created_date) as mn,signup_date
from cte
where created_date>signup_date
group by userid,signup_date)
select a.userid,b.product_id,a.mn,a.signup_date
from cte2 as a
join sales as b
on a.userid=b.userid
and a.mn=b.created_date;

--Which item was purchased just before the customer became a member?
with cte as(
select a.userid,a.signup_date,b.created_date,b.product_id
from users as a
join sales as b
on a.userid=b.userid),
cte2 as(
select userid,signup_date,created_date,product_id
from cte
where created_date<signup_date),
cte3 as(
select userid,max(created_date) as mx
from cte2
group by userid)
select a.userid,b.product_id,a.mx
from cte3 as a
join sales as b
on a.mx=b.created_date
and a.userid=b.userid;

--What are the total orders and amount spent for each member before they become a member?
with cte as(
select a.userid,a.signup_date,b.created_date,b.product_id
from users as a
join sales as b
on a.userid=b.userid),
cte2 as(
select a.userid,a.signup_date,a.created_date,a.product_id,b.price
from cte as a
join product as b
on a.product_id=b.product_id),
cte3 as(
select userid, sum(price) as sm,count(*) as t
from cte2
where created_date<signup_date
group by userid)
select * from cte3;

--Rank all transactions of the customers
with cte as(
select a.userid,a.product_id,a.created_date,b.price
from sales as a
join product as b
on a.product_id=b.product_id)
select userid,created_date,price,product_id,DENSE_RANK() over(partition by userid order by userid,created_date,price) as rn from cte;

--Rank all transactions for each member whenever they are zomato gold members
--for every non-gold member transaction mark as na
with cte as(
select b.userid,created_date,product_id,gold_signup_date
from goldusers_signup as a
right join sales as b
on a.userid=b.userid
and b.created_date>a.gold_signup_date),
cte2 as(
select userid,product_id,created_date,gold_signup_date,rank() over(partition by userid order by created_date desc) as rn
from cte)
select userid,product_id,created_date,gold_signup_date,rn,case when not gold_signup_date is null then cast(rn as varchar(3))
else 'na' end  as rank
from cte2;



