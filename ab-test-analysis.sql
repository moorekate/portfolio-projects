-- This analysis uses a simple dataset from Kaggle: https://www.kaggle.com/datasets/sergylog/ab-test-data (CSV file is linked in the repository)
-- Kaggle Credit: https://www.kaggle.com/datasets/sergylog/ab-test-data
-- Objective: Company X has set up an A/B test with control and test groups. Evaluate whether the test experience drives more/less revenue, and therefore should/should not be implemented in full by the company.

-- Created a table in my local MySQL database:
CREATE TABLE `analyst_data`.`simple_ab_test_data`(
  `user_id` INT NULL,
  `test_variant` VARCHAR(45) NULL,
  `revenue` DECIMAL(4,2) NULL);

-- Check the number of records
select count(*) from analyst_data.simple_ab_test_data;

-- Let's start by aggregating!
-- (1) Total revenue from the test period: $798.46
-- (2) Average revenue per user: ~$0.13
select 
sum(revenue) AS total_revenue,
sum(revenue)/count(distinct user_id) AS avg_revenue_per_user
from simple_ab_test_data;

-- Let's split both of these metrics by test variant + see which variant holds the greater percentage of total revenue from the test period.
WITH revenue AS(
select
sum(revenue) AA total_revenue
from analyst_data.simple_ab_test_data)
select 
test_variant,
count(distinct user_id) AS ct_users,
sum(revenue) AS total_revenue,
sum(revenue)/count(distinct user_id) AS avg_revenue_per_user,
sum(revenue)/(select total_revenue from revenue)*100 AS percent_of_total_rev
from simple_ab_test_data
group by 1;
-- Alright, now we're getting somewhere! It looks like the control group produced 56% of revenue ($446.99), while the test group accounted for 44% ($351.47). 
-- But, what if the control group simply had more users? Nope, they're pretty even (3930 vs 3934, a total of 7,864 users participated in the test).

-- Let's look at some things that give us more insight into *how* the users in each group are behaving.
-- How many "power purchasers" are in each group? Are relatively few users generating the majority of revenue, or are lots of users making small purchases?
-- How many distinct users purchased in each group? How many were repeat purchasers?
-- An important note here: Users are recorded in this dataset as making a purchase even if the purchased product is FREE (revenue = 0). So I will be dividing purchases into Free and Paid. 
select 
user_id,
test_variant,
case 
    when sum(revenue) BETWEEN 0 and 1 then '0-1'
    when sum(revenue) BETWEEN 1 and 5 then '1-5'
    when sum(revenue) BETWEEN 5 and 10 then '5-10'
    when sum(revenue) BETWEEN 10 and 20 then '10-20'
    when sum(revenue) BETWEEN 20 and 40 then '20-40'
    when sum(revenue) > 40 then '40+'
    else 'no data' end as spend_bucket,
sum(revenue)
from analyst_data.simple_ab_test_data
group by 1,2
order by 4 desc
 
