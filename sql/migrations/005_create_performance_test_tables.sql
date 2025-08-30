-- パフォーマンステスト用テーブルの作成
-- データ量・インデックス・テーブル結合の影響を検証

-- 小規模テーブル（100行）
CREATE TABLE IF NOT EXISTS small_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    value DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_category (category),
    INDEX idx_created_at (created_at)
);

-- 中規模テーブル（10,000行）
CREATE TABLE IF NOT EXISTS medium_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    value DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_category (category),
    INDEX idx_created_at (created_at),
    INDEX idx_category_value (category, value)
);

-- 大規模テーブル（100,000行）
CREATE TABLE IF NOT EXISTS large_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    value DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_category (category),
    INDEX idx_created_at (created_at),
    INDEX idx_category_value (category, value),
    INDEX idx_value (value)
);

-- 結合用のマスターテーブル
CREATE TABLE IF NOT EXISTS master_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    status ENUM('active', 'inactive', 'pending') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_code (code),
    INDEX idx_status (status),
    INDEX idx_status_created (status, created_at)
);

-- 結合用の詳細テーブル
CREATE TABLE IF NOT EXISTS detail_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    master_id INT NOT NULL,
    item_name VARCHAR(100) NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (master_id) REFERENCES master_table(id),
    INDEX idx_master_id (master_id),
    INDEX idx_created_at (created_at),
    INDEX idx_master_created (master_id, created_at)
);

-- パフォーマンステスト結果を記録するテーブル
CREATE TABLE IF NOT EXISTS performance_test_results (
    id INT AUTO_INCREMENT PRIMARY KEY,
    test_name VARCHAR(100) NOT NULL,
    table_size VARCHAR(20) NOT NULL,
    index_used BOOLEAN NOT NULL,
    join_type VARCHAR(50),
    estimated_cost DECIMAL(10,4),
    actual_time_ms DECIMAL(10,4),
    rows_processed INT,
    loops_count INT,
    test_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_test_name (test_name),
    INDEX idx_table_size (table_size),
    INDEX idx_test_date (test_date)
);
