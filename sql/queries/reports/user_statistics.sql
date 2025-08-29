-- Query: user_statistics.sql
-- Description: ユーザー統計レポート
-- Created: 2024-01-01
-- Author: System

USE practice_db;

-- ユーザー登録統計（月別）
SELECT 
    DATE_FORMAT(created_at, '%Y-%m') AS month,
    COUNT(*) AS new_users
FROM users 
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(created_at, '%Y-%m')
ORDER BY month DESC;

-- ユーザー登録統計（日別）
SELECT 
    DATE(created_at) AS registration_date,
    COUNT(*) AS new_users
FROM users 
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY DATE(created_at)
ORDER BY registration_date DESC;

-- ユーザー総数
SELECT 
    COUNT(*) AS total_users,
    COUNT(DISTINCT username) AS unique_usernames,
    COUNT(DISTINCT email) AS unique_emails
FROM users;
