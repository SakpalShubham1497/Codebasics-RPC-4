#1.Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
select distinct(market) from dim_customer
	where customer="Atliq Exclusive" and region="APAC";


#2.What is the percentage of unique product increase in 2021 vs. 2020?
with cte1 as (
		select count(distinct(product_code)) as u20 from fact_sales_monthly
			where fiscal_year=2020),
	cte2 as (
		select count(distinct(product_code)) as u21 from fact_sales_monthly
			where fiscal_year=2021)
select u20 as unique_product_2020, u21 as unique_product_2021,
	round((u21-u20)*100/u20,2) as Pct_Chg
    from (cte1, cte2);


#3.Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
SELECT segment, count(product_code) as product_count
	FROM dim_product
    group by segment
    order by product_count desc;


#4.Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?
with cte1 as (select
		p.segment as segment, count(distinct(s.product_code)) as product_count_2020, sum(s.sold_quantity)
		from fact_sales_monthly s
		join dim_product p on
		s.product_code = p.product_code
		where fiscal_year=2020
		group by segment),
cte2 as (select
		p.segment as segment, count(distinct(s.product_code)) as product_count_2021, sum(s.sold_quantity)
		from fact_sales_monthly s
		join dim_product p on
		s.product_code = p.product_code
		where fiscal_year=2021
		group by segment)
select cte1.segment, product_count_2020, product_count_2021, (product_count_2021 - product_count_2020) as difference
	   from cte1, cte2
       where cte1.segment = cte2.segment;


#5.Get the products that have the highest and lowest manufacturing costs.
select p.product_code, p.product, m.manufacturing_cost 
	from dim_product p
	join fact_manufacturing_cost m on
    p.product_code = m.product_code
    where manufacturing_cost in (
    (select min(manufacturing_cost)from fact_manufacturing_cost),
    (select max(manufacturing_cost)from fact_manufacturing_cost))
    order by manufacturing_cost desc;


#6.Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. The final output contains these fields,
select c.customer_code, c.customer, pre.pre_invoice_discount_pct as avg_pre_discount_pct
	from dim_customer c
	join fact_pre_invoice_deductions pre on
    c.customer_code = pre.customer_code
    where fiscal_year=2021 and market="India"
    order by pre_invoice_discount_pct desc
    limit 5;


#7.Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions.
select concat(monthname(s.date), ' (', year(s.date), ')') as 'month', s.fiscal_year,
    round(sum(s.sold_quantity*g.gross_price),2) as Gross_sales_Amount
	from fact_sales_monthly s
	join dim_customer c on
    s.customer_code = c.customer_code
    join fact_gross_price g on
    s.product_code = g.product_code
    where c.customer = "Atliq Exclusive"
    group by month, s.fiscal_year
    order by fiscal_year asc;


#8.In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity,
select 
	case
		when date between '2019-09-01' and '2019-11-01' then 'Q1'
        when date between '2019-12-01' and '2020-02-01' then 'Q2'
        when date between '2020-03-01' and '2020-05-01' then 'Q3'
        when date between '2020-06-01' and '2020-08-01' then 'Q4'
    end as Quaters_fy_2020,
    sum(sold_quantity) as total_sold_quantity_fy_2020
    from fact_sales_monthly
    where fiscal_year = 2020
    group by Quaters_fy_2020;


#9.Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields,
with cte1 as 
	(select c.channel,
    round(sum(s.sold_quantity*g.gross_price/1000000),2) as Gross_Sales_Mill
    from fact_sales_monthly s
    join dim_customer c on
    s.customer_code = c.customer_code
    join fact_gross_price g on
    s.product_code = g.product_code
    where s.fiscal_year = 2021
    group by c.channel),
cte2 as 
	(select sum(Gross_Sales_Mill) as total from cte1)
select cte1.channel, Gross_Sales_Mill, round((Gross_Sales_Mill*100/total),2) as Percentage_Contri
	from (cte2,cte1)
    order by Percentage_Contri desc;


#10.Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields,
with cte1 as 
	(select p.division, p.product_code, p.product, sum(s.sold_quantity) as total_sold_quantity
    from fact_sales_monthly s
	join dim_product p on
    s.product_code = p.product_code
    where fiscal_year = 2021
    group by p.division, p.product_code, p.product),
cte2 as 
	(select *,
    rank() over(partition by division order by total_sold_quantity desc) as rank_no
    from cte1)
select * from cte2 where rank_no <= 3;