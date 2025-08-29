#!/bin/bash

# MySQL Docker Container Management Script
# 使用方法: ./mysql-docker.sh <command>

set -e

# Docker Composeファイルのパス
COMPOSE_FILE="docker/mysql/docker-compose.yml"

# 色付きの出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ヘルプ表示
show_help() {
    echo "MySQL Docker Container Management Script"
    echo ""
    echo "使用方法: $0 <command>"
    echo ""
    echo "利用可能なコマンド:"
    echo "  build      - Dockerイメージをビルド"
    echo "  up         - コンテナを起動（バックグラウンド）"
    echo "  down       - コンテナを停止・削除"
    echo "  start      - 既存のコンテナを起動"
    echo "  stop       - コンテナを停止"
    echo "  restart    - コンテナを再起動"
    echo "  status     - コンテナの状態を表示"
    echo "  logs       - コンテナのログを表示"
    echo "  connect    - MySQLに接続"
    echo "  connect-root - rootユーザーでMySQLに接続"
    echo "  backup     - データベースをバックアップ"
    echo "  restore    - データベースを復元"
    echo "  update     - イメージを最新版に更新"
    echo "  clean      - コンテナとイメージを削除"
    echo "  clean-all  - コンテナ、イメージ、ボリュームを全て削除"
    echo "  health     - ヘルスチェック"
    echo "  info       - データベース情報を表示"
    echo "  help       - このヘルプを表示"
}

# コンテナの状態チェック
check_container_status() {
    if docker compose -f "$COMPOSE_FILE" ps | grep -q "mysql-local.*Up"; then
        return 0
    else
        return 1
    fi
}

# イメージをビルド
build() {
    log_info "MySQLイメージをビルド中..."
    docker compose -f "$COMPOSE_FILE" build
    log_success "ビルドが完了しました"
}

# コンテナを起動
up() {
    log_info "MySQLコンテナを起動中..."
    docker compose -f "$COMPOSE_FILE" up -d
    
    # 起動待機
    log_info "コンテナの起動を待機中..."
    sleep 10
    
    if check_container_status; then
        log_success "コンテナが起動しました"
        show_connection_info
    else
        log_error "コンテナの起動に失敗しました"
        docker compose -f "$COMPOSE_FILE" logs mysql
        exit 1
    fi
}

# コンテナを停止・削除
down() {
    log_info "MySQLコンテナを停止・削除中..."
    docker compose -f "$COMPOSE_FILE" down
    log_success "コンテナが停止・削除されました"
}

# 既存のコンテナを起動
start() {
    log_info "MySQLコンテナを起動中..."
    docker compose -f "$COMPOSE_FILE" start
    log_success "コンテナが起動しました"
}

# コンテナを停止
stop() {
    log_info "MySQLコンテナを停止中..."
    docker compose -f "$COMPOSE_FILE" stop
    log_success "コンテナが停止しました"
}

# コンテナを再起動
restart() {
    log_info "MySQLコンテナを再起動中..."
    docker compose -f "$COMPOSE_FILE" restart
    log_success "コンテナが再起動しました"
}

# コンテナの状態を表示
status() {
    log_info "MySQLコンテナの状態:"
    docker compose -f "$COMPOSE_FILE" ps
    echo ""
    log_info "Dockerイメージ:"
    docker images | grep mysql || echo "MySQLイメージが見つかりません"
}

# コンテナのログを表示
logs() {
    log_info "MySQLコンテナのログ:"
    docker compose -f "$COMPOSE_FILE" logs -f mysql
}

# MySQLに接続
connect() {
    if ! check_container_status; then
        log_error "コンテナが起動していません。先に 'up' コマンドを実行してください"
        exit 1
    fi
    
    log_info "MySQLに接続中..."
    docker compose -f "$COMPOSE_FILE" exec mysql mysql -u practice_user -ppractice_password practice_db
}

# rootユーザーでMySQLに接続
connect_root() {
    if ! check_container_status; then
        log_error "コンテナが起動していません。先に 'up' コマンドを実行してください"
        exit 1
    fi
    
    log_info "MySQLにrootユーザーで接続中..."
    docker compose -f "$COMPOSE_FILE" exec mysql mysql -u root -prootpassword
}

# データベースをバックアップ
backup() {
    if ! check_container_status; then
        log_error "コンテナが起動していません。先に 'up' コマンドを実行してください"
        exit 1
    fi
    
    local backup_dir="backups"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${backup_dir}/backup_${timestamp}.sql"
    
    log_info "データベースをバックアップ中..."
    mkdir -p "$backup_dir"
    docker compose -f "$COMPOSE_FILE" exec mysql mysqldump -u practice_user -ppractice_password practice_db > "$backup_file"
    log_success "バックアップが完了しました: $backup_file"
}

# データベースを復元
restore() {
    if ! check_container_status; then
        log_error "コンテナが起動していません。先に 'up' コマンドを実行してください"
        exit 1
    fi
    
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        log_error "使用方法: $0 restore <backup_file>"
        echo "例: $0 restore backups/backup_20231201_120000.sql"
        exit 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        log_error "バックアップファイルが見つかりません: $backup_file"
        exit 1
    fi
    
    log_info "データベースを復元中: $backup_file"
    docker compose -f "$COMPOSE_FILE" exec -T mysql mysql -u practice_user -ppractice_password practice_db < "$backup_file"
    log_success "復元が完了しました"
}

# イメージを最新版に更新
update() {
    log_info "MySQLイメージを最新版に更新中..."
    docker compose -f "$COMPOSE_FILE" pull
    docker compose -f "$COMPOSE_FILE" down
    docker compose -f "$COMPOSE_FILE" up -d
    log_success "更新が完了しました"
}

# コンテナとイメージを削除
clean() {
    log_warning "コンテナとイメージを削除しますか？ (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_info "コンテナとイメージを削除中..."
        docker compose -f "$COMPOSE_FILE" down --rmi all
        log_success "削除が完了しました"
    else
        log_info "削除をキャンセルしました"
    fi
}

# コンテナ、イメージ、ボリュームを全て削除
clean_all() {
    log_warning "コンテナ、イメージ、ボリュームを全て削除しますか？ (y/N)"
    log_warning "この操作により全てのデータが失われます！"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_info "コンテナ、イメージ、ボリュームを全て削除中..."
        docker compose -f "$COMPOSE_FILE" down --rmi all --volumes
        log_success "全てのデータが削除されました"
    else
        log_info "削除をキャンセルしました"
    fi
}

# ヘルスチェック
health() {
    if ! check_container_status; then
        log_error "コンテナが起動していません"
        exit 1
    fi
    
    log_info "MySQLコンテナのヘルスチェック:"
    if docker compose -f "$COMPOSE_FILE" exec mysql mysqladmin ping -h localhost -u practice_user -ppractice_password > /dev/null 2>&1; then
        log_success "MySQLは正常に動作しています"
    else
        log_error "MySQLのヘルスチェックに失敗しました"
        exit 1
    fi
}

# 接続情報を表示
show_connection_info() {
    echo ""
    log_info "接続情報:"
    echo "  Host: localhost"
    echo "  Port: 3306"
    echo "  Database: practice_db"
    echo "  Username: practice_user"
    echo "  Password: practice_password"
    echo "  Root Password: rootpassword"
    echo ""
    log_info "接続例:"
    echo "  mysql -h localhost -P 3306 -u practice_user -ppractice_password practice_db"
    echo "  docker compose -f $COMPOSE_FILE exec mysql mysql -u practice_user -ppractice_password practice_db"
}

# データベース情報を表示
info() {
    show_connection_info
}

# メイン処理
main() {
    local command="$1"
    
    case "$command" in
        build)
            build
            ;;
        up)
            up
            ;;
        down)
            down
            ;;
        start)
            start
            ;;
        stop)
            stop
            ;;
        restart)
            restart
            ;;
        status)
            status
            ;;
        logs)
            logs
            ;;
        connect)
            connect
            ;;
        connect-root)
            connect_root
            ;;
        backup)
            backup
            ;;
        restore)
            restore "$2"
            ;;
        update)
            update
            ;;
        clean)
            clean
            ;;
        clean-all)
            clean_all
            ;;
        health)
            health
            ;;
        info)
            info
            ;;
        help|--help|-h)
            show_help
            ;;
        "")
            show_help
            ;;
        *)
            log_error "不明なコマンド: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# スクリプト実行
main "$@"
