-- Maintenance: cleanup_old_data.sql
-- Description: 古いデータのクリーンアップ
-- Created: 2024-01-01
-- Author: System

USE practice_db;

-- 非アクティブユーザーの削除（1年以上更新がない場合）
DELETE FROM users 
WHERE is_active = FALSE 
AND updated_at < DATE_SUB(NOW(), INTERVAL 1 YEAR);

-- 古い注文の削除（2年以上前のキャンセル済み注文）
DELETE FROM orders 
WHERE status = 'cancelled' 
AND order_date < DATE_SUB(NOW(), INTERVAL 2 YEAR);

-- 古いマイグレーション履歴の削除（1年以上前）
DELETE FROM migration_history 
WHERE executed_at < DATE_SUB(NOW(), INTERVAL 1 YEAR);

-- テーブル最適化
OPTIMIZE TABLE users;
OPTIMIZE TABLE orders;
OPTIMIZE TABLE order_items;
OPTIMIZE TABLE migration_history;
