-- パフォーマンステスト用サンプルデータの生成
-- データ量・インデックス・テーブル結合の影響を検証

-- マスターテーブルのデータ生成
INSERT INTO master_table (code, name, description, status) VALUES
('M001', 'Electronics', 'Electronics and gadgets', 'active'),
('M002', 'Clothing', 'Fashion and apparel', 'active'),
('M003', 'Books', 'Books and publications', 'active'),
('M004', 'Home', 'Home and garden', 'active'),
('M005', 'Sports', 'Sports and fitness', 'inactive'),
('M006', 'Food', 'Food and beverages', 'active'),
('M007', 'Automotive', 'Automotive parts', 'pending'),
('M008', 'Health', 'Health and beauty', 'active'),
('M009', 'Toys', 'Toys and games', 'active'),
('M010', 'Tools', 'Tools and hardware', 'active')
ON DUPLICATE KEY UPDATE 
    created_at = CURRENT_TIMESTAMP;

-- 詳細テーブルのデータ生成（マスターテーブルとの結合用）
INSERT INTO detail_table (master_id, item_name, quantity, unit_price, total_price) VALUES
(1, 'Smartphone', 5, 500.00, 2500.00),
(1, 'Laptop', 3, 1200.00, 3600.00),
(1, 'Tablet', 8, 300.00, 2400.00),
(2, 'T-Shirt', 20, 25.00, 500.00),
(2, 'Jeans', 15, 80.00, 1200.00),
(2, 'Shoes', 10, 120.00, 1200.00),
(3, 'Programming Book', 12, 45.00, 540.00),
(3, 'Novel', 25, 15.00, 375.00),
(3, 'Magazine', 30, 8.00, 240.00),
(4, 'Garden Chair', 6, 75.00, 450.00),
(4, 'Plant Pot', 15, 12.00, 180.00),
(4, 'Garden Tool', 8, 35.00, 280.00)
ON DUPLICATE KEY UPDATE 
    created_at = CURRENT_TIMESTAMP;

-- 小規模テーブルのデータ生成（100行）
INSERT INTO small_table (name, category, value)
SELECT 
    CONCAT('Item_', LPAD(numbers.n, 3, '0')) as name,
    CASE 
        WHEN numbers.n % 4 = 0 THEN 'Category_A'
        WHEN numbers.n % 4 = 1 THEN 'Category_B'
        WHEN numbers.n % 4 = 2 THEN 'Category_C'
        ELSE 'Category_D'
    END as category,
    ROUND(RAND() * 1000, 2) as value
FROM (
    SELECT 1 + ones.n + 10 * tens.n as n
    FROM (SELECT 0 n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) ones,
         (SELECT 0 n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) tens
    WHERE 1 + ones.n + 10 * tens.n <= 100
) numbers
ON DUPLICATE KEY UPDATE 
    created_at = CURRENT_TIMESTAMP;

-- 中規模テーブルのデータ生成（1,000,000行）
INSERT INTO medium_table (name, category, value)
SELECT 
    CONCAT('Medium_Item_', LPAD(numbers.n, 7, '0')) as name,
    CASE 
        WHEN numbers.n % 6 = 0 THEN 'Category_A'
        WHEN numbers.n % 6 = 1 THEN 'Category_B'
        WHEN numbers.n % 6 = 2 THEN 'Category_C'
        WHEN numbers.n % 6 = 3 THEN 'Category_D'
        WHEN numbers.n % 6 = 4 THEN 'Category_E'
        ELSE 'Category_F'
    END as category,
    ROUND(RAND() * 1000, 2) as value
FROM (
    SELECT 1 + ones.n + 10 * tens.n + 100 * hundreds.n + 1000 * thousands.n + 10000 * ten_thousands.n + 100000 * hundred_thousands.n as n
    FROM (SELECT 0 n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) ones,
         (SELECT 0 n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) tens,
         (SELECT 0 n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) hundreds,
         (SELECT 0 n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) thousands,
         (SELECT 0 n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) ten_thousands,
         (SELECT 0 n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) hundred_thousands
    WHERE 1 + ones.n + 10 * tens.n + 100 * hundreds.n + 1000 * thousands.n + 10000 * ten_thousands.n + 100000 * hundred_thousands.n <= 1000000
) numbers
ON DUPLICATE KEY UPDATE 
    created_at = CURRENT_TIMESTAMP;

-- 大規模テーブルのデータ生成（10,000,000行）
INSERT INTO large_table (name, category, value)
SELECT 
    CONCAT('Large_Item_', LPAD(numbers.n, 8, '0')) as name,
    CASE 
        WHEN numbers.n % 7 = 0 THEN 'Category_A'
        WHEN numbers.n % 7 = 1 THEN 'Category_B'
        WHEN numbers.n % 7 = 2 THEN 'Category_C'
        WHEN numbers.n % 7 = 3 THEN 'Category_D'
        WHEN numbers.n % 7 = 4 THEN 'Category_E'
        WHEN numbers.n % 7 = 5 THEN 'Category_F'
        ELSE 'Category_G'
    END as category,
    ROUND(RAND() * 1000, 2) as value
FROM (
    SELECT 1 + ones.n + 10 * tens.n + 100 * hundreds.n + 1000 * thousands.n + 10000 * ten_thousands.n + 100000 * hundred_thousands.n + 1000000 * millions.n as n
    FROM (SELECT 0 n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) ones,
         (SELECT 0 n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) tens,
         (SELECT 0 n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) hundreds,
         (SELECT 0 n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) thousands,
         (SELECT 0 n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) ten_thousands,
         (SELECT 0 n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) hundred_thousands,
         (SELECT 0 n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) millions
    WHERE 1 + ones.n + 10 * tens.n + 100 * hundreds.n + 1000 * thousands.n + 10000 * ten_thousands.n + 100000 * hundred_thousands.n + 1000000 * millions.n <= 10000000
) numbers
ON DUPLICATE KEY UPDATE 
    created_at = CURRENT_TIMESTAMP;
