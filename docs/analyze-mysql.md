# MySQL実行計画分析ガイド

## 基本的な実行計画の確認

```mysql
EXPLAIN ANALYZE SELECT * FROM users;
-- -> Table scan on users  (cost=1.05 rows=8) (actual time=0.692..0.738 rows=8 loops=1)
```

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

#### Window関数の実行計画例
```
-> Filter: (amount > region_avg)  (cost=... rows=...) (actual time=...)
    -> Window aggregate with buffering: avg(s.amount) OVER (PARTITION BY s.region )   (cost=... rows=...) (actual time=...)
        -> Sort: s.region  (cost=... rows=...) (actual time=...)
            -> Table scan on s  (cost=... rows=...) (actual time=...)
```

### 最適化のポイント

1. **インデックスの活用**: WHERE句やJOIN条件に適切なインデックスを作成
2. **データ量の考慮**: 小規模データでは相関サブクエリ、大規模データではWindow関数
3. **実行頻度**: 頻繁に実行されるクエリはWindow関数を優先
4. **可読性**: チームの理解度に応じて選択
