# マイグレーション管理システム

## 概要

このプロジェクトでは、カスタム実装のマイグレーション管理システムを使用しています。シンプルで軽量、かつ信頼性の高いマイグレーション管理を提供します。

## 基本概念

### マイグレーションとは
データベースのスキーマ変更を管理する仕組みです。各マイグレーションファイルは一度だけ実行され、実行履歴が`migration_history`テーブルに記録されます。

### ファイル命名規則
```
sql/migrations/
├── 001_create_users_table.sql
├── 002_create_orders_table.sql
├── 003_create_warehouse_table.sql
└── 004_create_analysis_tables.sql
```

- ファイル名は `001_`, `002_` のように連番で管理
- 各ファイルには適切なコメントを記載
- 実行履歴は `migration_history` テーブルで管理

## 実行済み制御の仕組み

### 制御の流れ

#### 1. マイグレーションファイルの取得
```bash
# マイグレーションファイルを辞書順でソートして取得
local migration_files=($(ls "$MIGRATIONS_DIR"/*.sql 2>/dev/null | sort))
```

- `sql/migrations/`ディレクトリ内の`.sql`ファイルを取得
- `sort`コマンドで辞書順にソート
- 連番のマイグレーションが正しい順序で実行される

#### 2. 実行済みチェック
各マイグレーションファイルに対して、以下のSQLクエリで実行済みかチェックします：

```sql
SELECT COUNT(*) FROM migration_history 
WHERE migration_name = '$migration_name' 
AND status = 'SUCCESS';
```

**チェック条件**
- **migration_name**: ファイル名が一致
- **status = 'SUCCESS'**: 成功したマイグレーションのみ

**判定結果**
- **0**: 未実行 → マイグレーションを実行
- **1以上**: 実行済み → スキップ

#### 3. 条件分岐による制御
```bash
if [ "$executed" -eq 0 ]; then
    # 未実行の場合：マイグレーションを実行
    run_single_migration "$migration_file"
else
    # 実行済みの場合：スキップ
    log_info "スキップ: $migration_name (既に実行済み)"
fi
```

### 実装詳細

#### ファイル名の抽出
```bash
local migration_name=$(basename "$migration_file")
```

- フルパスからファイル名のみを抽出
- 例: `/path/to/001_create_users_table.sql` → `001_create_users_table.sql`

#### 実行履歴の記録
マイグレーション実行後、`migration_history`テーブルに履歴を記録：

```sql
INSERT INTO migration_history (migration_name, execution_time_ms, status) 
VALUES ('$(basename "$migration_file")', $execution_time, 'SUCCESS')
ON DUPLICATE KEY UPDATE 
    executed_at = CURRENT_TIMESTAMP,
    execution_time_ms = $execution_time,
    status = 'SUCCESS',
    error_message = NULL;
```

## 使用方法

### 基本的なコマンド

```bash
# 全てのマイグレーションを実行
make migrate

# 特定のマイグレーションファイルを実行
make migrate-file FILE=sql/migrations/001_create_users_table.sql

# マイグレーション履歴を表示
make migration-history
```

### 実際の動作例

#### 実行前の状態
```sql
-- migration_historyテーブルの状態
SELECT migration_name, status FROM migration_history;
+--------------------------------+---------+
| migration_name                 | status  |
+--------------------------------+---------+
| 001_create_users_table.sql     | SUCCESS |
| 002_create_orders_table.sql    | SUCCESS |
| 003_create_warehouse_table.sql | SUCCESS |
+--------------------------------+---------+
```

#### 実行時の判定例

**未実行のマイグレーション**
```bash
# 004_create_analysis_tables.sqlの場合
SELECT COUNT(*) FROM migration_history 
WHERE migration_name = '004_create_analysis_tables.sql' 
AND status = 'SUCCESS';
-- 結果: 0 → 未実行 → 実行する
```

**実行済みのマイグレーション**
```bash
# 001_create_users_table.sqlの場合  
SELECT COUNT(*) FROM migration_history 
WHERE migration_name = '001_create_users_table.sql' 
AND status = 'SUCCESS';
-- 結果: 1 → 実行済み → スキップ
```

#### 実行ログ例
```bash
$ make migrate
[INFO] 未実行のマイグレーションを確認中...
[INFO] スキップ: 001_create_users_table.sql (既に実行済み)
[INFO] スキップ: 002_create_orders_table.sql (既に実行済み)
[INFO] スキップ: 003_create_warehouse_table.sql (既に実行済み)
[INFO] 実行中: 004_create_analysis_tables.sql
[INFO] 完了: 004_create_analysis_tables.sql (実行時間: 2s)
[INFO] マイグレーション実行完了
```

## migration_historyテーブル

### テーブル構造
```sql
CREATE TABLE migration_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    migration_name VARCHAR(255) NOT NULL,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    execution_time_ms INT NOT NULL,
    status ENUM('SUCCESS', 'FAILED') NOT NULL,
    error_message TEXT
);
```

### 各カラムの説明
- **id**: 主キー（自動採番）
- **migration_name**: マイグレーションファイル名
- **executed_at**: 実行日時
- **execution_time_ms**: 実行時間（ミリ秒）
- **status**: 実行結果（SUCCESS/FAILED）
- **error_message**: エラーメッセージ（失敗時のみ）

### 管理コマンド
```bash
# マイグレーション履歴の確認
make migration-history

# 特定のマイグレーション履歴を確認
docker compose -f docker/mysql/compose.yaml exec mysql mysql -u practice_user -ppractice_password practice_db -e "
SELECT * FROM migration_history WHERE migration_name = 'ファイル名.sql';"

# マイグレーション履歴のリセット
docker compose -f docker/mysql/compose.yaml exec mysql mysql -u practice_user -ppractice_password practice_db -e "
DELETE FROM migration_history WHERE migration_name = 'リセットしたいファイル名.sql';"
```

## 制限事項と注意点

### 1. ステータスによる制御
- `SUCCESS`のみが実行済みとして認識
- `FAILED`の場合は再実行される
- エラーが発生した場合、`status = 'FAILED'`で記録

### 2. ファイル名の依存
- ファイル名が変更された場合、新しいマイグレーションとして認識
- リネーム時の注意が必要
- ファイル名の一貫性が重要

### 3. 手動実行の考慮
- `make migrate-file`で個別実行した場合も履歴に記録される
- 一貫性が保たれる
- 履歴テーブルが唯一の信頼できる情報源

## トラブルシューティング

### 1. 実行済みなのに再実行される場合
```bash
# migration_historyテーブルを確認
docker compose -f docker/mysql/compose.yaml exec mysql mysql -u practice_user -ppractice_password practice_db -e "
SELECT migration_name, status, executed_at FROM migration_history 
WHERE migration_name = '問題のファイル名.sql';"
```

### 2. 実行済みなのにスキップされない場合
```bash
# ファイル名の確認
ls -la sql/migrations/
# ファイル名にスペースや特殊文字がないか確認
```

### 3. マイグレーション履歴のリセット
```bash
# 特定のマイグレーション履歴を削除
docker compose -f docker/mysql/compose.yaml exec mysql mysql -u practice_user -ppractice_password practice_db -e "
DELETE FROM migration_history WHERE migration_name = 'リセットしたいファイル名.sql';"
```

## 今後の改善計画

### Phase 1: 基本機能の強化
1. チェックサム機能の実装
2. バリデーション機能の追加
3. 詳細ログ機能の実装

### Phase 2: 高度な機能の追加
1. ロールバック機能の実装
2. 並列実行防止機能
3. migration_historyテーブルの拡張

### Phase 3: 運用機能の改善
1. レポート機能の追加
2. モニタリング機能の実装
3. 自動テスト機能の追加

## まとめ

このマイグレーション管理システムは、シンプルで軽量、かつ信頼性の高い設計となっています。現在の実装に段階的な改善を加えることで、エンタープライズレベルのマイグレーション管理を実現できます。
