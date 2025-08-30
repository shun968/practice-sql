# Practice SQL

MySQLを使用したSQL学習・練習環境です。Dockerを使用して簡単にセットアップできます。

## 特徴

- 🐳 Docker Composeによる簡単セットアップ
- 📊 実行計画の確認機能
- 🔄 カスタムマイグレーション管理システム
- 📈 レポート・分析クエリ管理
- 🛠️ メンテナンススクリプト管理
- 📝 シードデータ管理
- 📚 詳細なドキュメント

## ディレクトリ構成

```
practice-sql/
├── docker/
│   └── mysql/
│       ├── compose.yaml          # Docker Compose設定
│       ├── config/
│       │   └── mysql.cnf         # MySQL設定
│       └── init/                 # DB初期化時のみ実行
│           ├── 01-init.sql
│           └── 02-init.sql
├── sql/                         # 任意タイミングで実行するSQL
│   ├── migrations/              # データベースマイグレーション
│   │   ├── 001_create_users_table.sql
│   │   ├── 002_create_orders_table.sql
│   │   ├── 003_create_warehouse_table.sql
│   │   ├── 004_create_analysis_tables.sql
│   │   └── 005_create_performance_test_tables.sql
│   ├── seeds/                   # テストデータ・初期データ
│   │   ├── 001_sample_users.sql
│   │   ├── 002_sample_warehouse.sql
│   │   ├── 004_sample_analysis_data.sql
│   │   └── 005_sample_performance_test_data.sql
│   ├── queries/                 # 分析・レポート用クエリ
│   │   ├── reports/
│   │   │   └── user_statistics.sql
│   │   └── analysis/
│   │       ├── warehouse_city_mapping.sql
│   │       ├── correlated_subquery_vs_window.sql
│   │       └── performance_comparison.sql
│   └── maintenance/             # メンテナンス用スクリプト
│       └── cleanup_old_data.sql
├── scripts/                     # SQL実行用スクリプト
│   ├── run_migration.sh
│   ├── run_query.sh
│   ├── run_performance_test.sh
│   └── generate_performance_report.sh
├── docs/                        # ドキュメント
│   ├── migration.md
│   ├── analyze-mysql.md
│   └── github-directory.md
├── reports/                     # パフォーマンステストレポート
└── Makefile                     # 管理コマンド
```

## セットアップ

### 1. リポジトリのクローン

```bash
git clone <repository-url>
cd practice-sql
```

### 2. MySQLコンテナの起動

```bash
make up
```

### 3. マイグレーションの実行

```bash
make migrate
```

### 4. シードデータの実行

```bash
make seed
```

### 5. ドキュメントの確認

```bash
# マイグレーション管理について
cat docs/migration.md

# MySQL実行計画分析について
cat docs/analyze-mysql.md

# GitHubディレクトリの設定について
cat docs/github-directory.md

# Gitワークフロールールについて
cat .cursor/rules/git-workflow.mdc
```

## 使用方法

### 基本的なコマンド

```bash
# コンテナの起動
make up

# コンテナの停止
make down

# MySQLに接続
make connect

# コンテナの状態確認
make status
```

### SQLファイル管理

#### マイグレーション

```bash
# 全ての未実行マイグレーションを実行
make migrate

# 特定のマイグレーションファイルを実行
make migrate-file FILE=sql/migrations/001_create_users_table.sql

# マイグレーション履歴を表示
make migration-history
```

詳細については `docs/migration.md` を参照してください。

#### シードデータ

```bash
# シードデータを実行
make seed
```

#### クエリ実行

```bash
# クエリファイルを実行
make query FILE=sql/queries/reports/user_statistics.sql

# 直接スクリプトを使用（出力形式指定可能）
./scripts/run_query.sh sql/queries/reports/user_statistics.sql csv
./scripts/run_query.sh sql/queries/reports/user_statistics.sql json
```

#### メンテナンス

```bash
# メンテナンススクリプトを実行
make maintenance

# パフォーマンステストを実行
make performance-test

# 特定のパフォーマンステストを実行
make performance-test-type TYPE=data-volume

# パフォーマンステスト結果レポート生成
make performance-report

# パフォーマンステスト実行 + レポート生成
make performance-test-with-report
```

**利用可能なテストタイプ**:
- **data-volume**: データ量による影響の比較（小規模・中規模・大規模テーブル）
- **index**: インデックス有無による影響の比較
- **join**: テーブル結合の影響比較
- **subquery**: サブクエリ vs JOIN の比較
- **aggregation**: 集計クエリの比較
- **sort**: ソート処理の比較
- **results**: テスト結果の表示
- **analyze**: 結果の統計分析

**レポート生成**:
- **performance-report**: HTML形式のグラフ付きレポートを生成
- **performance-test-with-report**: テスト実行とレポート生成を一括実行
```

### 実行計画の確認

MySQLに接続して実行計画を確認できます：

```sql
-- 基本的な実行計画
EXPLAIN SELECT * FROM users WHERE email = 'test@example.com';

-- JSON形式での詳細な実行計画
EXPLAIN FORMAT=JSON SELECT * FROM users WHERE email = 'test@example.com';

-- 実際にクエリを実行して実行時間も表示
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'test@example.com';
```

詳細については `docs/analyze-mysql.md` を参照してください。

## GitHub設定

このプロジェクトでは、GitHubの機能を活用して品質向上と効率化を図っています：

- **GitHub Actions**: CI/CDパイプラインの自動実行
- **Dependabot**: 依存関係の自動更新
- **Issue/PRテンプレート**: 標準化された報告・提案フォーマット

詳細については `docs/github-directory.md` を参照してください。

## Gitワークフロー

このプロジェクトでは、標準化されたGitワークフローを採用しています：

- **Feature Branch Workflow**: 機能開発は専用ブランチで実施
- **Conventional Commits**: 統一されたコミットメッセージ形式
- **プルリクエスト必須**: コードレビューによる品質確保
- **ブランチ保護**: mainブランチへの直接プッシュ禁止

詳細については `.cursor/rules/git-workflow.mdc` を参照してください。

## データベース情報

- **Host**: localhost
- **Port**: 3306
- **Database**: practice_db
- **Username**: practice_user
- **Password**: practice_password
- **Root Password**: rootpassword

## ファイル管理のベストプラクティス

### マイグレーションファイル

- ファイル名は `001_`, `002_` のように連番で管理
- 各ファイルには適切なコメントを記載
- 実行履歴は `migration_history` テーブルで管理
- 詳細については `docs/migration.md` を参照

### クエリファイル

- 用途別にディレクトリを分ける（reports, analysis等）
- ファイル名は内容を表す名前にする
- 複雑なクエリにはコメントを記載

### シードファイル

- テストデータや初期データを管理
- `ON DUPLICATE KEY UPDATE` を使用して冪等性を保つ

### メンテナンスファイル

- 定期的に実行するクリーンアップや最適化スクリプト
- 実行前にバックアップを取ることを推奨

## トラブルシューティング

### Docker Desktopのエラー

Docker Desktopでスナップショットエラーが発生した場合：

```bash
# Dockerシステムのクリーンアップ
docker system prune -a --volumes -f

# Docker Desktopを再起動
# その後、make up を実行
```

### マイグレーションエラー

```bash
# マイグレーション履歴を確認
make migration-history

# 特定のマイグレーションを再実行
make migrate-file FILE=sql/migrations/001_create_users_table.sql
```

## 開発者向け情報

### 新しいマイグレーションの追加

1. `sql/migrations/` ディレクトリに新しいファイルを作成
2. ファイル名は連番で管理（例: `003_add_new_table.sql`）
3. 適切なコメントを記載
4. `make migrate` で実行

### 新しいクエリの追加

1. 用途に応じたディレクトリにファイルを作成
2. ファイル名は内容を表す名前にする
3. `make query FILE=path/to/query.sql` で実行

## ライセンス

MIT License

