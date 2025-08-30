-- Query: correlated_subquery_vs_window.sql
-- Description: 相関サブクエリとwindow関数の実行計画比較
-- Created: 2024-01-01
-- Author: System

USE practice_db;

-- ========================================
-- 1. 相関サブクエリを使用したクエリ
-- ========================================

-- 各ユーザーの売上金額が、その地域の平均売上金額を上回る売上を取得
EXPLAIN ANALYZE
SELECT 
    s.user_id,
    s.product_name,
    s.amount,
    s.region,
    s.sale_date
FROM sales s
WHERE s.amount > (
    SELECT AVG(s2.amount)
    FROM sales s2
    WHERE s2.region = s.region
);

-- ========================================
-- 2. Window関数を使用したクエリ
-- ========================================

-- 各ユーザーの売上金額が、その地域の平均売上金額を上回る売上を取得
EXPLAIN ANALYZE
SELECT 
    user_id,
    product_name,
    amount,
    region,
    sale_date
FROM (
    SELECT 
        s.user_id,
        s.product_name,
        s.amount,
        s.region,
        s.sale_date,
        AVG(s.amount) OVER (PARTITION BY s.region) AS region_avg
    FROM sales s
) ranked_sales
WHERE amount > region_avg;

-- ========================================
-- 3. 従業員の給与ランキング比較
-- ========================================

-- 相関サブクエリ: 各部門で給与が上位2位以内の従業員
EXPLAIN ANALYZE
SELECT 
    e.name,
    e.salary,
    d.department_name
FROM employees e
JOIN departments d ON e.department_id = d.id
WHERE (
    SELECT COUNT(*)
    FROM employees e2
    WHERE e2.department_id = e.department_id
    AND e2.salary > e.salary
) < 2
ORDER BY e.department_id, e.salary DESC;

-- Window関数: 各部門で給与が上位2位以内の従業員
EXPLAIN ANALYZE
SELECT 
    name,
    salary,
    department_name
FROM (
    SELECT 
        e.name,
        e.salary,
        d.department_name,
        ROW_NUMBER() OVER (
            PARTITION BY e.department_id 
            ORDER BY e.salary DESC
        ) AS salary_rank
    FROM employees e
    JOIN departments d ON e.department_id = d.id
) ranked_employees
WHERE salary_rank <= 2;

-- ========================================
-- 4. 累積売上金額の比較
-- ========================================

-- 相関サブクエリ: 各ユーザーの累積売上金額
EXPLAIN ANALYZE
SELECT 
    s.user_id,
    s.product_name,
    s.amount,
    s.sale_date,
    (
        SELECT SUM(s2.amount)
        FROM sales s2
        WHERE s2.user_id = s.user_id
        AND s2.sale_date <= s.sale_date
    ) AS cumulative_amount
FROM sales s
ORDER BY s.user_id, s.sale_date;

-- Window関数: 各ユーザーの累積売上金額
EXPLAIN ANALYZE
SELECT 
    user_id,
    product_name,
    amount,
    sale_date,
    SUM(amount) OVER (
        PARTITION BY user_id 
        ORDER BY sale_date 
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_amount
FROM sales
ORDER BY user_id, sale_date;
