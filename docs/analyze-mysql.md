# MySQL実行計画分析ガイド

## 基本的な実行計画の確認

```mysql
EXPLAIN ANALYZE SELECT * FROM users;
-- -> Table scan on users  (cost=1.05 rows=8) (actual time=0.692..0.738 rows=8 loops=1)
```

## 実行計画の詳細解説

### 実行計画の基本構造

実行計画は以下の形式で表示されます：
```
-> 操作名 on テーブル名  (cost=推定コスト rows=推定行数) (actual time=開始時間..終了時間 rows=実際の行数 loops=ループ回数)
```

### 各要素の詳細解説

#### 1. 操作名（Operation）
| 操作名 | 説明 | 最適化のポイント |
|--------|------|------------------|
| `Table scan` | テーブル全体をスキャン | インデックス作成を検討 |
| `Index scan` | インデックスを使用したスキャン | 適切なインデックスが使用されているか確認 |
| `Index lookup` | インデックスによる直接アクセス | 最も効率的なアクセス方法 |
| `Sort` | ソート処理 | ORDER BY句の最適化を検討 |
| `Filter` | フィルタリング処理 | WHERE句の最適化を検討 |
| `Aggregate` | 集計処理 | GROUP BY句の最適化を検討 |
| `Window` | Window関数の処理 | パーティション分割の最適化を検討 |
| `Nested loop` | ネストしたループ結合 | JOIN順序の最適化を検討 |
| `Hash join` | ハッシュ結合 | 大規模データでの効率的な結合 |
| `Merge join` | マージ結合 | ソート済みデータでの効率的な結合 |

#### 2. テーブル名（Table）
- **対象テーブル**: 処理対象となるテーブル名
- **エイリアス**: クエリで指定されたエイリアス名
- **派生テーブル**: サブクエリやCTEの場合は識別子

#### 3. 推定コスト（cost）
```
cost=1.05
```
- **単位**: 相対的なコスト値（絶対値ではない）
- **読み方**: 低いほど効率的
- **比較**: 同じクエリ内での相対的な比較が有効
- **最適化目標**: 全体的なコストの削減

#### 4. 推定行数（rows）
```
rows=8
```
- **意味**: 処理される推定行数
- **読み方**: 少ないほど効率的
- **注意点**: 統計情報に基づく推定値のため、実際の行数と異なる場合がある
- **最適化**: 不要な行の処理を減らす

#### 5. 実際の実行時間（actual time）
```
actual time=0.692..0.738
```
- **形式**: `開始時間..終了時間`（ミリ秒）
- **読み方**: 
  - 開始時間: 最初の行を取得するまでの時間
  - 終了時間: 全行を取得するまでの時間
- **最適化目標**: 終了時間の短縮

#### 6. 実際の行数（actual rows）
```
rows=8
```
- **意味**: 実際に処理された行数
- **比較**: 推定行数（rows）との比較で統計情報の精度を確認
- **最適化**: 推定値と実際値の乖離が大きい場合は統計情報の更新を検討

#### 7. ループ回数（loops）
```
loops=1
```
- **意味**: その操作が実行された回数
- **読み方**: 少ないほど効率的
- **注意点**: ネストしたループでは内側のループ回数が重要
- **最適化**: ループ回数の削減がパフォーマンス向上に直結

### 実行計画の読み方の例

#### 例1: シンプルなテーブルスキャン
```
-> Table scan on users  (cost=1.05 rows=8) (actual time=0.692..0.738 rows=8 loops=1)
```

**解説**:
- **操作**: `Table scan` - テーブル全体をスキャン
- **対象**: `users`テーブル
- **推定コスト**: `1.05` - 比較的低いコスト
- **推定行数**: `8`行
- **実行時間**: `0.692ms`から`0.738ms`（46μsの差）
- **実際行数**: `8`行（推定と一致）
- **ループ回数**: `1`回

**評価**: 小規模テーブルでの効率的な処理

#### 例2: インデックスを使用した検索
```
-> Index lookup on users using PRIMARY (id=1)  (cost=0.35 rows=1) (actual time=0.1..0.1 rows=1 loops=1)
```

**解説**:
- **操作**: `Index lookup` - インデックスによる直接アクセス
- **対象**: `users`テーブルのPRIMARYキー
- **条件**: `id=1`
- **推定コスト**: `0.35` - 非常に低いコスト
- **推定行数**: `1`行
- **実行時間**: `0.1ms`（開始と終了が同じ）
- **実際行数**: `1`行
- **ループ回数**: `1`回

**評価**: 最も効率的なアクセス方法

#### 例3: フィルタリング処理
```
-> Filter: (email IS NOT NULL)  (cost=1.05 rows=6) (actual time=0.5..0.6 rows=6 loops=1)
    -> Table scan on users  (cost=1.05 rows=8) (actual time=0.4..0.5 rows=8 loops=1)
```

**解説**:
- **操作**: `Filter` - 条件によるフィルタリング
- **条件**: `email IS NOT NULL`
- **推定コスト**: `1.05` - ベーステーブルと同じ
- **推定行数**: `6`行（8行から2行削減）
- **実行時間**: `0.5ms`から`0.6ms`
- **実際行数**: `6`行
- **ループ回数**: `1`回
- **子操作**: `Table scan`で8行をスキャンし、フィルタで6行に削減

**評価**: フィルタリングにより行数が削減されている

### パフォーマンス問題の特定

#### 1. 高コストの操作
```
cost=1000.5  # 非常に高いコスト
```
**対策**:
- インデックスの追加
- クエリの書き換え
- テーブル設計の見直し

#### 2. 大量の行処理
```
rows=1000000  # 大量の行
```
**対策**:
- WHERE句の追加
- LIMIT句の使用
- パーティショニングの検討

#### 3. 長時間の実行
```
actual time=1000.5..2000.3  # 1-2秒の実行時間
```
**対策**:
- インデックスの最適化
- クエリの簡素化
- 実行計画の見直し

#### 4. 多回数のループ
```
loops=1000  # 1000回のループ
```
**対策**:
- JOIN順序の最適化
- サブクエリの書き換え
- インデックスの追加

### 最適化のチェックリスト

#### インデックス関連
- [ ] WHERE句の条件に適切なインデックスが存在するか
- [ ] JOIN条件にインデックスが使用されているか
- [ ] ORDER BY句にインデックスが活用されているか
- [ ] 複合インデックスの順序が適切か

#### クエリ構造
- [ ] 不要な列の選択を避けているか
- [ ] 適切なWHERE句で行数を削減しているか
- [ ] サブクエリをJOINに書き換えられないか
- [ ] Window関数の使用を検討しているか

#### テーブル設計
- [ ] 適切なデータ型を使用しているか
- [ ] NULL値の使用を最小限にしているか
- [ ] 正規化が適切か
- [ ] パーティショニングを検討しているか

## 相関サブクエリ vs Window関数の比較

### 実行計画の読み方

#### 重要な指標
- **cost**: 推定コスト（低いほど良い）
- **actual time**: 実際の実行時間
- **rows**: 処理される行数
- **loops**: ループ回数

#### パフォーマンスの判断基準
1. **cost**: 低いほど効率的
2. **actual time**: 短いほど高速
3. **rows**: 少ないほど効率的
4. **loops**: 少ないほど効率的

### 比較分析の実行方法

```bash
# 分析用クエリの実行
make query FILE=sql/queries/analysis/correlated_subquery_vs_window.sql
```

### 期待される結果

#### 相関サブクエリの特徴
- **メリット**: シンプルで理解しやすい
- **デメリット**: 各行に対してサブクエリが実行されるため、パフォーマンスが劣る
- **適用場面**: 小規模データ、単発の分析

#### Window関数の特徴
- **メリット**: 一度のスキャンで全データを処理、パフォーマンスが優れている
- **デメリット**: 構文が複雑、理解しにくい場合がある
- **適用場面**: 大規模データ、複雑な分析

### 分析結果の解釈

#### 相関サブクエリの実行計画例
```
-> Filter: (s.amount > (select #2))  (cost=... rows=...) (actual time=...)
    -> Table scan on s  (cost=... rows=...) (actual time=...)
    -> Select #2 (subquery in condition; run only once)
        -> Aggregate: avg(s2.amount)  (cost=... rows=...) (actual time=...)
            -> Filter: (s2.region = s.region)  (cost=... rows=...) (actual time=...)
                -> Table scan on s2  (cost=... rows=...) (actual time=...)
```

**各行の解説**:
1. **Filter**: メインクエリの条件チェック
2. **Table scan on s**: メインテーブルのスキャン
3. **Select #2**: 相関サブクエリの実行
4. **Aggregate**: 平均値の計算
5. **Filter**: 相関条件によるフィルタリング
6. **Table scan on s2**: サブクエリ内のテーブルスキャン

#### Window関数の実行計画例
```
-> Filter: (amount > region_avg)  (cost=... rows=...) (actual time=...)
    -> Window aggregate with buffering: avg(s.amount) OVER (PARTITION BY s.region )   (cost=... rows=...) (actual time=...)
        -> Sort: s.region  (cost=... rows=...) (actual time=...)
            -> Table scan on s  (cost=... rows=...) (actual time=...)
```

**各行の解説**:
1. **Filter**: 計算結果によるフィルタリング
2. **Window aggregate**: Window関数による集計処理
3. **Sort**: パーティション分割のためのソート
4. **Table scan on s**: ベーステーブルのスキャン

### 最適化のポイント

1. **インデックスの活用**: WHERE句やJOIN条件に適切なインデックスを作成
2. **データ量の考慮**: 小規模データでは相関サブクエリ、大規模データではWindow関数
3. **実行頻度**: 頻繁に実行されるクエリはWindow関数を優先
4. **可読性**: チームの理解度に応じて選択

## 実践的な分析例

### 例1: ユーザー統計クエリの分析

```sql
EXPLAIN ANALYZE 
SELECT 
    region,
    COUNT(*) as user_count,
    AVG(amount) as avg_amount
FROM users u
JOIN sales s ON u.id = s.user_id
WHERE s.created_at >= '2024-01-01'
GROUP BY region
ORDER BY user_count DESC;
```

**期待される実行計画**:
```
-> Sort: user_count DESC  (cost=... rows=...) (actual time=...)
    -> Aggregate: count(*), avg(s.amount)  (cost=... rows=...) (actual time=...)
        -> Nested loop inner join  (cost=... rows=...) (actual time=...)
            -> Filter: (s.created_at >= '2024-01-01')  (cost=... rows=...) (actual time=...)
                -> Index scan on s using idx_created_at  (cost=... rows=...) (actual time=...)
            -> Index lookup on u using PRIMARY (id=s.user_id)  (cost=... rows=...) (actual time=...)
```

### 例2: 複雑な分析クエリの最適化

```sql
-- 最適化前（相関サブクエリ）
EXPLAIN ANALYZE
SELECT 
    product_name,
    amount,
    (SELECT AVG(amount) FROM sales s2 WHERE s2.product_id = s1.product_id) as avg_amount
FROM sales s1
WHERE amount > (SELECT AVG(amount) FROM sales s2 WHERE s2.product_id = s1.product_id);

-- 最適化後（Window関数）
EXPLAIN ANALYZE
SELECT 
    product_name,
    amount,
    avg_amount
FROM (
    SELECT 
        product_name,
        amount,
        AVG(amount) OVER (PARTITION BY product_id) as avg_amount
    FROM sales
) ranked_sales
WHERE amount > avg_amount;
```

**最適化効果**:
- **ループ回数**: 大幅な削減
- **実行時間**: 50-80%の短縮
- **コスト**: 30-60%の削減
