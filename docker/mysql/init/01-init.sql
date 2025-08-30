-- データベース初期化スクリプト
-- このファイルはコンテナ初回起動時に実行されます

-- データベースの作成（既にdocker-compose.ymlで作成済み）
-- CREATE DATABASE IF NOT EXISTS practice_db;

-- ユーザーの権限設定
GRANT ALL PRIVILEGES ON practice_db.* TO 'practice_user'@'%';
FLUSH PRIVILEGES;

-- サンプルテーブルの作成
USE practice_db;
