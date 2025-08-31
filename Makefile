# MySQL Docker Container Management
# 使用方法: make <target>

.PHONY: help build up down start stop restart status logs clean clean-all connect backup restore update

# Docker Composeファイルのパス
COMPOSE_FILE = docker/mysql/compose.yaml

# デフォルトターゲット
help:
	@echo "MySQL Docker Container Management"
	@echo ""
	@echo "利用可能なコマンド:"
	@echo "  build      - Dockerイメージをビルド"
	@echo "  up         - コンテナを起動（バックグラウンド）"
	@echo "  down       - コンテナを停止・削除"
	@echo "  start      - 既存のコンテナを起動"
	@echo "  stop       - コンテナを停止"
	@echo "  restart    - コンテナを再起動"
	@echo "  status     - コンテナの状態を表示"
	@echo "  logs       - コンテナのログを表示"
	@echo "  connect    - MySQLに接続"
	@echo "  backup     - データベースをバックアップ"
	@echo "  restore    - データベースを復元"
	@echo "  update     - イメージを最新版に更新"
	@echo "  clean      - コンテナとイメージを削除"
	@echo "  clean-all  - コンテナ、イメージ、ボリュームを全て削除"
	@echo ""
	@echo "SQLファイル管理:"
	@echo "  migrate         - 全てのマイグレーションを実行"
	@echo "  migrate-file    - 特定のマイグレーションファイルを実行"
	@echo "  seed            - シードデータを実行"
	@echo "  query           - クエリファイルを実行"
	@echo "  maintenance     - メンテナンススクリプトを実行"
	@echo "  migration-history - マイグレーション履歴を表示"

# イメージをビルド
build:
	@echo "MySQLイメージをビルド中..."
	docker compose -f $(COMPOSE_FILE) build

# コンテナを起動（バックグラウンド）
up:
	@echo "MySQLコンテナを起動中..."
	docker compose -f $(COMPOSE_FILE) up -d
	@echo "コンテナが起動しました。接続情報:"
	@echo "  Host: localhost"
	@echo "  Port: 3306"
	@echo "  Database: practice_db"
	@echo "  Username: practice_user"
	@echo "  Password: practice_password"
	@echo "  Root Password: rootpassword"

# コンテナを停止・削除
down:
	@echo "MySQLコンテナを停止・削除中..."
	docker compose -f $(COMPOSE_FILE) down

# 既存のコンテナを起動
start:
	@echo "MySQLコンテナを起動中..."
	docker compose -f $(COMPOSE_FILE) start

# コンテナを停止
stop:
	@echo "MySQLコンテナを停止中..."
	docker compose -f $(COMPOSE_FILE) stop

# コンテナを再起動
restart:
	@echo "MySQLコンテナを再起動中..."
	docker compose -f $(COMPOSE_FILE) restart

# コンテナの状態を表示
status:
	@echo "MySQLコンテナの状態:"
	docker compose -f $(COMPOSE_FILE) ps
	@echo ""
	@echo "Dockerイメージ:"
	docker images | grep mysql

# コンテナのログを表示
logs:
	@echo "MySQLコンテナのログ:"
	docker compose -f $(COMPOSE_FILE) logs -f mysql

# MySQLに接続
connect:
	@echo "MySQLに接続中..."
	docker compose -f $(COMPOSE_FILE) exec mysql mysql -u practice_user -ppractice_password practice_db

# rootユーザーでMySQLに接続
connect-root:
	@echo "MySQLにrootユーザーで接続中..."
	docker compose -f $(COMPOSE_FILE) exec mysql mysql -u root -prootpassword

# データベースをバックアップ
backup:
	@echo "データベースをバックアップ中..."
	@mkdir -p backups
	docker compose -f $(COMPOSE_FILE) exec mysql mysqldump -u practice_user -ppractice_password practice_db > backups/backup_$$(date +%Y%m%d_%H%M%S).sql
	@echo "バックアップが完了しました: backups/backup_$$(date +%Y%m%d_%H%M%S).sql"

# データベースを復元（引数: BACKUP_FILE=backups/backup_20231201_120000.sql）
restore:
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "使用方法: make restore BACKUP_FILE=backups/backup_20231201_120000.sql"; \
		exit 1; \
	fi
	@echo "データベースを復元中: $(BACKUP_FILE)"
	docker compose -f $(COMPOSE_FILE) exec -T mysql mysql -u practice_user -ppractice_password practice_db < $(BACKUP_FILE)
	@echo "復元が完了しました"

# イメージを最新版に更新
update:
	@echo "MySQLイメージを最新版に更新中..."
	docker compose -f $(COMPOSE_FILE) pull
	docker compose -f $(COMPOSE_FILE) down
	docker compose -f $(COMPOSE_FILE) up -d
	@echo "更新が完了しました"

# コンテナとイメージを削除
clean:
	@echo "コンテナとイメージを削除中..."
	docker compose -f $(COMPOSE_FILE) down --rmi all

# コンテナ、イメージ、ボリュームを全て削除
clean-all:
	@echo "コンテナ、イメージ、ボリュームを全て削除中..."
	docker compose -f $(COMPOSE_FILE) down --rmi all --volumes
	@echo "全てのデータが削除されました"

# ヘルスチェック
health:
	@echo "MySQLコンテナのヘルスチェック:"
	docker compose -f $(COMPOSE_FILE) exec mysql mysqladmin ping -h localhost -u practice_user -ppractice_password

# データベース情報を表示
info:
	@echo "MySQLデータベース情報:"
	@echo "  Host: localhost"
	@echo "  Port: 3306"
	@echo "  Database: practice_db"
	@echo "  Username: practice_user"
	@echo "  Password: practice_password"
	@echo "  Root Password: rootpassword"
	@echo ""
	@echo "接続例:"
	@echo "  mysql -h localhost -P 3306 -u practice_user -ppractice_password practice_db"
	@echo "  docker compose -f $(COMPOSE_FILE) exec mysql mysql -u practice_user -ppractice_password practice_db"

# SQLファイル管理コマンド
# マイグレーション実行
migrate:
	@echo "マイグレーション実行中..."
	./scripts/run_migration.sh

# パフォーマンステスト実行
performance-test:
	@echo "パフォーマンステスト実行中..."
	./scripts/run_performance_test.sh

# 特定のパフォーマンステスト実行
performance-test-type:
	@if [ -z "$(TYPE)" ]; then \
		echo "使用方法: make performance-test-type TYPE=data-volume"; \
		echo "利用可能なタイプ: data-volume, index, join, subquery, aggregation, sort, results, analyze"; \
		exit 1; \
	fi
	@echo "パフォーマンステスト実行中: $(TYPE)"
	./scripts/run_performance_test.sh $(TYPE)

# パフォーマンステスト結果レポート生成
performance-report:
	@echo "パフォーマンステスト結果レポート生成中..."
	./scripts/generate_performance_report.sh

# パフォーマンステスト実行 + レポート生成
performance-test-with-report: performance-test performance-report
	@echo "パフォーマンステストとレポート生成が完了しました"
	@echo "レポートファイル: reports/performance_report.html"

# 結合順序とインデックス設計の最適化テスト
join-optimization-test:
	@echo "結合順序とインデックス設計の最適化テスト実行中..."
	./scripts/run_join_optimization_test.sh

# 特定のマイグレーション実行
migrate-file:
	@if [ -z "$(FILE)" ]; then \
		echo "使用方法: make migrate-file FILE=sql/migrations/001_create_users_table.sql"; \
		exit 1; \
	fi
	@echo "マイグレーション実行中: $(FILE)"
	./scripts/run_migration.sh $(FILE)

# シードデータ実行
seed:
	@echo "シードデータ実行中..."
	@for file in sql/seeds/*.sql; do \
		if [ -f "$$file" ]; then \
			echo "実行中: $$file"; \
			docker compose -f $(COMPOSE_FILE) exec -T mysql mysql -u practice_user -ppractice_password practice_db < "$$file"; \
		fi; \
	done
	@echo "シードデータ実行完了"

# クエリ実行
query:
	@if [ -z "$(FILE)" ]; then \
		echo "使用方法: make query FILE=sql/queries/reports/user_statistics.sql"; \
		exit 1; \
	fi
	@echo "クエリ実行中: $(FILE)"
	./scripts/run_query.sh $(FILE)

# メンテナンス実行
maintenance:
	@echo "メンテナンス実行中..."
	@for file in sql/maintenance/*.sql; do \
		if [ -f "$$file" ]; then \
			echo "実行中: $$file"; \
			docker compose -f $(COMPOSE_FILE) exec -T mysql mysql -u practice_user -ppractice_password practice_db < "$$file"; \
		fi; \
	done
	@echo "メンテナンス実行完了"

# マイグレーション履歴表示
migration-history:
	@echo "マイグレーション実行履歴:"
	docker compose -f $(COMPOSE_FILE) exec mysql mysql -u practice_user -ppractice_password practice_db -e "SELECT migration_name, executed_at, execution_time_ms, status FROM migration_history ORDER BY executed_at DESC;"
