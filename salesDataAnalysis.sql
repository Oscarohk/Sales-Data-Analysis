# https://www.kaggle.com/datasets/beekiran/sales-data-analysis/data

# Dataset first glance
select * from sales limit 100;

# Order ID - A unique ID for each order placed on a product
# Product - Item that is purchased
# Quantity Ordered - Describes how many of that products are ordered
# Price Each - Price of a unit of that product
# Order Date - Date on which the order is placed
# Purchase Address - Address to where the order is shipped
# Month, Sales, City, Hour - Extra attributes formed from the above.


# Data Cleaning

create table sales_copy like sales;
insert into sales_copy select * from sales;

# 1. Remove duplicates
with duplicate_cte as (
	select *, row_number() over (partition by Order_ID, Product, Quantity_Ordered, Price_Each, Order_Date, Purchase_Address, `Month`, Sales, City, `Hour`) row_num
    from sales_copy
    order by Product
)
select * from duplicate_cte where row_num > 1;

CREATE TABLE `sales_no_duplicates` (
  `Order_ID` int DEFAULT NULL,
  `Product` text,
  `Quantity_Ordered` int DEFAULT NULL,
  `Price_Each` double DEFAULT NULL,
  `Order_Date` text,
  `Purchase_Address` text,
  `Month` int DEFAULT NULL,
  `Sales` double DEFAULT NULL,
  `City` text,
  `Hour` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

insert into sales_no_duplicates
select *, row_number() over (partition by Order_ID, Product, Quantity_Ordered, Price_Each, Order_Date, Purchase_Address, `Month`, Sales, City, `Hour`) row_num
from sales_copy;

delete from sales_no_duplicates where row_num > 1;

# 2. Standardizing
select Order_Date, str_to_date(substring_index(Order_Date, ' ', 1), '%Y/%m/%d') `Date`, substring_index(Order_Date, ' ', -1) `Time` from sales_no_duplicates;
alter table sales_no_duplicates 
	add column `Date` date, 
    add column `Time` time;
update sales_no_duplicates set `Date` = str_to_date(substring_index(Order_Date, ' ', 1), '%Y/%m/%d');
update sales_no_duplicates set `Time` = substring_index(Order_Date, ' ', -1);

# 3. Dealing with null values
select * from sales_no_duplicates 
where Order_ID is null or Product is null or Quantity_Ordered is null or Price_Each is null or Purchase_Address is null;

# 4. Remove any columns or rows
alter table sales_no_duplicates
	drop column Order_Date,
	drop column row_num;

# 5. Finished cleaning
CREATE TABLE `sales_cleaned` (
  `Order_ID` int DEFAULT NULL,
  `Product` text,
  `Quantity_Ordered` int DEFAULT NULL,
  `Price_Each` double DEFAULT NULL,
  `Purchase_Address` text,
  `Date` date,
  `Time` time,
  `Month` int DEFAULT NULL,
  `Sales` double DEFAULT NULL,
  `City` text,
  `Hour` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

insert into sales_cleaned
select Order_ID, Product, Quantity_Ordered, Price_Each, Purchase_Address, `Date`, `Time`, `Month`, Sales, City, `Hour` from sales_no_duplicates;

drop table sales_no_duplicates;


# Data Analysis

# What was the best month for sales? How much was earned that month?
select `Month`, round(sum(Sales), 2) Total_Earnings
from sales_cleaned
group by `Month`
order by sum(Sales) desc;

# What city sold the most product?
select City, sum(Quantity_Ordered) Total_Num_Products
from sales_cleaned
group by City
order by Total_Num_Products desc;

# What time should we display advertisements to maximize the likelihood of customer’s buying product?
select concat(`Hour`, ':00') `Time_Period`, round(sum(Sales), 2) sum_of_sales
from sales_cleaned
group by `Hour`
order by sum(Sales) desc;

# What products are most often sold together?
select least(s1.Product, s2.Product) product_a, greatest(s1.Product, s2.Product) product_b, round(count(*)/2, 0) times_sold_tgt
from sales_cleaned s1 join sales_cleaned s2
	on s1.Order_ID = s2.Order_ID and s1.Product != s2.Product
group by product_a, product_b
order by times_sold_tgt desc;

# What product sold the most? Why do you think it sold the most?
select Product, sum(Quantity_Ordered) Total_Num_Products
from sales_cleaned
group by Product
order by sum(Quantity_Ordered) desc;