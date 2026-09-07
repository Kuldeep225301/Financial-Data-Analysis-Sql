USE finance_db;

#  Bussiness Problem
/*
1. What is the total income across all accounts?
2. What is the total amount of expenses across all accounts?
3. What is the net savings (total income minus total expenses)?
4. What percentage of income is being saved (savings rate)?
5. What is the monthly cash flow (income vs expenses per month)?
6. How much income is coming from each income source/category?
7. How much is being spent in each expense category?
8. Which expense category has the highest total spending?
9. How does actual spending compare to the budgeted amount for each category?
10. What is the average amount spent per day?
11. What is the trend of total spending month by month?
12. What is the running account balance after each transaction?
13. Which expenses are recurring every month (subscriptions, bills, etc.)?
14. Is spending higher on weekends or on weekdays?
15. Which are the top 10 largest transactions overall?
16. What is the current balance of each account?
17. How much is income growing or shrinking month over month?
18. How much are expenses growing or shrinking month over month?
19. What percentage does each category contribute to total spending?
20. What does the overall financial health dashboard look like (summary of key numbers).
*/
select count(*) from categories; # Total record
select * from accounts;
select * from transactions;
select * from categories;

# 1. What is the total income across all accounts?

select sum(abs(transactions.amount)) as "Total Income" from transactions   # abs-> Absolute-> method use to convert -ve value to positive value.
join categories 
on categories.category_id = transactions.category_id
where categories.transaction_type = "Income";

-- 2. What is the total amount of expenses across all accounts?
select sum(abs(transactions.amount)) as Total_Amount from transactions
join categories
on categories.category_id = transactions.category_id
where categories.transaction_type = "Expense";

 -- 3. What is the net savings (total income minus total expenses)?
SELECT 
	ROUND(SUM(CASE WHEN categories.transaction_type= "Income" THEN ABS(transactions.amount) ELSE 0 END),2) AS Total_AMOUNT,
    ROUND(SUM(CASE WHEN categories.transaction_type = "Expense" THEN ABS(transactions.amount) ELSE 0 END),2)  AS  TOTAL_EXPENSES,
    
    (SUM(CASE WHEN categories.transaction_type = "Income" THEN ABS(transactions.amount) ELSE 0 END) - 
    SUM(CASE WHEN categories.transaction_type =  "Expense" THEN ABS(transactions.amount) ELSE 0 END)) AS Net_Saving
    FROM transactions JOIN categories
    ON categories.category_id = transactions.category_id;
    
-- 4. What percentage of income is being saved (savings rate)?
SELECT 
	 ROUND(SUM(CASE WHEN categories.transaction_type = "Income" THEN ABS(transactions.amount) ELSE 0 END),2) AS TOTAL_INCOME,
     ROUND(SUM(CASE WHEN transaction_type ="Expense" THEN ABS(transactions.amount) ELSE 0 END),2) AS TOTAL_EXPENSES,
     
ROUND((SUM(CASE WHEN categories.transaction_type = "Income" THEN ABS(transactions.amount) ELSE 0 END)-
    SUM(CASE WHEN categories.transaction_type = "Expense" THEN ABS(transactions.amount) ELSE 0 END))*100.0 /
    NULLIF(SUM(CASE WHEN categories.transaction_type = "Income" THEN ABS(transactions.amount) ELSE 0 END),0),2) AS Saving_Per_Rate
    
    from transactions join categories
    ON categories.category_id = transactions.category_id;
    
    
-- 5. What is the monthly cash flow (income vs expenses per month)? # monthly cash flow=  Monthly_Inome - Monthly_Expenses

SELECT 
		DATE_FORMAT(transactions.transaction_date, '%Y-%m') AS Month_Wise,
		SUM(CASE WHEN categories.transaction_type = "Income" THEN ABS(transactions.amount) ELSE 0 END) AS TOTAL_INCOME,
        SUM(CASE WHEN categories.transaction_type = "Expense" THEN ABS(transactions.amount) ELSE 0 END) AS TOTAL_EXPENSES,
        
ROUND(SUM(CASE WHEN categories.transaction_type = "Income" THEN ABS(transactions.amount) ELSE - ABS(transactions.amount)END),2) AS Monthly_Cash_Flow
        
        FROM transactions JOIN categories
        ON categories.category_id = transactions.category_id
        GROUP BY Month_Wise
        ORDER BY Month_Wise  LIMIT 12;
	
-- 6  How much income is coming from each income source/category?
SELECT categories.category_name AS Income_Source, SUM(ABS(transactions.amount))  AS Total_Amount 
FROM transactions JOIN categories
ON categories.category_id = transactions.category_id
WHERE categories.transaction_type = 'Income'
GROUP BY Income_Source
ORDER BY Total_Amount DESC limit 10;
    
-- 7  How much is being spent in each expense category?

SELECT  categories.category_name AS Category_Name, SUM(ABS(transactions.amount))  AS Total_Expense 
FROM transactions JOIN categories
ON categories.category_id =  transactions.category_id
WHERE categories.transaction_type = 'Expense'
GROUP BY Category_Name
ORDER BY Total_Expense DESC LIMIT 10;

-- 8 Which expense category has the highest total spending?

SELECT categories.category_name AS Category_Name, SUM(ABS(transactions.amount)) AS TOTAL_AMOUNT
FROM transactions JOIN categories
ON categories.category_id = transactions.category_id
WHERE categories.transaction_type = "Expense"
GROUP BY Category_Name
ORDER BY TOTAL_AMOUNT DESC LIMIT 1;

-- 9 How does actual spending compare to the budgeted amount for each category?

WITH Monthly AS(
SELECT 
		DATE_FORMAT(transactions.transaction_date, '%Y-%m') AS Monthly_Wise, 
		categories.category_name AS Category_Name, SUM(ABS(transactions.amount)) AS Spend_Amount 
        FROM transactions JOIN categories
        ON categories.category_id = transactions.category_id
        WHERE categories.transaction_type = "Expense"
        GROUP BY Category_Name, Monthly_Wise
),

budget AS(
		SELECT Category_Name, ROUND(AVG(Spend_Amount),2) AS Budget_Amount FROM Monthly
        GROUP BY Category_Name
),

latest_Month AS(
		SELECT MAX(Monthly_Wise) AS m FROM Monthly
),

Actual AS(
		SELECT Category_Name, ROUND(Spend_Amount,2) AS Actual_Amount FROM Monthly, latest_Month
        WHERE Monthly.Monthly_Wise = latest_Month.m
)

SELECT budget.Category_Name, budget.Budget_Amount, 
COALESCE(Actual.Actual_Amount, 0) AS Actual_Amount,
COALESCE(Actual.Actual_Amount, 0) - budget.Budget_Amount AS Varrience
FROM budget 
LEFT JOIN Actual ON Actual.Category_Name = budget.Category_Name
ORDER BY Varrience DESC LIMIT 10 ;
 
-- 10 What is the average amount spent per day?
SELECT ROUND(SUM(ABS(amount))* 1.0/COUNT(DISTINCT transaction_date),2)  AS Avg_DailySpending 
FROM transactions 
JOIN categories
ON categories.category_id = transactions.category_id
WHERE categories.transaction_type = 'Expense';

-- 11 What is the trend of total spending month by month?

SELECT 
	DATE_FORMAT(transactions.transaction_date, '%Y-%m') AS Month_Wise,
    SUM(ABS(transactions.amount)) AS Spending_Amount 
    FROM transactions
    JOIN categories 
    ON categories.category_id = transactions.category_id
    WHERE categories.transaction_type = 'Expense'
    GROUP BY Month_Wise
    ORDER BY Month_Wise LIMIT 12;

-- 12 What is the running account balance after each transaction?
WITH top_account AS(
SELECT account_id FROM transactions
GROUP BY account_id ORDER BY COUNT(*) DESC LIMIT 1
) 
SELECT 
transactions.transaction_id, 
transactions.transaction_date,
transactions.amount AS Amount,
accounts.opening_balance + SUM(transactions.amount) OVER(ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)  AS Running_Balance 
FROM transactions
JOIN accounts
ON accounts.account_id = transactions.account_id
WHERE transactions.account_id =  (SELECT account_id FROM top_account)
ORDER BY transactions.account_id, transactions.transaction_date LIMIT 10;

-- 13 Which expenses are recurring every month (subscriptions, bills, etc.)?

SELECT
categories.category_name AS Category_Name,
COUNT(DISTINCT(DATE_FORMAT(transactions.transaction_date, '%Y-%m'))) AS Months_Active,
SUM(ABS(transactions.amount)) AS Total_Spent,
ROUND(AVG(ABS(transactions.amount)),2) AS AVG_Spent
FROM transactions
JOIN categories
ON categories.category_id = transactions.category_id
WHERE categories.transaction_type = 'Expense'
GROUP BY Category_Name
HAVING Months_Active>=6
ORDER BY Months_Active DESC ,  Total_Spent DESC LIMIT 10;

-- 14.Is spending higher on weekends or on weekdays?
SELECT
 CASE WHEN dayofweek(transactions.transaction_date) IN (1,7) THEN 'weekend' ELSE 'weekday' END  AS day_type,
 COUNT(*) AS Num_Transactions,
 SUM(ABS(transactions.amount)) AS Total_Spent,
 ROUND(AVG(ABS(transactions.amount)),2) AS AVG_Spent
 FROM transactions
 JOIN categories
 ON categories.category_id = transactions.category_id
 WHERE categories.transaction_type = 'Expense'
 GROUP BY day_type
 ORDER BY Num_Transactions DESC;
 
-- 15. Which are the top 10 largest transactions overall?
SELECT transactions.transaction_id, transactions.transaction_date, accounts.account_name, categories.category_name,
ABS(transactions.amount) AS Total_Amount
FROM transactions
JOIN accounts ON accounts.account_id = transactions.account_id
JOIN categories ON categories.category_id = transactions.category_id
ORDER BY Total_Amount DESC LIMIT 10;

-- 16 What is the current balance of each account?
SELECT accounts.account_id,accounts.account_name, accounts.account_type,accounts.opening_balance,
(accounts.opening_balance + COALESCE(SUM(transactions.amount),0)) AS Current_Balance 
FROM transactions JOIN accounts
ON accounts.account_id = transactions.account_id
GROUP BY accounts.account_id, accounts.account_name, accounts.account_type,accounts.opening_balance
ORDER BY Current_Balance DESC LIMIT 10;

-- 17 How much is income growing or shrinking month over month?

WITH monthly AS (
SELECT 
	DATE_FORMAT(transactions.transaction_date, '%Y-%m') AS Month_Wise,
    SUM(ABS(transactions.amount)) AS income 
    FROM transactions 
    JOIN categories
    ON categories.category_id = transactions.category_id
    WHERE categories.transaction_type = 'Income'
    GROUP BY Month_Wise
)
SELECT Month_Wise, income ,
ROUND((income - LAG(income) OVER(ORDER BY Month_Wise))*100/ 
NULLIF(LAG(income) OVER(ORDER BY Month_Wise),0),2) AS Growth_Rate 
FROM monthly ORDER BY Month_Wise;

-- 18. How much are expenses growing or shrinking month over month?
WITH monthly AS(
SELECT 
DATE_FORMAT(transactions.transaction_date, '%Y-%m') AS month_wise,
SUM(transactions.amount) AS Expense
FROM transactions
JOIN categories ON categories.category_id = transactions.category_id
WHERE categories.transaction_type = 'Expense'
GROUP BY month_wise 
)
SELECT month_wise, Expense,
(Expense) - LAG(Expense) OVER(ORDER BY month_wise) *100/
NULLIF(LAG(Expense) OVER(ORDER BY month_wise),0) AS Growing_Rate
FROM monthly ORDER BY month_wise;

-- 19 What percentage does each category contribute to total spending?
WITH monthly AS (
SELECT 
SUM(ABS(transactions.amount)) AS Total_Expense
FROM transactions join categories
ON categories.category_id = transactions.category_id
WHERE categories.transaction_type = 'Expense'

)
SELECT categories.category_name as Category_Name,
	SUM(ABS(transactions.amount)) AS categor_Expense,
    ROUND((SUM(ABS(transactions.amount))*100/(SELECT Total_Expense FROM monthly)),2) AS Percentage_Contribution
    FROM transactions join categories
	ON categories.category_id = transactions.category_id
	WHERE categories.transaction_type = 'Expense' 
    GROUP BY Category_Name
    ORDER BY categor_Expense DESC LIMIT 10;
    
-- 20 What does the overall financial health dashboard look like .
-- (summary of key numbers)
 select * from accounts;
select * from transactions;
select * from categories;

SELECT
 SUM(CASE WHEN categories.transaction_type = 'Income' THEN ABS(transactions.amount) ELSE 0 END) AS Total_Income,
 SUM(CASE WHEN categories.transaction_type = 'Expense' THEN ABS(transactions.amount) ELSE 0 END) AS Total_Expense,
 
 SUM(CASE WHEN categories.transaction_type = 'Income' THEN ABS(transactions.amount) ELSE 0 END) - 
 SUM(CASE WHEN categories.transaction_type = 'Expense' THEN ABS(transactions.amount) ELSE 0 END) AS Net_Savings,
 
 (SUM(CASE WHEN categories.transaction_type = 'Income' THEN ABS(transactions.amount) ELSE 0 END)- 
 SUM(CASE WHEN categories.transaction_type = 'Expense' THEN ABS(transactions.amount) ELSE 0 END))*100/
 NULLIF(SUM(CASE WHEN categories.transaction_type = 'Income' THEN ABS(transactions.amount) ELSE 0 END),0) AS Savings_Rate_Percentage,
 
 COUNT(DISTINCT(transactions.transaction_id)) AS Total_transactions,
 COUNT(DISTINCT(transactions.account_id)) AS Active_Account
 
 FROM transactions join categories
 ON categories.category_id = transactions.category_id
 
	

