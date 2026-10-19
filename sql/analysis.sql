-- set up 
create database if not exists churn;
use churn;

create table if not exists telco (
  customerID TEXT, gender TEXT, SeniorCitizen INT, Partner TEXT, Dependents TEXT,
  tenure INT, PhoneService TEXT, MultipleLines TEXT, InternetService TEXT,
  OnlineSecurity TEXT, OnlineBackup TEXT, DeviceProtection TEXT, TechSupport TEXT,
  StreamingTV TEXT, StreamingMovies TEXT, Contract TEXT, PaperlessBilling TEXT,
  PaymentMethod TEXT, MonthlyCharges DECIMAL(10,2), TotalCharges TEXT, Churn TEXT
);
-- Import data from the csv file 

--Checking that all the rows are imported 
select count(*) as total_rows from telco;   


-- Q1: Overall churn rate

select round(100.0 * sum(case when Churn = 'Yes' then 1 else 0 end) / count(*), 1) as churn_rate_pct
from telco;
-- RESULT: Overall churn rate is 26.5%
-- INSIGHT: Roughly 1 in 4 customers leaves, so churn is a serious, company-wide problem and the data is imbalanced


-- Q2: Churn by contract type

select Contract,
       count(*) as customers,
       round(100.0 * sum(case when Churn = 'Yes' then 1 else 0 end) / count(*), 1) as churn_rate_pct
from telco
group by Contract
order by churn_rate_pct desc;
-- RESULT: Month-to-month 42.7%, One year 11.3%, Two year 2.8%.
-- INSIGHT: Month-to-month customers churn about 15x more than two-year customers (42.7 / 2.8), so contract length is the strongest retention lever. Moving customers onto longer contracts should cut churn sharply.


-- Q3: Churn by tenure bucket

select case when tenure <= 12 then '0-12'
            when tenure <= 24 then '13-24'
            when tenure <= 48 then '25-48'
            else '49+' end as tenure_group,
       count(*) as customers,
       round(100.0 * sum(case when Churn = 'Yes' then 1 else 0 end) / count(*), 1) as churn_rate_pct
from telco
group by 1
order by 1;
-- RESULT: 0-12 months 47.4%, 13-24 months 28.7%, 25-48 months 20.4%, 49+ months 9.5%.
-- INSIGHT: Churn falls steadily as tenure rises, and first-year customers churn about 5x more than those with 4+ years. The first 12 months are the danger zone, so retention efforts should focus on new customers.


-- Q4: Revenue lost to churn

select round(sum(MonthlyCharges), 2) as monthly_lost,
       round(sum(MonthlyCharges) * 12, 2) as annual_lost
from telco
where Churn = 'Yes';
-- RESULT: Monthly revenue lost ₹139,162; annual revenue lost ₹1,669,944 (about ₹1.67M).
-- INSIGHT: Churn costs the company roughly ₹1.67M a year, so even a small reduction in churn is worth a lot of money.


-- Q5: Ranking contracts by revenue lost

select Contract,
       round(sum(MonthlyCharges), 2) as monthly_lost,
       rank() over (order by sum(MonthlyCharges) desc) as rnk
from telco
where Churn = 'Yes'
group by Contract;
-- RESULT: Rank 1 Month-to-month ₹120,875; Rank 2 One year ₹14,121; Rank 3 Two year ₹4,166.
-- INSIGHT: Month-to-month customers account for about 87% of all revenue lost to churn (120,875 / 139,162), so this is the segment to target first.


-- Q6: High-risk segment (month-to-month AND tenure <= 12)

with seg as (
  select *,
         case when Contract = 'Month-to-month' and tenure <= 12 then 1 else 0 end as high_risk
  from telco
)
select high_risk,
       count(*) as customers,
       sum(case when Churn = 'Yes' then 1 else 0 end) as churned,
       round(100.0 * avg(case when Churn = 'Yes' then 1 else 0 end), 1) as churn_pct
from seg
group by high_risk;
-- RESULT: High-risk: 1,994 customers, 1,024 churned, 51.4% churn. Not high-risk: 5,049 customers, 845 churned, 16.7% churn.
-- High-risk customers are 28.3% of the base (1,994 / 7,043) but 54.8% of all churn (1,024 / 1,869).
-- INSIGHT: About 28% of customers cause 55% of churn, and this group churns about 3x more than everyone else. A targeted retention offer for new month-to-month customers is the highest-impact action.

