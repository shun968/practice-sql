-- Query: warehouse_city_mapping.sql
-- Description: 倉庫IDと都市名のマッピング表示
-- Created: 2024-01-01
-- Author: System

USE practice_db;

-- 倉庫IDと都市名のマッピング
SELECT 
    CASE 
        WHEN warehouse_id = 1 THEN 'New York'
        WHEN warehouse_id = 2 THEN 'New Jersey'
        WHEN warehouse_id = 3 THEN 'Los Angeles'
        WHEN warehouse_id = 4 THEN 'Seattle'
        WHEN warehouse_id = 5 THEN 'San Francisco'
        ELSE 'Non domestic'
    END AS city, 
    region 
FROM warehouse
ORDER BY warehouse_id;
