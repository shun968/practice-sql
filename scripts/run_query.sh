#!/bin/bash

# Query Runner Script
# Usage: ./scripts/run_query.sh <query_file> [output_format]

set -e

# 設定
COMPOSE_FILE="docker/mysql/compose.yaml"
DB_USER="practice_user"
DB_PASS="practice_password"
DB_NAME="practice_db"

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

log_query() {
    echo -e "${BLUE}[QUERY]${NC} $1"
}

# ヘルプ表示
show_help() {
    echo "Usage: $0 <query_file> [output_format]"
    echo ""
    echo "Arguments:"
    echo "  query_file     SQLクエリファイルのパス"
    echo "  output_format  出力形式 (table|csv|json|vertical) [default: table]"
    echo ""
    echo "Examples:"
    echo "  $0 sql/queries/reports/user_statistics.sql"
    echo "  $0 sql/queries/reports/user_statistics.sql csv"
    echo "  $0 sql/queries/analysis/performance_queries.sql json"
}

# メイン処理
main() {
    # 引数チェック
    if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_help
        exit 0
    fi
    
    local query_file="$1"
    local output_format="${2:-table}"
    
    # ファイル存在チェック
    if [ ! -f "$query_file" ]; then
        log_error "クエリファイルが見つかりません: $query_file"
        exit 1
    fi
    
    # MySQLコンテナが起動しているかチェック
    if ! docker compose -f "$COMPOSE_FILE" ps | grep -q "mysql-local.*Up"; then
        log_error "MySQLコンテナが起動していません。'make up' を実行してください。"
        exit 1
    fi
    
    log_info "クエリ実行中: $query_file"
    log_info "出力形式: $output_format"
    
    # クエリファイルの内容を表示
    log_query "実行するクエリ:"
    echo "----------------------------------------"
    cat "$query_file"
    echo "----------------------------------------"
    
    # 出力形式に応じたオプションを設定
    local mysql_options=""
    case "$output_format" in
        "table")
            mysql_options=""
            ;;
        "csv")
            mysql_options="--batch --raw --skip-column-names"
            ;;
        "json")
            mysql_options="--json"
            ;;
        "vertical")
            mysql_options="--vertical"
            ;;
        *)
            log_warn "不明な出力形式: $output_format (table形式で実行します)"
            mysql_options=""
            ;;
    esac
    
    # クエリ実行
    local start_time=$(date +%s)
    
    if docker compose -f "$COMPOSE_FILE" exec -T mysql mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" $mysql_options < "$query_file"; then
        local end_time=$(date +%s)
        local execution_time=$((end_time - start_time))
        log_info "クエリ実行完了 (実行時間: ${execution_time}s)"
    else
        log_error "クエリ実行に失敗しました"
        exit 1
    fi
}

# スクリプト実行
main "$@"
