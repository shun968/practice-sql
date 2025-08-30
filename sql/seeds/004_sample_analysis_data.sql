-- Seed: 004_sample_analysis_data.sql
-- Description: 相関サブクエリとwindow関数の分析用サンプルデータ
-- Created: 2024-01-01
-- Author: System

USE practice_db;

-- 商品データの挿入
INSERT INTO products (product_name, category, price) VALUES
('Laptop Pro', 'Electronics', 1299.99),
('Smartphone X', 'Electronics', 899.99),
('Wireless Headphones', 'Electronics', 199.99),
('Office Chair', 'Furniture', 299.99),
('Desk Lamp', 'Furniture', 89.99),
('Coffee Maker', 'Appliances', 149.99),
('Blender', 'Appliances', 79.99),
('Running Shoes', 'Sports', 129.99),
('Yoga Mat', 'Sports', 39.99),
('Backpack', 'Accessories', 59.99)
ON DUPLICATE KEY UPDATE
    category = VALUES(category),
    price = VALUES(price);

-- 部門データの挿入
INSERT INTO departments (department_name, budget) VALUES
('Engineering', 500000.00),
('Sales', 300000.00),
('Marketing', 200000.00),
('HR', 150000.00),
('Finance', 250000.00)
ON DUPLICATE KEY UPDATE
    budget = VALUES(budget);

-- 従業員データの挿入
INSERT INTO employees (name, department_id, salary, hire_date) VALUES
('Alice Johnson', 1, 85000.00, '2020-01-15'),
('Bob Smith', 1, 92000.00, '2019-03-20'),
('Carol Davis', 2, 65000.00, '2021-06-10'),
('David Wilson', 2, 70000.00, '2020-11-05'),
('Eva Brown', 3, 55000.00, '2022-02-28'),
('Frank Miller', 3, 58000.00, '2021-09-15'),
('Grace Lee', 4, 45000.00, '2022-04-12'),
('Henry Garcia', 4, 48000.00, '2021-12-03'),
('Ivy Chen', 5, 75000.00, '2020-08-22'),
('Jack Taylor', 5, 80000.00, '2019-12-01')
ON DUPLICATE KEY UPDATE
    salary = VALUES(salary),
    hire_date = VALUES(hire_date);

-- 売上データの挿入（大量データでパフォーマンス比較用）
INSERT INTO sales (user_id, product_name, amount, sale_date, region) VALUES
-- User 1 の売上
(1, 'Laptop Pro', 1299.99, '2024-01-15', 'East Coast'),
(1, 'Smartphone X', 899.99, '2024-01-20', 'East Coast'),
(1, 'Wireless Headphones', 199.99, '2024-02-05', 'East Coast'),
(1, 'Office Chair', 299.99, '2024-02-10', 'East Coast'),
(1, 'Desk Lamp', 89.99, '2024-03-01', 'East Coast'),

-- User 2 の売上
(2, 'Laptop Pro', 1299.99, '2024-01-10', 'West Coast'),
(2, 'Coffee Maker', 149.99, '2024-01-25', 'West Coast'),
(2, 'Blender', 79.99, '2024-02-15', 'West Coast'),
(2, 'Running Shoes', 129.99, '2024-02-28', 'West Coast'),
(2, 'Yoga Mat', 39.99, '2024-03-05', 'West Coast'),

-- User 3 の売上
(3, 'Smartphone X', 899.99, '2024-01-05', 'East Coast'),
(3, 'Wireless Headphones', 199.99, '2024-01-30', 'East Coast'),
(3, 'Office Chair', 299.99, '2024-02-20', 'East Coast'),
(3, 'Desk Lamp', 89.99, '2024-03-10', 'East Coast'),
(3, 'Backpack', 59.99, '2024-03-15', 'East Coast'),

-- User 4 の売上
(4, 'Laptop Pro', 1299.99, '2024-01-12', 'West Coast'),
(4, 'Coffee Maker', 149.99, '2024-02-01', 'West Coast'),
(4, 'Blender', 79.99, '2024-02-18', 'West Coast'),
(4, 'Running Shoes', 129.99, '2024-03-01', 'West Coast'),
(4, 'Yoga Mat', 39.99, '2024-03-08', 'West Coast'),

-- User 5 の売上
(5, 'Smartphone X', 899.99, '2024-01-08', 'East Coast'),
(5, 'Wireless Headphones', 199.99, '2024-01-28', 'East Coast'),
(5, 'Office Chair', 299.99, '2024-02-12', 'East Coast'),
(5, 'Desk Lamp', 89.99, '2024-03-03', 'East Coast'),
(5, 'Backpack', 59.99, '2024-03-12', 'East Coast')
ON DUPLICATE KEY UPDATE
    amount = VALUES(amount),
    sale_date = VALUES(sale_date),
    region = VALUES(region);
