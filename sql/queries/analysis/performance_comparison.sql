-- パフォーマンス比較テストクエリ
-- データ量・インデックス・テーブル結合の影響を検証

-- 1. データ量による影響の比較（インデックスあり）

-- 小規模テーブル（100行）
EXPLAIN ANALYZE
SELECT category, COUNT(*), AVG(value)
FROM small_table 
WHERE category = 'Category_A'
GROUP BY category;

-- 中規模テーブル（10,000行）
EXPLAIN ANALYZE
SELECT category, COUNT(*), AVG(value)
FROM medium_table 
WHERE category = 'Category_A'
GROUP BY category;

-- 大規模テーブル（100,000行）
EXPLAIN ANALYZE
SELECT category, COUNT(*), AVG(value)
FROM large_table 
WHERE category = 'Category_A'
GROUP BY category;

-- 2. インデックス有無による影響の比較

-- インデックスあり（category）
EXPLAIN ANALYZE
SELECT * FROM medium_table 
WHERE category = 'Category_B' AND value > 500;

-- インデックスなし（valueのみ）
EXPLAIN ANALYZE
SELECT * FROM medium_table 
WHERE value > 500;

-- 複合インデックスあり（category, value）
EXPLAIN ANALYZE
SELECT * FROM medium_table 
WHERE category = 'Category_C' AND value BETWEEN 100 AND 200;

-- 3. テーブル結合の影響比較

-- 小規模結合（master_table + detail_table）
EXPLAIN ANALYZE
SELECT 
    m.name as master_name,
    d.item_name,
    d.quantity,
    d.total_price
FROM master_table m
JOIN detail_table d ON m.id = d.master_id
WHERE m.status = 'active'
ORDER BY d.total_price DESC;

-- 中規模結合（medium_table + master_table）
EXPLAIN ANALYZE
SELECT 
    m.name as master_name,
    med.category,
    COUNT(*) as item_count,
    AVG(med.value) as avg_value
FROM master_table m
JOIN medium_table med ON m.id = (med.id % 10) + 1
WHERE m.status = 'active'
GROUP BY m.name, med.category
HAVING item_count > 100;

-- 4. 集計クエリの比較

-- 単純集計（インデックスあり）
EXPLAIN ANALYZE
SELECT 
    category,
    COUNT(*) as count,
    AVG(value) as avg_value,
    MIN(value) as min_value,
    MAX(value) as max_value
FROM medium_table
GROUP BY category;

-- 条件付き集計（インデックスあり）
EXPLAIN ANALYZE
SELECT 
    category,
    COUNT(*) as count,
    AVG(value) as avg_value
FROM medium_table
WHERE value > 500
GROUP BY category;

-- 5. ソート処理の比較

-- インデックスありでのソート
EXPLAIN ANALYZE
SELECT * FROM medium_table 
WHERE category = 'Category_A'
ORDER BY created_at DESC
LIMIT 100;

-- インデックスなしでのソート
EXPLAIN ANALYZE
SELECT * FROM medium_table 
WHERE value > 500
ORDER BY value DESC
LIMIT 100;

-- 6. 複雑な結合クエリの比較

-- 3テーブル結合
EXPLAIN ANALYZE
SELECT 
    m.name as master_name,
    med.category,
    d.item_name,
    COUNT(*) as detail_count
FROM master_table m
JOIN medium_table med ON m.id = (med.id % 10) + 1
JOIN detail_table d ON m.id = d.master_id
WHERE m.status = 'active' 
  AND med.value > 500
GROUP BY m.name, med.category, d.item_name
HAVING detail_count > 1
ORDER BY detail_count DESC;

-- 7. サブクエリ vs JOIN の比較

-- サブクエリ版
EXPLAIN ANALYZE
SELECT 
    m.name,
    (SELECT COUNT(*) FROM detail_table d WHERE d.master_id = m.id) as detail_count,
    (SELECT AVG(d.total_price) FROM detail_table d WHERE d.master_id = m.id) as avg_price
FROM master_table m
WHERE m.status = 'active';

-- JOIN版
EXPLAIN ANALYZE
SELECT 
    m.name,
    COUNT(d.id) as detail_count,
    AVG(d.total_price) as avg_price
FROM master_table m
LEFT JOIN detail_table d ON m.id = d.master_id
WHERE m.status = 'active'
GROUP BY m.id, m.name;

-- 8. データ分布の確認

-- 各テーブルの行数確認
SELECT 
    'small_table' as table_name,
    COUNT(*) as row_count,
    COUNT(DISTINCT category) as category_count,
    MIN(value) as min_value,
    MAX(value) as max_value,
    AVG(value) as avg_value
FROM small_table
UNION ALL
SELECT 
    'medium_table' as table_name,
    COUNT(*) as row_count,
    COUNT(DISTINCT category) as category_count,
    MIN(value) as min_value,
    MAX(value) as max_value,
    AVG(value) as avg_value
FROM medium_table
UNION ALL
SELECT 
    'large_table' as table_name,
    COUNT(*) as row_count,
    COUNT(DISTINCT category) as category_count,
    MIN(value) as min_value,
    MAX(value) as max_value,
    AVG(value) as avg_value
FROM large_table;

-- カテゴリ別の分布確認
SELECT 
    'small_table' as table_name,
    category,
    COUNT(*) as count,
    AVG(value) as avg_value
FROM small_table
GROUP BY category
UNION ALL
SELECT 
    'medium_table' as table_name,
    category,
    COUNT(*) as count,
    AVG(value) as avg_value
FROM medium_table
GROUP BY category
UNION ALL
SELECT 
    'large_table' as table_name,
    category,
    COUNT(*) as count,
    AVG(value) as avg_value
FROM large_table
GROUP BY category
ORDER BY table_name, category;
