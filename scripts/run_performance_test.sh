#!/bin/bash

# Performance Test Runner Script
# Usage: ./scripts/run_performance_test.sh [test_type]

set -e

# 設定
COMPOSE_FILE="docker/mysql/compose.yaml"
DB_USER="practice_user"
DB_PASS="practice_password"
DB_NAME="practice_db"
TEST_QUERY_FILE="sql/queries/analysis/performance_comparison.sql"

# 色付き出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${BLUE}[HEADER]${NC} $1"
}

# パフォーマンステストの実行
run_performance_test() {
    local test_name="$1"
    local query="$2"
    local table_size="$3"
    local index_used="$4"
    local join_type="$5"
    
    log_info "実行中: $test_name"
    
    # 実行計画の取得と解析
    local result=$(docker compose -f "$COMPOSE_FILE" exec -T mysql mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -s -e "$query" 2>/dev/null)
    
    # 実行時間の測定
    local start_time=$(date +%s%N)
    docker compose -f "$COMPOSE_FILE" exec -T mysql mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -s -e "$query" > /dev/null 2>&1
    local end_time=$(date +%s%N)
    local execution_time=$(( (end_time - start_time) / 1000000 )) # ミリ秒
    
    # 実行計画からコストと行数を抽出
    local explain_result=$(docker compose -f "$COMPOSE_FILE" exec -T mysql mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -s -e "EXPLAIN FORMAT=JSON $query" 2>/dev/null)
    
    # 結果をデータベースに記録
    docker compose -f "$COMPOSE_FILE" exec -T mysql mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
    INSERT INTO performance_test_results 
    (test_name, table_size, index_used, join_type, estimated_cost, actual_time_ms, rows_processed, loops_count) 
    VALUES 
    ('$test_name', '$table_size', $index_used, '$join_type', 0, $execution_time, 0, 0)
    ON DUPLICATE KEY UPDATE 
        actual_time_ms = $execution_time,
        test_date = CURRENT_TIMESTAMP;"
    
    log_info "完了: $test_name (実行時間: ${execution_time}ms)"
}

# データ量テスト
run_data_volume_tests() {
    log_header "=== データ量による影響の比較テスト ==="
    
    # 小規模テーブル（100行）
    run_performance_test \
        "Small Table Query" \
        "SELECT category, COUNT(*), AVG(value) FROM small_table WHERE category = 'Category_A' GROUP BY category;" \
        "small" \
        "true" \
        "none"
    
    # 中規模テーブル（10,000行）
    run_performance_test \
        "Medium Table Query" \
        "SELECT category, COUNT(*), AVG(value) FROM medium_table WHERE category = 'Category_A' GROUP BY category;" \
        "medium" \
        "true" \
        "none"
    
    # 大規模テーブル（100,000行）
    run_performance_test \
        "Large Table Query" \
        "SELECT category, COUNT(*), AVG(value) FROM large_table WHERE category = 'Category_A' GROUP BY category;" \
        "large" \
        "true" \
        "none"
}

# インデックステスト
run_index_tests() {
    log_header "=== インデックス有無による影響の比較テスト ==="
    
    # インデックスあり（category）
    run_performance_test \
        "Indexed Query" \
        "SELECT * FROM medium_table WHERE category = 'Category_B' AND value > 500;" \
        "medium" \
        "true" \
        "none"
    
    # インデックスなし（valueのみ）
    run_performance_test \
        "Non-Indexed Query" \
        "SELECT * FROM medium_table WHERE value > 500;" \
        "medium" \
        "false" \
        "none"
    
    # 複合インデックスあり
    run_performance_test \
        "Composite Index Query" \
        "SELECT * FROM medium_table WHERE category = 'Category_C' AND value BETWEEN 100 AND 200;" \
        "medium" \
        "true" \
        "none"
}

# テーブル結合テスト
run_join_tests() {
    log_header "=== テーブル結合の影響比較テスト ==="
    
    # 小規模結合
    run_performance_test \
        "Small Join Query" \
        "SELECT m.name as master_name, d.item_name, d.quantity, d.total_price FROM master_table m JOIN detail_table d ON m.id = d.master_id WHERE m.status = 'active' ORDER BY d.total_price DESC;" \
        "small" \
        "true" \
        "inner"
    
    # 中規模結合
    run_performance_test \
        "Medium Join Query" \
        "SELECT m.name as master_name, med.category, COUNT(*) as item_count, AVG(med.value) as avg_value FROM master_table m JOIN medium_table med ON m.id = (med.id % 10) + 1 WHERE m.status = 'active' GROUP BY m.name, med.category HAVING item_count > 100;" \
        "medium" \
        "true" \
        "inner"
    
    # 3テーブル結合
    run_performance_test \
        "Complex Join Query" \
        "SELECT m.name as master_name, med.category, d.item_name, COUNT(*) as detail_count FROM master_table m JOIN medium_table med ON m.id = (med.id % 10) + 1 JOIN detail_table d ON m.id = d.master_id WHERE m.status = 'active' AND med.value > 500 GROUP BY m.name, med.category, d.item_name HAVING detail_count > 1 ORDER BY detail_count DESC;" \
        "medium" \
        "true" \
        "multiple"
}

# サブクエリ vs JOIN テスト
run_subquery_vs_join_tests() {
    log_header "=== サブクエリ vs JOIN の比較テスト ==="
    
    # サブクエリ版
    run_performance_test \
        "Subquery Query" \
        "SELECT m.name, (SELECT COUNT(*) FROM detail_table d WHERE d.master_id = m.id) as detail_count, (SELECT AVG(d.total_price) FROM detail_table d WHERE d.master_id = m.id) as avg_price FROM master_table m WHERE m.status = 'active';" \
        "small" \
        "true" \
        "subquery"
    
    # JOIN版
    run_performance_test \
        "JOIN Query" \
        "SELECT m.name, COUNT(d.id) as detail_count, AVG(d.total_price) as avg_price FROM master_table m LEFT JOIN detail_table d ON m.id = d.master_id WHERE m.status = 'active' GROUP BY m.id, m.name;" \
        "small" \
        "true" \
        "left_join"
}

# 集計クエリテスト
run_aggregation_tests() {
    log_header "=== 集計クエリの比較テスト ==="
    
    # 単純集計
    run_performance_test \
        "Simple Aggregation" \
        "SELECT category, COUNT(*) as count, AVG(value) as avg_value, MIN(value) as min_value, MAX(value) as max_value FROM medium_table GROUP BY category;" \
        "medium" \
        "true" \
        "none"
    
    # 条件付き集計
    run_performance_test \
        "Conditional Aggregation" \
        "SELECT category, COUNT(*) as count, AVG(value) as avg_value FROM medium_table WHERE value > 500 GROUP BY category;" \
        "medium" \
        "true" \
        "none"
}

# ソート処理テスト
run_sort_tests() {
    log_header "=== ソート処理の比較テスト ==="
    
    # インデックスありでのソート
    run_performance_test \
        "Indexed Sort" \
        "SELECT * FROM medium_table WHERE category = 'Category_A' ORDER BY created_at DESC LIMIT 100;" \
        "medium" \
        "true" \
        "none"
    
    # インデックスなしでのソート
    run_performance_test \
        "Non-Indexed Sort" \
        "SELECT * FROM medium_table WHERE value > 500 ORDER BY value DESC LIMIT 100;" \
        "medium" \
        "false" \
        "none"
}

# 全テストの実行
run_all_tests() {
    log_header "パフォーマンステストを開始します"
    
    # データ量テスト
    run_data_volume_tests
    
    # インデックステスト
    run_index_tests
    
    # テーブル結合テスト
    run_join_tests
    
    # サブクエリ vs JOIN テスト
    run_subquery_vs_join_tests
    
    # 集計クエリテスト
    run_aggregation_tests
    
    # ソート処理テスト
    run_sort_tests
    
    log_header "全テストが完了しました"
}

# 結果の表示
show_results() {
    log_header "=== パフォーマンステスト結果 ==="
    
    docker compose -f "$COMPOSE_FILE" exec -T mysql mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
    SELECT 
        test_name,
        table_size,
        index_used,
        join_type,
        estimated_cost,
        actual_time_ms,
        rows_processed,
        loops_count,
        test_date
    FROM performance_test_results 
    ORDER BY test_date DESC, table_size, test_name;"
}

# 結果の分析
analyze_results() {
    log_header "=== パフォーマンステスト結果の分析 ==="
    
    # データ量による影響
    log_info "データ量による影響:"
    docker compose -f "$COMPOSE_FILE" exec -T mysql mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
    SELECT 
        table_size,
        AVG(actual_time_ms) as avg_time_ms,
        MIN(actual_time_ms) as min_time_ms,
        MAX(actual_time_ms) as max_time_ms
    FROM performance_test_results 
    WHERE join_type = 'none' AND index_used = true
    GROUP BY table_size
    ORDER BY 
        CASE table_size 
            WHEN 'small' THEN 1 
            WHEN 'medium' THEN 2 
            WHEN 'large' THEN 3 
        END;"
    
    # インデックスによる影響
    log_info "インデックスによる影響:"
    docker compose -f "$COMPOSE_FILE" exec -T mysql mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
    SELECT 
        index_used,
        AVG(actual_time_ms) as avg_time_ms,
        COUNT(*) as test_count
    FROM performance_test_results 
    WHERE table_size = 'medium' AND join_type = 'none'
    GROUP BY index_used;"
    
    # 結合タイプによる影響
    log_info "結合タイプによる影響:"
    docker compose -f "$COMPOSE_FILE" exec -T mysql mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
    SELECT 
        join_type,
        AVG(actual_time_ms) as avg_time_ms,
        COUNT(*) as test_count
    FROM performance_test_results 
    WHERE join_type != 'none'
    GROUP BY join_type
    ORDER BY avg_time_ms;"
}

# メイン処理
main() {
    case "${1:-all}" in
        "data-volume")
            run_data_volume_tests
            ;;
        "index")
            run_index_tests
            ;;
        "join")
            run_join_tests
            ;;
        "subquery")
            run_subquery_vs_join_tests
            ;;
        "aggregation")
            run_aggregation_tests
            ;;
        "sort")
            run_sort_tests
            ;;
        "results")
            show_results
            ;;
        "analyze")
            analyze_results
            ;;
        "all"|*)
            run_all_tests
            show_results
            analyze_results
            ;;
    esac
}

# スクリプトの実行
main "$@"
