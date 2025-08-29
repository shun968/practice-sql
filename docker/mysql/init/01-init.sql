-- データベース初期化スクリプト
-- このファイルはコンテナ初回起動時に実行されます

-- データベースの作成（既にdocker-compose.ymlで作成済み）
-- CREATE DATABASE IF NOT EXISTS practice_db;

-- ユーザーの権限設定
GRANT ALL PRIVILEGES ON practice_db.* TO 'practice_user'@'%';
FLUSH PRIVILEGES;

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

-- サンプルデータの挿入
INSERT INTO users (username, email) VALUES
    ('test_user1', 'test1@example.com'),
    ('test_user2', 'test2@example.com'),
    ('test_user3', 'test3@example.com')
ON DUPLICATE KEY UPDATE
    email = VALUES(email);
