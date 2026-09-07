# 💰 Financial Data Analysis Using SQL

A comprehensive SQL project analyzing personal/business financial data — covering income, expenses, savings, budgets, account balances, and spending trends using MySQL.

---

## 📌 Project Overview

This project uses SQL to analyze a financial database (`finance_db`) containing **accounts**, **transactions**, and **categories** tables. The goal is to answer 20 real-world business questions that help understand income patterns, spending behavior, savings rate, budget variance, and overall financial health.

---

## 🗂️ Database Schema

| Table | Description |
|---|---|
| `accounts` | Stores account details (account ID, name, type, opening balance) |
| `transactions` | Stores individual transactions (amount, date, account, category) |
| `categories` | Stores category details and transaction type (Income/Expense) |

---

## 🛠️ Tools & Technologies

- **Database:** MySQL
- **Concepts Used:** Joins, Aggregate Functions, CTEs (Common Table Expressions), Window Functions (`LAG`, `SUM OVER`), Subqueries, `CASE` Statements, Date Formatting, `HAVING`, `GROUP BY`

---

## ❓ Business Problems & Solutions

### 1. What is the total income across all accounts?
```sql
SELECT SUM(ABS(transactions.amount)) AS Total_Income 
FROM transactions 
JOIN categories ON categories.category_id = transactions.category_id
WHERE categories.transaction_type = "Income";
```

### 2. What is the total amount of expenses across all accounts?
```sql
SELECT SUM(ABS(transactions.amount)) AS Total_Amount 
FROM transactions
JOIN categories ON categories.category_id = transactions.category_id
WHERE categories.transaction_type = "Expense";
```

### 3. What is the net savings (total income minus total expenses)?
```sql
SELECT 
    ROUND(SUM(CASE WHEN categories.transaction_type = "Income" THEN ABS(transactions.amount) ELSE 0 END), 2) AS Total_Income,
    ROUND(SUM(CASE WHEN categories.transaction_type = "Expense" THEN ABS(transactions.amount) ELSE 0 END), 2) AS Total_Expenses,
    (SUM(CASE WHEN categories.transaction_type = "Income" THEN ABS(transactions.amount) ELSE 0 END) - 
     SUM(CASE WHEN categories.transaction_type = "Expense" THEN ABS(transactions.amount) ELSE 0 END)) AS Net_Saving
FROM transactions 
JOIN categories ON categories.category_id = transactions.category_id;
```

### 4. What percentage of income is being saved (savings rate)?
```sql
SELECT 
    ROUND(SUM(CASE WHEN categories.transaction_type = "Income" THEN ABS(transactions.amount) ELSE 0 END), 2) AS Total_Income,
    ROUND(SUM(CASE WHEN transaction_type = "Expense" THEN ABS(transactions.amount) ELSE 0 END), 2) AS Total_Expenses,
    ROUND((SUM(CASE WHEN categories.transaction_type = "Income" THEN ABS(transactions.amount) ELSE 0 END) -
           SUM(CASE WHEN categories.transaction_type = "Expense" THEN ABS(transactions.amount) ELSE 0 END)) * 100.0 /
          NULLIF(SUM(CASE WHEN categories.transaction_type = "Income" THEN ABS(transactions.amount) ELSE 0 END), 0), 2) AS Saving_Rate_Percent
FROM transactions 
JOIN categories ON categories.category_id = transactions.category_id;
```

### 5. What is the monthly cash flow (income vs expenses per month)?
```sql
SELECT 
    DATE_FORMAT(transactions.transaction_date, '%Y-%m') AS Month_Wise,
    SUM(CASE WHEN categories.transaction_type = "Income" THEN ABS(transactions.amount) ELSE 0 END) AS Total_Income,
    SUM(CASE WHEN categories.transaction_type = "Expense" THEN ABS(transactions.amount) ELSE 0 END) AS Total_Expenses,
    ROUND(SUM(CASE WHEN categories.transaction_type = "Income" THEN ABS(transactions.amount) ELSE -ABS(transactions.amount) END), 2) AS Monthly_Cash_Flow
FROM transactions 
JOIN categories ON categories.category_id = transactions.category_id
GROUP BY Month_Wise
ORDER BY Month_Wise 
LIMIT 12;
```

### 6. How much income is coming from each income source/category?
```sql
SELECT categories.category_name AS Income_Source, SUM(ABS(transactions.amount)) AS Total_Amount 
FROM transactions 
JOIN categories ON categories.category_id = transactions.category_id
WHERE categories.transaction_type = 'Income'
GROUP BY Income_Source
ORDER BY Total_Amount DESC 
LIMIT 10;
```

### 7. How much is being spent in each expense category?
```sql
SELECT categories.category_name AS Category_Name, SUM(ABS(transactions.amount)) AS Total_Expense 
FROM transactions 
JOIN categories ON categories.category_id = transactions.category_id
WHERE categories.transaction_type = 'Expense'
GROUP BY Category_Name
ORDER BY Total_Expense DESC 
LIMIT 10;
```

### 8. Which expense category has the highest total spending?
```sql
SELECT categories.category_name AS Category_Name, SUM(ABS(transactions.amount)) AS Total_Amount
FROM transactions 
JOIN categories ON categories.category_id = transactions.category_id
WHERE categories.transaction_type = "Expense"
GROUP BY Category_Name
ORDER BY Total_Amount DESC 
LIMIT 1;
```

### 9. How does actual spending compare to the budgeted amount for each category?
```sql
WITH Monthly AS (
    SELECT 
        DATE_FORMAT(transactions.transaction_date, '%Y-%m') AS Monthly_Wise, 
        categories.category_name AS Category_Name, 
        SUM(ABS(transactions.amount)) AS Spend_Amount 
    FROM transactions 
    JOIN categories ON categories.category_id = transactions.category_id
    WHERE categories.transaction_type = "Expense"
    GROUP BY Category_Name, Monthly_Wise
),
budget AS (
    SELECT Category_Name, ROUND(AVG(Spend_Amount), 2) AS Budget_Amount 
    FROM Monthly
    GROUP BY Category_Name
),
latest_Month AS (
    SELECT MAX(Monthly_Wise) AS m FROM Monthly
),
Actual AS (
    SELECT Category_Name, ROUND(Spend_Amount, 2) AS Actual_Amount 
    FROM Monthly, latest_Month
    WHERE Monthly.Monthly_Wise = latest_Month.m
)
SELECT 
    budget.Category_Name, 
    budget.Budget_Amount, 
    COALESCE(Actual.Actual_Amount, 0) AS Actual_Amount,
    COALESCE(Actual.Actual_Amount, 0) - budget.Budget_Amount AS Variance
FROM budget 
LEFT JOIN Actual ON Actual.Category_Name = budget.Category_Name
ORDER BY Variance DESC 
LIMIT 10;
```

### 10. What is the average amount spent per day?
```sql
SELECT ROUND(SUM(ABS(amount)) * 1.0 / COUNT(DISTINCT transaction_date), 2) AS Avg_Daily_Spending 
FROM transactions 
JOIN categories ON categories.category_id = transactions.category_id
WHERE categories.transaction_type = 'Expense';
```

### 11. What is the trend of total spending month by month?
```sql
SELECT 
    DATE_FORMAT(transactions.transaction_date, '%Y-%m') AS Month_Wise,
    SUM(ABS(transactions.amount)) AS Spending_Amount 
FROM transactions
JOIN categories ON categories.category_id = transactions.category_id
WHERE categories.transaction_type = 'Expense'
GROUP BY Month_Wise
ORDER BY Month_Wise 
LIMIT 12;
```

### 12. What is the running account balance after each transaction?
```sql
WITH top_account AS (
    SELECT account_id FROM transactions
    GROUP BY account_id 
    ORDER BY COUNT(*) DESC 
    LIMIT 1
) 
SELECT 
    transactions.transaction_id, 
    transactions.transaction_date,
    transactions.amount AS Amount,
    accounts.opening_balance + SUM(transactions.amount) OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Running_Balance 
FROM transactions
JOIN accounts ON accounts.account_id = transactions.account_id
WHERE transactions.account_id = (SELECT account_id FROM top_account)
ORDER BY transactions.account_id, transactions.transaction_date 
LIMIT 10;
```

### 13. Which expenses are recurring every month (subscriptions, bills, etc.)?
```sql
SELECT
    categories.category_name AS Category_Name,
    COUNT(DISTINCT(DATE_FORMAT(transactions.transaction_date, '%Y-%m'))) AS Months_Active,
    SUM(ABS(transactions.amount)) AS Total_Spent,
    ROUND(AVG(ABS(transactions.amount)), 2) AS Avg_Spent
FROM transactions
JOIN categories ON categories.category_id = transactions.category_id
WHERE categories.transaction_type = 'Expense'
GROUP BY Category_Name
HAVING Months_Active >= 6
ORDER BY Months_Active DESC, Total_Spent DESC 
LIMIT 10;
```

### 14. Is spending higher on weekends or on weekdays?
```sql
SELECT
    CASE WHEN DAYOFWEEK(transactions.transaction_date) IN (1, 7) THEN 'Weekend' ELSE 'Weekday' END AS Day_Type,
    COUNT(*) AS Num_Transactions,
    SUM(ABS(transactions.amount)) AS Total_Spent,
    ROUND(AVG(ABS(transactions.amount)), 2) AS Avg_Spent
FROM transactions
JOIN categories ON categories.category_id = transactions.category_id
WHERE categories.transaction_type = 'Expense'
GROUP BY Day_Type
ORDER BY Num_Transactions DESC;
```

### 15. Which are the top 10 largest transactions overall?
```sql
SELECT 
    transactions.transaction_id, 
    transactions.transaction_date, 
    accounts.account_name, 
    categories.category_name,
    ABS(transactions.amount) AS Total_Amount
FROM transactions
JOIN accounts ON accounts.account_id = transactions.account_id
JOIN categories ON categories.category_id = transactions.category_id
ORDER BY Total_Amount DESC 
LIMIT 10;
```

### 16. What is the current balance of each account?
```sql
SELECT 
    accounts.account_id, 
    accounts.account_name, 
    accounts.account_type, 
    accounts.opening_balance,
    (accounts.opening_balance + COALESCE(SUM(transactions.amount), 0)) AS Current_Balance 
FROM transactions 
JOIN accounts ON accounts.account_id = transactions.account_id
GROUP BY accounts.account_id, accounts.account_name, accounts.account_type, accounts.opening_balance
ORDER BY Current_Balance DESC 
LIMIT 10;
```

### 17. How much is income growing or shrinking month over month?
```sql
WITH monthly AS (
    SELECT 
        DATE_FORMAT(transactions.transaction_date, '%Y-%m') AS Month_Wise,
        SUM(ABS(transactions.amount)) AS Income 
    FROM transactions 
    JOIN categories ON categories.category_id = transactions.category_id
    WHERE categories.transaction_type = 'Income'
    GROUP BY Month_Wise
)
SELECT 
    Month_Wise, 
    Income,
    ROUND((Income - LAG(Income) OVER (ORDER BY Month_Wise)) * 100 / 
          NULLIF(LAG(Income) OVER (ORDER BY Month_Wise), 0), 2) AS Growth_Rate 
FROM monthly 
ORDER BY Month_Wise;
```

### 18. How much are expenses growing or shrinking month over month?
```sql
WITH monthly AS (
    SELECT 
        DATE_FORMAT(transactions.transaction_date, '%Y-%m') AS Month_Wise,
        SUM(transactions.amount) AS Expense
    FROM transactions
    JOIN categories ON categories.category_id = transactions.category_id
    WHERE categories.transaction_type = 'Expense'
    GROUP BY Month_Wise 
)
SELECT 
    Month_Wise, 
    Expense,
    (Expense - LAG(Expense) OVER (ORDER BY Month_Wise)) * 100 /
    NULLIF(LAG(Expense) OVER (ORDER BY Month_Wise), 0) AS Growth_Rate
FROM monthly 
ORDER BY Month_Wise;
```

### 19. What percentage does each category contribute to total spending?
```sql
WITH monthly AS (
    SELECT SUM(ABS(transactions.amount)) AS Total_Expense
    FROM transactions 
    JOIN categories ON categories.category_id = transactions.category_id
    WHERE categories.transaction_type = 'Expense'
)
SELECT 
    categories.category_name AS Category_Name,
    SUM(ABS(transactions.amount)) AS Category_Expense,
    ROUND((SUM(ABS(transactions.amount)) * 100 / (SELECT Total_Expense FROM monthly)), 2) AS Percentage_Contribution
FROM transactions 
JOIN categories ON categories.category_id = transactions.category_id
WHERE categories.transaction_type = 'Expense' 
GROUP BY Category_Name
ORDER BY Category_Expense DESC 
LIMIT 10;
```

### 20. What does the overall financial health dashboard look like? (summary of key numbers)
```sql
SELECT
    SUM(CASE WHEN categories.transaction_type = 'Income' THEN ABS(transactions.amount) ELSE 0 END) AS Total_Income,
    SUM(CASE WHEN categories.transaction_type = 'Expense' THEN ABS(transactions.amount) ELSE 0 END) AS Total_Expense,
    SUM(CASE WHEN categories.transaction_type = 'Income' THEN ABS(transactions.amount) ELSE 0 END) - 
    SUM(CASE WHEN categories.transaction_type = 'Expense' THEN ABS(transactions.amount) ELSE 0 END) AS Net_Savings,
    (SUM(CASE WHEN categories.transaction_type = 'Income' THEN ABS(transactions.amount) ELSE 0 END) - 
     SUM(CASE WHEN categories.transaction_type = 'Expense' THEN ABS(transactions.amount) ELSE 0 END)) * 100 /
     NULLIF(SUM(CASE WHEN categories.transaction_type = 'Income' THEN ABS(transactions.amount) ELSE 0 END), 0) AS Savings_Rate_Percentage,
    COUNT(DISTINCT(transactions.transaction_id)) AS Total_Transactions,
    COUNT(DISTINCT(transactions.account_id)) AS Active_Accounts
FROM transactions 
JOIN categories ON categories.category_id = transactions.category_id;
```

---

## 📈 Key Results

| Metric | Value |
|---|---|
| Total Records in Dataset | 2,000 |
| Total Income | ₹14,81,602.09 |
| Total Expenses | ₹15,08,106.99 |
| Net Savings | −₹26,504.90 |
| Savings Rate | −1.79% |
| Total Transactions | 2,000 |
| Active Accounts | 1,254 |

**Observation:** Total expenses (₹15.08L) slightly exceeded total income (₹14.82L) across the dataset, resulting in a **negative net savings** of ₹26,504.90 and a **savings rate of −1.79%**. This kind of finding is exactly what a structured SQL analysis is meant to surface early — a household or business spending marginally more than it earns, before the gap widens.

---

## 📊 Key Insights

- Calculated **total income (₹14.82L), total expenses (₹15.08L)**, and a **net savings of −₹26,504.90** across all accounts.
- Derived a **savings rate of −1.79%**, revealing that expenses slightly outpaced income overall.
- Built a **month-over-month cash flow** view to track trends.
- Identified **top income sources** and **highest-spending expense categories**.
- Compared **actual vs. budgeted spending** to flag variance.
- Detected **recurring monthly expenses** (subscriptions/bills).
- Analyzed **weekday vs. weekend spending behavior**.
- Tracked **running account balances** using window functions.
- Measured **month-over-month growth rate** for both income and expenses.
- Built a **financial health summary dashboard** combining all key metrics.

---

## 🚀 How to Use

1. Clone this repository.
2. Import the `finance_db` schema and sample data into MySQL.
3. Run the queries in `finance_analysis.sql` sequentially or individually.
4. Modify `LIMIT` clauses or filters as needed for your own dataset.

---

## 📁 Repository Structure

```
├── finance_analysis.sql   # All 20 business problems with SQL solutions
└── README.md              # Project documentation
```

---

## 🏷️ Tags

`SQL` `MySQL` `Data Analysis` `Finance` `Window Functions` `CTE` `Personal Finance Dashboard`

---

## 📬 Connect

If you found this project useful, feel free to ⭐ the repo or connect with me for feedback and collaboration!
