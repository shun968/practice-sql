#!/bin/bash

# Migration Runner Script
# Usage: ./scripts/run_migration.sh [migration_file]

set -e

# 設定
COMPOSE_FILE="docker/mysql/compose.yaml"
DB_USER="practice_user"
DB_PASS="practice_password"
DB_NAME="practice_db"
MIGRATIONS_DIR="sql/migrations"

# 色付き出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# 特定のマイグレーションファイルを実行
run_single_migration() {
    local migration_file="$1"
    local start_time=$(date +%s)
    
    log_info "実行中: $migration_file"
    
    # マイグレーション実行
    if docker compose -f "$COMPOSE_FILE" exec -T mysql mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$migration_file"; then
        local end_time=$(date +%s)
        local execution_time=$((end_time - start_time))
        
        # 実行履歴を記録
        docker compose -f "$COMPOSE_FILE" exec -T mysql mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
        INSERT INTO migration_history (migration_name, execution_time_ms, status) 
        VALUES ('$(basename "$migration_file")', $execution_time, 'SUCCESS')
        ON DUPLICATE KEY UPDATE 
            executed_at = CURRENT_TIMESTAMP,
            execution_time_ms = $execution_time,
            status = 'SUCCESS',
            error_message = NULL;"
        
        log_info "完了: $migration_file (実行時間: ${execution_time}s)"
    else
        local end_time=$(date +%s)
        local execution_time=$((end_time - start_time))
        
        # エラー履歴を記録
        docker compose -f "$COMPOSE_FILE" exec -T mysql mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
        INSERT INTO migration_history (migration_name, execution_time_ms, status, error_message) 
        VALUES ('$(basename "$migration_file")', $execution_time, 'FAILED', 'Migration execution failed')
        ON DUPLICATE KEY UPDATE 
            executed_at = CURRENT_TIMESTAMP,
            execution_time_ms = $execution_time,
            status = 'FAILED',
            error_message = 'Migration execution failed';"
        
        log_error "失敗: $migration_file"
        exit 1
    fi
}

# 未実行のマイグレーションを全て実行
run_all_migrations() {
    log_info "未実行のマイグレーションを確認中..."
    
    # マイグレーションファイルを取得
    local migration_files=($(ls "$MIGRATIONS_DIR"/*.sql 2>/dev/null | sort))
    
    if [ ${#migration_files[@]} -eq 0 ]; then
        log_warn "マイグレーションファイルが見つかりません: $MIGRATIONS_DIR"
        return
    fi
    
    for migration_file in "${migration_files[@]}"; do
        local migration_name=$(basename "$migration_file")
        
        # 既に実行済みかチェック
        local executed=$(docker compose -f "$COMPOSE_FILE" exec -T mysql mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -s -e "
        SELECT COUNT(*) FROM migration_history WHERE migration_name = '$migration_name' AND status = 'SUCCESS';")
        
        if [ "$executed" -eq 0 ]; then
            run_single_migration "$migration_file"
        else
            log_info "スキップ: $migration_name (既に実行済み)"
        fi
    done
}

# メイン処理
main() {
    # MySQLコンテナが起動しているかチェック
    if ! docker compose -f "$COMPOSE_FILE" ps | grep -q "mysql-local.*Up"; then
        log_error "MySQLコンテナが起動していません。'make up' を実行してください。"
        exit 1
    fi
    
    if [ $# -eq 0 ]; then
        # 引数なし: 全ての未実行マイグレーションを実行
        run_all_migrations
    else
        # 引数あり: 指定されたマイグレーションファイルを実行
        local migration_file="$1"
        
        if [ ! -f "$migration_file" ]; then
            log_error "ファイルが見つかりません: $migration_file"
            exit 1
        fi
        
        run_single_migration "$migration_file"
    fi
    
    log_info "マイグレーション実行完了"
}

# スクリプト実行
main "$@"
