# GitHubディレクトリ（.github/）の解説

## 概要

`.github`ディレクトリは、GitHubの機能を活用してプロジェクトの品質向上と効率化を図るための重要な設定ディレクトリです。このディレクトリには、GitHub Actions、Dependabot、Issue/PRテンプレートなどの設定ファイルが含まれます。

## ディレクトリ構造

```
.github/
├── workflows/              # GitHub Actionsワークフロー
│   └── ci.yml
├── ISSUE_TEMPLATE/         # Issueテンプレート
│   ├── bug_report.md
│   └── feature_request.md
├── dependabot.yml          # Dependabot設定
└── pull_request_template.md # PRテンプレート
```

## 各ファイルの詳細解説

### 1. GitHub Actions（.github/workflows/）

#### 公式リファレンス
- **GitHub Actions ドキュメント**: https://docs.github.com/en/actions
- **ワークフロー構文**: https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions

#### 現在の設定：ci.yml

```yaml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
```

**根拠**: [GitHub Actions トリガー設定](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows)
- `push`: 指定ブランチへのプッシュ時に実行
- `pull_request`: 指定ブランチへのPR作成時に実行

#### サービスコンテナの設定

```yaml
services:
  mysql:
    image: mysql:8.0.36
    env:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: practice_db
      MYSQL_USER: practice_user
      MYSQL_PASSWORD: practice_password
    ports:
      - 3306:3306
    options: --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=3
```

**根拠**: [サービスコンテナの使用](https://docs.github.com/en/actions/using-containerized-services)
- CI/CD環境でMySQLサービスを提供
- ヘルスチェックでサービスの準備完了を確認
- データベーステストの実行環境を構築

#### ジョブ構成

1. **test ジョブ**: SQLファイルの構文チェック
2. **lint ジョブ**: ファイル命名規則の検証
3. **security ジョブ**: セキュリティスキャン

**根拠**: [ジョブとステップの定義](https://docs.github.com/en/actions/using-jobs)

#### テストジョブの詳細

```yaml
- name: Run tests
  run: |
    # SQLファイルの構文チェック
    for file in sql/migrations/*.sql sql/seeds/*.sql sql/queries/**/*.sql; do
      if [ -f "$file" ]; then
        echo "Checking SQL syntax: $file"
        if grep -q "CREATE\|INSERT\|SELECT\|UPDATE\|DELETE" "$file"; then
          echo "✓ SQL file contains valid SQL statements: $file"
        else
          echo "⚠ Warning: SQL file may not contain valid statements: $file"
        fi
      fi
    done
```

**目的**: SQLファイルの基本的な構文チェックを実行

#### リントジョブの詳細

```yaml
- name: Check file naming conventions
  run: |
    # マイグレーションファイルの命名チェック
    if ! ls sql/migrations/ | grep -E '^[0-9]{3}_[a-z_]+\.sql$' > /dev/null; then
      echo "Error: Migration files must follow the pattern: 001_name.sql"
      exit 1
    fi
    
    # シードファイルの命名チェック
    if ! ls sql/seeds/ | grep -E '^[0-9]{3}_sample_[a-z_]+\.sql$' > /dev/null; then
      echo "Error: Seed files must follow the pattern: 001_sample_name.sql"
      exit 1
    fi
```

**目的**: プロジェクトルールに従ったファイル命名の検証

### 2. Dependabot設定（.github/dependabot.yml）

#### 公式リファレンス
- **Dependabot ドキュメント**: https://docs.github.com/en/code-security/dependabot
- **設定オプション**: https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file

#### 現在の設定

```yaml
version: 2
updates:
  # GitHub Actionsの依存関係を更新
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
    open-pull-requests-limit: 10
    assignees:
      - "shun968"
    commit-message:
      prefix: "chore"
      prefix-development: "chore"
      include: "scope"

  # Docker Composeの依存関係を更新
  - package-ecosystem: "docker"
    directory: "/docker/mysql"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
    open-pull-requests-limit: 5
    assignees:
      - "shun968"
    commit-message:
      prefix: "chore"
      prefix-development: "chore"
      include: "scope"
```

**根拠**: [Dependabot設定ファイル](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file#package-ecosystem)
- `version: 2`: 最新の設定形式
- `package-ecosystem`: サポートされているエコシステムを指定
- `schedule`: 更新チェックのスケジュール設定

#### 設定項目の詳細

| 項目 | 説明 | 根拠 |
|------|------|------|
| `package-ecosystem` | パッケージエコシステムの種類 | [サポートされているエコシステム](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file#package-ecosystem) |
| `directory` | 設定ファイルの場所 | [ディレクトリ指定](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file#directory) |
| `schedule` | 更新チェックのスケジュール | [スケジュール設定](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file#schedule) |
| `open-pull-requests-limit` | 同時に開くPRの最大数 | [PR制限設定](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file#open-pull-requests-limit) |

### 3. プルリクエストテンプレート（.github/pull_request_template.md）

#### 公式リファレンス
- **PRテンプレート**: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository

#### 現在の設定

```markdown
## 概要
<!-- 変更の概要を簡潔に説明 -->

## 変更内容
<!-- 変更点を箇条書きで記載 -->
- 変更点1
- 変更点2
- 変更点3

## 影響範囲
<!-- 影響を受ける機能やファイル -->
- 影響を受ける機能1
- 影響を受ける機能2

## テスト
<!-- 実行したテスト内容 -->
- [ ] 単体テスト
- [ ] 統合テスト
- [ ] 手動テスト

## チェックリスト
- [ ] コードレビューを依頼しました
- [ ] テストが通ることを確認しました
- [ ] ドキュメントを更新しました（必要に応じて）
- [ ] コミットメッセージがプロジェクトルールに従っています

## 関連Issue
<!-- 関連するIssue番号（該当する場合） -->
Closes #
```

**根拠**: [PRテンプレートの作成](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository)
- ファイル名は`pull_request_template.md`または`PULL_REQUEST_TEMPLATE.md`
- ルートまたは`.github/`ディレクトリに配置

### 4. Issueテンプレート（.github/ISSUE_TEMPLATE/）

#### 公式リファレンス
- **Issueテンプレート**: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository

#### バグ報告テンプレート（bug_report.md）

```yaml
---
name: バグ報告
about: バグを報告して改善にご協力ください
title: '[BUG] '
labels: ['bug']
assignees: ['shun968']
---
```

#### 機能要求テンプレート（feature_request.md）

```yaml
---
name: 機能要求
about: このプロジェクトのアイデアを提案してください
title: '[FEATURE] '
labels: ['enhancement']
assignees: ['shun968']
---
```

**根拠**: [Issueテンプレートの設定](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository#creating-issue-forms)
- YAMLフロントマターでメタデータを定義
- `name`: テンプレートの表示名
- `about`: テンプレートの説明
- `title`: デフォルトのタイトルプレフィックス
- `labels`: 自動付与されるラベル
- `assignees`: 自動アサインされるユーザー

## ファイル命名規則

#### 公式リファレンス
- **ファイル命名**: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository#creating-a-pull-request-template

| ファイル名 | 用途 | 根拠 |
|-----------|------|------|
| `pull_request_template.md` | PRテンプレート | [PRテンプレート作成](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository) |
| `ISSUE_TEMPLATE/` | Issueテンプレートディレクトリ | [Issueテンプレート設定](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository) |
| `workflows/` | GitHub Actionsワークフロー | [ワークフロー作成](https://docs.github.com/en/actions/using-workflows/creating-workflows) |
| `dependabot.yml` | Dependabot設定 | [Dependabot設定](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file) |

## 設定の優先順位

#### 公式リファレンス
- **テンプレート優先順位**: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository#creating-a-pull-request-template

1. `.github/pull_request_template.md`（優先）
2. `docs/pull_request_template.md`
3. ルートの`pull_request_template.md`

## セキュリティ考慮事項

#### 公式リファレンス
- **セキュリティベストプラクティス**: https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions

```yaml
# 推奨設定
env:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}  # 最小権限の原則
```

### セキュリティチェックの実装

```yaml
- name: Run security scan
  run: |
    # 機密情報のチェック
    if grep -r "password\|secret\|token" . --exclude-dir=.git --exclude-dir=node_modules; then
      echo "Warning: Potential secrets found in code"
    fi
```

## カスタマイズ例

### Issueテンプレートの拡張

```yaml
---
name: セキュリティ報告
about: セキュリティ脆弱性を報告
title: '[SECURITY] '
labels: ['security', 'high-priority']
assignees: ['security-team']
body:
  - type: markdown
    attributes:
      value: |
        セキュリティ報告のガイドライン
  - type: textarea
    id: vulnerability
    attributes:
      label: 脆弱性の詳細
      description: 発見した脆弱性について詳しく説明してください
    validations:
      required: true
---
```

**根拠**: [Issue Forms](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository#creating-issue-forms)

### ワークフローの拡張

```yaml
# デプロイメントワークフローの例
name: Deploy

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v5
    - name: Deploy to production
      run: |
        echo "Deploying to production..."
```

## ベストプラクティス

### 1. 最小権限の原則
- 必要最小限の権限のみを付与
- セキュリティトークンの適切な管理

### 2. テンプレートの標準化
- 一貫性のあるテンプレート設計
- プロジェクト固有の要件に合わせたカスタマイズ

### 3. 自動化の活用
- CI/CDパイプラインの構築
- 依存関係の自動更新

### 4. ドキュメント化
- 設定内容の明確な記録
- 変更履歴の管理

## トラブルシューティング

### よくある問題と解決方法

1. **ワークフローが実行されない**
   - トリガー設定の確認
   - ブランチ名の確認

2. **Dependabotが更新を検出しない**
   - パッケージエコシステムの確認
   - ディレクトリパスの確認

3. **テンプレートが表示されない**
   - ファイル名の確認
   - ディレクトリ構造の確認

## まとめ

`.github`ディレクトリは、GitHubの機能を活用してプロジェクトの品質向上と効率化を図るための重要な設定ディレクトリです。公式リファレンスに基づいた適切な設定により、以下の効果が期待できます：

1. **自動化**: CI/CD、依存関係管理の自動化
2. **標準化**: Issue、PRの標準化されたテンプレート
3. **品質向上**: コードレビュー、テストの自動実行
4. **セキュリティ**: 脆弱性の自動検出と更新

現在の設定は公式リファレンスに準拠しており、プロジェクトの特性に適した構成となっています。

## 参考リンク

- [GitHub Actions ドキュメント](https://docs.github.com/en/actions)
- [Dependabot ドキュメント](https://docs.github.com/en/code-security/dependabot)
- [Issue テンプレート](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository)
- [PR テンプレート](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository)
