-- Migration: 001_create_users_table.sql
-- Description: ユーザーテーブルの作成
-- Created: 2024-01-01
-- Author: System

USE practice_db;

-- サンプルテーブルの作成
USE practice_db;

-- ユーザーテーブル
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- マイグレーション実行履歴テーブルの作成
CREATE TABLE IF NOT EXISTS migration_history (
    id INT PRIMARY KEY AUTO_INCREMENT,
    migration_name VARCHAR(255) NOT NULL UNIQUE,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    execution_time_ms INT,
    status ENUM('SUCCESS', 'FAILED') NOT NULL,
    error_message TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
