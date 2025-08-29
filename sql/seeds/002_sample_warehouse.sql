-- Seed: 002_sample_warehouse.sql
-- Description: サンプル倉庫データの挿入
-- Created: 2024-01-01
-- Author: System

USE practice_db;

-- サンプル倉庫データの挿入
INSERT INTO warehouse (warehouse_id, region) VALUES
    (1, 'East Coast'),
    (2, 'East Coast'),
    (3, 'West Coast'),
    (4, 'West Coast'),
    (5, 'West Coast')
ON DUPLICATE KEY UPDATE
    region = VALUES(region);
