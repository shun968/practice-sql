#!/bin/bash

# 結合順序とインデックス設計の最適化テスト実行スクリプト
# 結合順序の最適化とインデックス設計の効果を検証

set -e

# 設定
DB_HOST="localhost"
DB_PORT="3306"
DB_USER="root"
DB_PASSWORD="password"
DB_NAME="practice_sql"

# 色付きログ出力
log_info() {
    echo -e "\033[32m[INFO]\033[0m $1"
}

log_warn() {
    echo -e "\033[33m[WARN]\033[0m $1"
}

log_error() {
    echo -e "\033[31m[ERROR]\033[0m $1"
}

log_header() {
    echo -e "\033[36m[HEADER]\033[0m $1"
}

# データベース接続確認
check_connection() {
    log_info "データベース接続を確認中..."
    mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SELECT 1;" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        log_info "データベース接続成功"
    else
        log_error "データベース接続失敗"
        exit 1
    fi
}

# テストテーブルの存在確認
check_tables() {
    log_info "テストテーブルの存在を確認中..."
    local tables=("master_table" "detail_table" "medium_table" "small_table" "large_table")
    
    for table in "${tables[@]}"; do
        local count=$(mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SELECT COUNT(*) FROM $table;" -s -N 2>/dev/null || echo "0")
        if [ "$count" -gt 0 ]; then
            log_info "$table: $count 行"
        else
            log_warn "$table: データなし"
        fi
    done
}

# インデックスの確認
check_indexes() {
    log_info "インデックスの確認中..."
    
    echo "=== master_table のインデックス ==="
    mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "
    SHOW INDEX FROM master_table;
    " 2>/dev/null || echo "インデックス情報の取得に失敗"
    
    echo "=== detail_table のインデックス ==="
    mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "
    SHOW INDEX FROM detail_table;
    " 2>/dev/null || echo "インデックス情報の取得に失敗"
    
    echo "=== medium_table のインデックス ==="
    mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "
    SHOW INDEX FROM medium_table;
    " 2>/dev/null || echo "インデックス情報の取得に失敗"
}

# 結合順序のテスト実行
run_join_order_tests() {
    log_header "結合順序の最適化テストを実行中..."
    
    local test_file="sql/queries/analysis/join_order_and_index_optimization.sql"
    
    if [ ! -f "$test_file" ]; then
        log_error "テストファイルが見つかりません: $test_file"
        return 1
    fi
    
    log_info "テストファイルを実行中: $test_file"
    
    # テスト実行（結果をファイルに保存）
    local output_file="reports/join_optimization_results.txt"
    mkdir -p reports
    
    mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$test_file" > "$output_file" 2>&1
    
    if [ $? -eq 0 ]; then
        log_info "テスト実行完了: $output_file"
    else
        log_error "テスト実行に失敗しました"
        return 1
    fi
}

# 結果の分析
analyze_results() {
    log_header "結果の分析中..."
    
    local output_file="reports/join_optimization_results.txt"
    
    if [ ! -f "$output_file" ]; then
        log_error "結果ファイルが見つかりません: $output_file"
        return 1
    fi
    
    echo "=== 結合順序テスト結果の要約 ==="
    echo
    
    # 実行時間の抽出と比較
    echo "実行時間の比較:"
    grep -A 5 -B 5 "actual time" "$output_file" | head -20
    
    echo
    echo "=== インデックス使用状況 ==="
    grep -A 3 -B 3 "Using index" "$output_file" | head -10
    
    echo
    echo "=== テーブルスキャン状況 ==="
    grep -A 3 -B 3 "Full table scan" "$output_file" | head -10
}

# 最適化の推奨事項
show_recommendations() {
    log_header "最適化の推奨事項"
    
    echo "=== 結合順序の最適化 ==="
    echo "1. 小さいテーブルから大きいテーブルへ結合"
    echo "   - ループ回数を最小化"
    echo "   - 駆動テーブルを適切に選択"
    echo
    echo "2. WHERE句で絞り込めるテーブルを先に結合"
    echo "   - 早期フィルタリングで処理対象行数を削減"
    echo "   - インデックスを活用した条件指定"
    echo
    echo "3. インデックスが効くテーブルを先に結合"
    echo "   - インデックススキャンで高速処理"
    echo "   - 主キー・外部キーの活用"
    echo
    echo "=== インデックス設計の最適化 ==="
    echo "1. 結合条件のインデックス"
    echo "   - JOIN句で使用されるカラムにインデックス"
    echo "   - 外部キー制約の活用"
    echo
    echo "2. WHERE句のインデックス"
    echo "   - フィルタリング条件にインデックス"
    echo "   - 複合条件はカーディナリティの高い順"
    echo
    echo "3. 複合インデックスの順序"
    echo "   - 等価比較 → 範囲比較 → ORDER BY → GROUP BY"
    echo "   - カーディナリティの高い順に配置"
    echo
    echo "4. カバリングインデックス"
    echo "   - SELECT句のカラムも含めたインデックス"
    echo "   - テーブルアクセスを回避"
}

# メイン処理
main() {
    log_header "結合順序とインデックス設計の最適化テストを開始"
    
    # データベース接続確認
    check_connection
    
    # テストテーブルの存在確認
    check_tables
    
    # インデックスの確認
    check_indexes
    
    # 結合順序のテスト実行
    run_join_order_tests
    
    # 結果の分析
    analyze_results
    
    # 最適化の推奨事項
    show_recommendations
    
    log_header "テスト完了"
    log_info "詳細な結果は reports/join_optimization_results.txt を確認してください"
}

# スクリプト実行
main "$@"
