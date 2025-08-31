-- 結合順序とインデックス設計のベストプラクティステスト
-- 結合順序の最適化とインデックス設計の効果を検証

-- ========================================
-- 1. 結合順序の最適化テスト
-- ========================================

-- テスト1: 小さいテーブルから大きいテーブルへの結合（推奨）
-- 期待結果: 小さいテーブルが駆動テーブルになり、ループ回数が最小化される
EXPLAIN ANALYZE
SELECT 
    m.name as master_name,
    d.item_name,
    d.quantity
FROM master_table m          -- 10行（小さいテーブル）
INNER JOIN detail_table d    -- 12行（大きいテーブル）
ON m.id = d.master_id
WHERE m.status = 'active';

-- テスト2: 大きいテーブルから小さいテーブルへの結合（非推奨）
-- 期待結果: 大きいテーブルが駆動テーブルになり、ループ回数が増加
EXPLAIN ANALYZE
SELECT 
    m.name as master_name,
    d.item_name,
    d.quantity
FROM detail_table d          -- 12行（大きいテーブル）
INNER JOIN master_table m    -- 10行（小さいテーブル）
ON d.master_id = m.id
WHERE m.status = 'active';

-- テスト3: WHERE句で絞り込めるテーブルを先に結合（推奨）
-- 期待結果: 早期フィルタリングにより処理対象行数が削減される
EXPLAIN ANALYZE
SELECT 
    m.name as master_name,
    d.item_name,
    d.quantity
FROM master_table m
INNER JOIN detail_table d ON m.id = d.master_id
WHERE m.status = 'active'    -- 早期フィルタリング
AND d.quantity > 5;

-- テスト4: インデックスが効くテーブルを先に結合（推奨）
-- 期待結果: インデックススキャンにより高速処理が可能
EXPLAIN ANALYZE
SELECT 
    m.name as master_name,
    d.item_name,
    d.quantity
FROM master_table m          -- 主キーインデックスあり
INNER JOIN detail_table d    -- 外部キーインデックスあり
ON m.id = d.master_id
WHERE m.status = 'active';

-- ========================================
-- 2. インデックス設計の最適化テスト
-- ========================================

-- テスト5: 結合条件のインデックス（推奨）
-- 期待結果: 外部キーインデックスにより結合が高速化
EXPLAIN ANALYZE
SELECT 
    m.name as master_name,
    d.item_name,
    d.quantity
FROM master_table m
INNER JOIN detail_table d ON m.id = d.master_id  -- インデックスあり
WHERE m.status = 'active';

-- テスト6: WHERE句のインデックス（推奨）
-- 期待結果: WHERE句のインデックスによりフィルタリングが高速化
EXPLAIN ANALYZE
SELECT 
    m.name as master_name,
    d.item_name,
    d.quantity
FROM master_table m
INNER JOIN detail_table d ON m.id = d.master_id
WHERE m.status = 'active'    -- インデックスあり
AND d.quantity > 5;

-- テスト7: 複合インデックスの順序（推奨）
-- 期待結果: 等価比較 → 範囲比較の順序でインデックスが効く
EXPLAIN ANALYZE
SELECT 
    m.name as master_name,
    d.item_name,
    d.quantity
FROM master_table m
INNER JOIN detail_table d ON m.id = d.master_id
WHERE m.status = 'active'        -- 等価比較（先頭）
AND d.created_at > '2024-01-01'  -- 範囲比較（2番目）
ORDER BY d.quantity DESC;        -- ソート（3番目）

-- テスト8: カバリングインデックス（推奨）
-- 期待結果: テーブルアクセスを回避し、インデックスからのみデータ取得
EXPLAIN ANALYZE
SELECT 
    m.name,                     -- インデックスに含まれる
    m.status,                   -- インデックスに含まれる
    d.item_name,                -- インデックスに含まれる
    d.quantity                  -- インデックスに含まれる
FROM master_table m
INNER JOIN detail_table d ON m.id = d.master_id
WHERE m.status = 'active'
AND d.quantity > 5;

-- ========================================
-- 3. 複雑な結合の最適化テスト
-- ========================================

-- テスト9: 3テーブル結合の最適な順序
-- 期待結果: 小さいテーブルから順に結合し、インデックスを活用
EXPLAIN ANALYZE
SELECT 
    m.name as master_name,
    med.category,
    d.item_name,
    COUNT(*) as detail_count
FROM master_table m            -- 10行（最小）
INNER JOIN detail_table d      -- 12行（中）
ON m.id = d.master_id
INNER JOIN medium_table med    -- 100万行（最大）
ON m.id = (med.id % 10) + 1
WHERE m.status = 'active' 
AND med.value > 500
GROUP BY m.name, med.category, d.item_name
HAVING detail_count > 1
ORDER BY detail_count DESC;

-- テスト10: 非最適な3テーブル結合順序
-- 期待結果: 大きいテーブルから結合し、パフォーマンスが劣化
EXPLAIN ANALYZE
SELECT 
    m.name as master_name,
    med.category,
    d.item_name,
    COUNT(*) as detail_count
FROM medium_table med          -- 100万行（最大）
INNER JOIN master_table m      -- 10行（最小）
ON m.id = (med.id % 10) + 1
INNER JOIN detail_table d      -- 12行（中）
ON m.id = d.master_id
WHERE m.status = 'active' 
AND med.value > 500
GROUP BY m.name, med.category, d.item_name
HAVING detail_count > 1
ORDER BY detail_count DESC;

-- ========================================
-- 4. カーディナリティの影響テスト
-- ========================================

-- テスト11: 高カーディナリティでの結合（推奨）
-- 期待結果: 主キーでの結合により結合結果が最小化
EXPLAIN ANALYZE
SELECT 
    m.name as master_name,
    d.item_name,
    d.quantity
FROM master_table m
INNER JOIN detail_table d ON m.id = d.master_id  -- 主キー（高カーディナリティ）
WHERE m.status = 'active';

-- テスト12: 低カーディナリティでの結合（非推奨）
-- 期待結果: ステータスでの結合により結合結果が増加
EXPLAIN ANALYZE
SELECT 
    m.name as master_name,
    d.item_name,
    d.quantity
FROM master_table m
INNER JOIN detail_table d ON m.status = d.status  -- ステータス（低カーディナリティ）
WHERE m.status = 'active';

-- ========================================
-- 5. インデックスなしでの結合（比較用）
-- ========================================

-- テスト13: インデックスなしでの結合
-- 期待結果: フルテーブルスキャンにより大幅に遅延
EXPLAIN ANALYZE
SELECT 
    m.name as master_name,
    d.item_name,
    d.quantity
FROM master_table m
INNER JOIN detail_table d ON m.id = d.master_id
WHERE m.status = 'active'
AND d.quantity > 5;

-- ========================================
-- 6. 実行計画の分析用クエリ
-- ========================================

-- 各テーブルの統計情報
SELECT 
    'master_table' as table_name,
    COUNT(*) as row_count,
    COUNT(DISTINCT status) as status_count,
    COUNT(DISTINCT id) as id_count
FROM master_table
UNION ALL
SELECT 
    'detail_table' as table_name,
    COUNT(*) as row_count,
    COUNT(DISTINCT master_id) as master_id_count,
    COUNT(DISTINCT item_name) as item_count
FROM detail_table
UNION ALL
SELECT 
    'medium_table' as table_name,
    COUNT(*) as row_count,
    COUNT(DISTINCT category) as category_count,
    COUNT(DISTINCT id) as id_count
FROM medium_table;

-- 結合条件のカーディナリティ分析
SELECT 
    'master_table.id' as column_name,
    COUNT(DISTINCT id) as distinct_values,
    COUNT(*) as total_rows,
    ROUND(COUNT(DISTINCT id) / COUNT(*) * 100, 2) as selectivity_percent
FROM master_table
UNION ALL
SELECT 
    'detail_table.master_id' as column_name,
    COUNT(DISTINCT master_id) as distinct_values,
    COUNT(*) as total_rows,
    ROUND(COUNT(DISTINCT master_id) / COUNT(*) * 100, 2) as selectivity_percent
FROM detail_table
UNION ALL
SELECT 
    'master_table.status' as column_name,
    COUNT(DISTINCT status) as distinct_values,
    COUNT(*) as total_rows,
    ROUND(COUNT(DISTINCT status) / COUNT(*) * 100, 2) as selectivity_percent
FROM master_table;
