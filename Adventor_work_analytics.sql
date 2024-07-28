use adventure_work_analytics;

select count(*) from sales        -- 29581
select count(*) from category     -- 4
select count(*) from product      -- 293
select count(*) from return_      -- 1809
select count(*) from subcategory  -- 37
select count(*) from territory    -- 10


-- create a table with cost,revenue and profit
select OrderDate,s.ProductKey,ProductCost,ProductPrice,OrderQuantity,round((OrderQuantity*ProductCost),1) as Cost,round((OrderQuantity*ProductPrice),1)as Revenue, round(((OrderQuantity*ProductPrice)-(OrderQuantity*ProductCost)),1) as Profit from sales s
join product p on p.ProductKey=s.ProductKey


-- month wise Revenue 

select MonthName(OrderDate) as Month_, round(sum(OrderQuantity*ProductPrice),0)as Revenue from sales s
join product p on p.ProductKey=s.ProductKey
group by Monthname(OrderDate),Month(OrderDate)
order by Month(OrderDate)


-- month wise revenue percentage change 
with r as(
select MonthName(OrderDate) as Month_, round(sum(OrderQuantity*ProductPrice),0)as Revenue from sales s
join product p on p.ProductKey=s.ProductKey
group by Monthname(OrderDate),Month(OrderDate)
order by Month(OrderDate)
)
select *, Lag(Revenue) over() as Previous_Month_Revenue,
round(((Revenue-Lag(Revenue) over())/Lag(Revenue) over())*100,1) as Revenue_Percentage_Change
from r

-- Quarter  wise Revenue

select Quarter(OrderDate) as Month_, round(sum(OrderQuantity*ProductPrice),0)as Revenue from sales s
join product p on p.ProductKey=s.ProductKey
group by Quarter(OrderDate)
order by Quarter(OrderDate)


-- Top 5 best selling product for based on Profit
with rev as(
select ProductName,sum(OrderQuantity*ProductCost) as Cost , sum(OrderQuantity * ProductPrice) as Revenue
from sales s
join Product p on p.ProductKey=s.ProductKey
group by ProductName
)
select ProductName,round((Revenue-Cost),0) as Profit
from rev
order by Profit desc
limit 5


-- highest ordered products
select ProductName,sum(OrderQuantity) as Total_Order
from sales s 
join Product p
on p.ProductKey=s.ProductKey
group by  ProductName
order by Total_Order desc


 -- return ratio of products
with ret_ as(
select ProductName,sum(ReturnQuantity) as Return_amount
from return_ r
join Product p 
on p.ProductKey=r.ProductKey
group by ProductName
order by Return_amount desc 
),
order_ as (
select ProductName,sum(OrderQuantity) as Total_Order
from sales s 
join Product p
on p.ProductKey=s.ProductKey
group by  ProductName
order by Total_Order desc
)
select o.ProductName,Total_order,Return_amount,round((Return_amount/Total_order)*100,1) as Return_ratio_percentage from order_ o
join ret_ r
on r.ProductName=o.ProductName
order by Return_ratio_percentage desc



-- country wise revenue and percentage
with r as
(select Country,round(sum(OrderQuantity*ProductPrice),0) as Revenue
from sales s
join product p on p.ProductKey=s.ProductKey
join territory t on t.SalesTerritoryKey=s.TerritoryKey
group by  Country
order by Revenue desc)

select *, 
round((Revenue/sum(Revenue) over())*100,0) as Percentage_of_Total_Revenue from r



-- Country wise best 5 products based on Revenue
with p as(
select Country,ProductName,round(sum(ProductPrice*OrderQuantity),0) as Revenue 
from sales s
join product p on p.ProductKey=s.ProductKey
join territory t on t.SalesTerritoryKey=s.TerritoryKey
group by Country,ProductName
),
ran as(
select *, dense_rank() over(partition by Country order by Revenue desc) as rnk
from p
)
select Country,ProductName,Revenue from ran
where rnk<6

 -- Category wise Revenue
select SubcategoryName,round(sum(OrderQuantity*ProductPrice),0) as Revenue from sales s
join product p on p.ProductKey=s.ProductKey
join subcategory sub on sub.ProductSubcategoryKey=p.ProductSubcategoryKey
group by SubcategoryName
order by Revenue desc



-- best 2 products under each sub-Category

with sub as(
select SubcategoryName,ProductName,round(sum(OrderQuantity*ProductPrice),0) as Revenue from sales s
join product p on p.ProductKey=s.ProductKey
join subcategory sub on sub.ProductSubcategoryKey=p.ProductSubcategoryKey
group by SubcategoryName,ProductName
order by SubcategoryName,Revenue desc
)
select SubcategoryName,ProductName,Revenue
from(
select * ,dense_rank() over(partition by SubcategoryName order by Revenue desc) as rnk from sub)p
where p.rnk<3


-- top 5 customer based on Total_Spent

select concat(Prefix,'  ',FirstName,'  ',LastName) as Customer_Name, round(sum(ProductPrice*OrderQuantity),0) as Total_Spent
from sales s
join product p on p.ProductKey=s.ProductKey
join customer c on c.CustomerKey=s.CustomerKey
group by concat(Prefix,'  ',FirstName,'  ',LastName)  
order by Total_Spent desc
limit 5

-- Customer occupation wise spent
select Occupation, round(sum(ProductPrice*OrderQuantity),0) as Total_Spent
from sales s
join product p on p.ProductKey=s.ProductKey
join customer c on c.CustomerKey=s.CustomerKey
group by Occupation 
order by Total_Spent desc
limit 5

-- Customer who buys product every month
select concat(Prefix,'  ',FirstName,'  ',LastName) as Customer_Name
from sales s
join customer c on c.CustomerKey=s.CustomerKey
group by concat(Prefix,'  ',FirstName,'  ',LastName)
having count(Distinct Month(OrderDate))=(select count(Distinct Month(OrderDate)) from sales)
