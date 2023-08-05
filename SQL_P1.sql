drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
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


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);



--Viewing the data
SELECT * FROM sales;
select * from product;
select * from goldusers_signup;
select * from users;

--What is the total amount spent by each user in foodmandu
SELECT sales.userid,SUM(product.price) as total 
FROM sales
LEFT JOIN product
ON sales.product_id=product.product_id
GROUP BY sales.userid;

--How many days has each customer visited zomato?
SELECT userid,count(distinct(created_date))
FROM sales
GROUP by userid;

--What was the first product purchased by each customer?
with cte as
(
SELECT s.userid,p.product_id,p.product_name,row_number() over(partition by s.userid order by s.created_date) as rn
FROM sales s
JOIN product p
ON s.product_id=p.product_id
)
SELECT userid,product_id,product_name
FROM cte
WHERE rn=1;

--What is the most purchased item on the menu and how many time was it purchased by all customer?
SELECT userid,count(product_id)
FROM sales 
WHERE product_id=
(
SELECT top 1 s.product_id
FROM sales s
LEFT JOIN product p
ON s.product_id=p.product_id
GROUP BY s.product_id
ORDER BY count(s.product_id) DESC
)
GROUP BY userid;

--Which item is most popular for each customer?
with cte as
(
SELECT userid,product_id,count(product_id) as total,rank() OVER (PARTITION BY userid ORDER BY count(product_id) DESC) as rn
FROM sales
GROUP BY userid,product_id
) 
SELECT userid,product_id,total
FROM cte 
WHERE rn=1;

--Which item was first purchased by customer after they became memeber?
with cte as
(
SELECT gu.userid,gu.gold_signup_date,s.created_date,s.product_id,rank() OVER(PARTITION BY gu.userid ORDER BY created_date) as rn
FROM goldusers_signup gu
JOIN sales s
On gu.userid=s.userid
WHERE s.created_date>=gu.gold_signup_date
)
SELECT userid,product_id
FROM cte
WHERE rn=1;

--Which item was purchased just before the customer became a member?
with cte as
(
SELECT gu.userid,gu.gold_signup_date,s.created_date,s.product_id,rank() OVER(PARTITION BY gu.userid ORDER BY created_date DESC) as rn
FROM goldusers_signup gu
JOIN sales s
On gu.userid=s.userid
WHERE s.created_date<=gu.gold_signup_date
)
SELECT userid,product_id
FROM cte
WHERE rn=1;

--What is the total orders and amount spent by each customer before becoming gold customers?
SELECT s.userid,count(s.product_id) as orders,sum(p.price) AS amount
FROM sales s
JOIN goldusers_signup gu
ON s.userid=gu.userid
JOIN product p
ON s.product_id=p.product_id
WHERE s.created_date<gu.gold_signup_date
GROUP BY s.userid;


--if buying each produt generates points
--i.e 2zp=rs.5 and p1->5rs=1zp, p2->10rs=5zp, p3->5rs=1zp
--calculate points collected by each customers and for which product most points has been given till now


--part1->points collected by each customers
with cte as
(
SELECT s.userid,s.product_id,sum(p.price) as amount
FROM sales s
JOIN product p
ON s.product_id=p.product_id
GROUP BY s.userid,s.product_id
)
SELECT userid,sum(fpoints) as total_fpoints FROM(
SELECT userid, product_id,CASE 
	WHEN product_id=1 THEN amount/5
	WHEN product_id=2 THEN amount/10
	WHEN product_id=3 THEN amount/5
	ELSE amount*0
	END AS fpoints
FROM cte) x
GROUP BY userid;



--part2-> product with most number of points
with cte as
(
SELECT s.userid,s.product_id,sum(p.price) as amount
FROM sales s
JOIN product p
ON s.product_id=p.product_id
GROUP BY s.userid,s.product_id
)
SELECT top 1 product_id,sum(fpoints) as total_fpoints FROM(
SELECT userid, product_id,CASE 
	WHEN product_id=1 THEN amount/5
	WHEN product_id=2 THEN amount/10
	WHEN product_id=3 THEN amount/5
	ELSE amount*0
	END AS fpoints
FROM cte) x
GROUP BY product_id
ORDER BY total_fpoints DESC;

--part3->equivalence cashback by each customer
with cte as
(
SELECT s.userid,s.product_id,sum(p.price) as amount
FROM sales s
JOIN product p
ON s.product_id=p.product_id
GROUP BY s.userid,s.product_id
)
SELECT userid,sum(fpoints) as total_fpoints,sum(fpoints)/2 as cashback
FROM(
SELECT userid, product_id,CASE 
	WHEN product_id=1 THEN amount/5
	WHEN product_id=2 THEN amount/10
	WHEN product_id=3 THEN amount/5
	ELSE amount*0
	END AS fpoints
FROM cte) x
GROUP BY userid


--In the first one year after a customer joins the gold program (including their join date) irrespective of what the customer
--has purchased they earn 5 fpoints for every 10rs spent. 
--Who earned more between 1 and 3?
--What was their points earning in their first year?

SELECT * FROM sales;
select * from product;
select * from goldusers_signup;
select * from users;

--part1->who earned the most fpoint?
SELECT top 1 s.userid,sum(p.price) as total,sum(p.price)/2 as fpoint
FROM sales s
JOIN goldusers_signup gu
ON s.userid=gu.userid
JOIN product p
ON s.product_id=p.product_id
WHERE gold_signup_date<=created_date AND created_date<=dateadd(day,365,gold_signup_date)
GROUP BY s.userid
ORDER BY fpoint DESC;

--part2->What was their points earning in their first year?

SELECT s.userid,sum(p.price) as total,sum(p.price)/2 as fpoint
FROM sales s
JOIN goldusers_signup gu
ON s.userid=gu.userid
JOIN product p
ON s.product_id=p.product_id
WHERE gold_signup_date<=created_date AND created_date<=dateadd(day,365,gold_signup_date)
GROUP BY s.userid
ORDER BY fpoint DESC;


--rank all the transactions of customers
SELECT *,rank() over(PARTITION BY userid ORDER BY created_date) as rank
FROM sales;

--rank all the transactions for every gold member customer and for normal customer mark as na
USE Project_SQL_dummydata
with cte as
(
SELECT s.userid,s.created_date,gu.gold_signup_date
FROM sales s
LEFT JOIN goldusers_signup gu
ON s.userid=gu.userid
)
SELECT userid,created_date,rn,
CASE
	WHEN rn=0 then 'na'
	ELSE rn
	END AS ran
FROM 
(SELECT *,
CAST((CASE 
	WHEN gold_signup_date IS NULL THEN 0
	ELSE rank() over(partition by userid order by created_date )
	end) AS VARCHAR) AS rn
FROM cte) x


