#!/bin/bash

# Performance Test Report Generator
# Usage: ./scripts/generate_performance_report.sh [output_dir]

set -e

# 設定
COMPOSE_FILE="docker/mysql/compose.yaml"
DB_USER="practice_user"
DB_PASS="practice_password"
DB_NAME="practice_db"
OUTPUT_DIR="${1:-reports}"
REPORT_FILE="$OUTPUT_DIR/performance_report.html"

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

log_header() {
    echo -e "${BLUE}[HEADER]${NC} $1"
}

# データベースからテスト結果を取得
get_test_results() {
    docker compose -f "$COMPOSE_FILE" exec -T mysql mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -s -e "
    SELECT 
        test_name,
        table_size,
        index_used,
        join_type,
        actual_time_ms,
        test_date
    FROM performance_test_results 
    ORDER BY test_date DESC, table_size, test_name;"
}

# データ量による影響のデータを取得（個別テストデータ）
get_data_volume_data() {
    docker compose -f "$COMPOSE_FILE" exec -T mysql mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -s -e "
    SELECT 
        test_name,
        table_size,
        actual_time_ms
    FROM performance_test_results 
    ORDER BY actual_time_ms DESC;"
}

# インデックスによる影響のデータを取得（総テストデータ）
get_index_data() {
    docker compose -f "$COMPOSE_FILE" exec -T mysql mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -s -e "
    SELECT 
        CASE 
            WHEN index_used = 1 THEN 'インデックスあり'
            ELSE 'インデックスなし'
        END as index_status,
        AVG(actual_time_ms) as avg_time_ms,
        COUNT(*) as test_count
    FROM performance_test_results 
    GROUP BY index_used
    ORDER BY avg_time_ms DESC;"
}

# 結合タイプによる影響のデータを取得（総テストデータ）
get_join_data() {
    docker compose -f "$COMPOSE_FILE" exec -T mysql mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -s -e "
    SELECT 
        CASE 
            WHEN join_type = 'none' THEN '結合なし'
            WHEN join_type = 'inner' THEN 'INNER JOIN'
            WHEN join_type = 'left_join' THEN 'LEFT JOIN'
            WHEN join_type = 'multiple' THEN '複数テーブル結合'
            WHEN join_type = 'subquery' THEN 'サブクエリ'
            ELSE join_type
        END as join_type_name,
        AVG(actual_time_ms) as avg_time_ms,
        COUNT(*) as test_count
    FROM performance_test_results 
    GROUP BY join_type
    ORDER BY avg_time_ms DESC;"
}

# 相関サブクエリとwindow関数の比較データを取得
get_subquery_window_data() {
    docker compose -f "$COMPOSE_FILE" exec -T mysql mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -s -e "
    SELECT 
        CASE 
            WHEN test_name LIKE '%Subquery%' THEN '相関サブクエリ'
            WHEN test_name LIKE '%Window%' OR test_name LIKE '%JOIN%' THEN 'Window関数/JOIN'
            ELSE 'その他'
        END as query_type,
        AVG(actual_time_ms) as avg_time_ms,
        COUNT(*) as test_count
    FROM performance_test_results 
    WHERE test_name LIKE '%Subquery%' OR test_name LIKE '%Window%' OR test_name LIKE '%JOIN%'
    GROUP BY 
        CASE 
            WHEN test_name LIKE '%Subquery%' THEN '相関サブクエリ'
            WHEN test_name LIKE '%Window%' OR test_name LIKE '%JOIN%' THEN 'Window関数/JOIN'
            ELSE 'その他'
        END
    ORDER BY avg_time_ms DESC;"
}

# テスト結果の詳細データを取得
get_detailed_results() {
    docker compose -f "$COMPOSE_FILE" exec -T mysql mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -s -e "
    SELECT 
        test_name,
        table_size,
        CASE 
            WHEN index_used = 1 THEN 'あり'
            ELSE 'なし'
        END as index_status,
        CASE 
            WHEN join_type = 'none' THEN 'なし'
            WHEN join_type = 'inner' THEN 'INNER JOIN'
            WHEN join_type = 'left_join' THEN 'LEFT JOIN'
            WHEN join_type = 'multiple' THEN '複数テーブル結合'
            WHEN join_type = 'subquery' THEN 'サブクエリ'
            ELSE join_type
        END as join_type_name,
        ROUND(actual_time_ms, 2) as execution_time_ms,
        DATE_FORMAT(test_date, '%Y-%m-%d %H:%i:%s') as test_date
    FROM performance_test_results 
    ORDER BY test_date DESC, table_size, test_name;"
}

# HTMLレポートを生成
generate_html_report() {
    log_info "HTMLレポートを生成中: $REPORT_FILE"
    
    # データを取得
    local test_results=$(get_test_results)
    local data_volume_data=$(get_data_volume_data)
    local index_data=$(get_index_data)
    local join_data=$(get_join_data)
    local subquery_window_data=$(get_subquery_window_data)
    local detailed_results=$(get_detailed_results)
    
    # データのJSON形式への変換
    local test_results_json=$(echo "$test_results" | jq -R -s -c 'split("\n") | map(select(length > 0)) | map(split("\t"))')
    local data_volume_json=$(echo "$data_volume_data" | jq -R -s -c 'split("\n") | map(select(length > 0)) | map(split("\t"))')
    local index_json=$(echo "$index_data" | jq -R -s -c 'split("\n") | map(select(length > 0)) | map(split("\t"))')
    local join_json=$(echo "$join_data" | jq -R -s -c 'split("\n") | map(select(length > 0)) | map(split("\t"))')
    local subquery_window_json=$(echo "$subquery_window_data" | jq -R -s -c 'split("\n") | map(select(length > 0)) | map(split("\t"))')
    local detailed_json=$(echo "$detailed_results" | jq -R -s -c 'split("\n") | map(select(length > 0)) | map(split("\t"))')
    
    # HTMLレポートを生成
    cat > "$REPORT_FILE" << EOF
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>パフォーマンステスト結果レポート</title>

    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
            border-bottom: 3px solid #007bff;
            padding-bottom: 10px;
        }
        h2 {
            color: #555;
            margin-top: 30px;
            border-left: 4px solid #007bff;
            padding-left: 15px;
        }
        .chart-container {
            display: flex;
            flex-wrap: wrap;
            gap: 20px;
            margin: 20px 0;
        }
        .chart-wrapper {
            flex: 1;
            min-width: 400px;
            height: 600px;
            background-color: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            border: 1px solid #dee2e6;
        }
        .performance-table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            background-color: white;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .performance-table th,
        .performance-table td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
            vertical-align: middle;
        }
        .performance-table th {
            background-color: #007bff;
            color: white;
            font-weight: bold;
            position: sticky;
            top: 0;
            z-index: 10;
        }
        .performance-table tr:nth-child(even) {
            background-color: #f8f9fa;
        }
        .performance-table tr:hover {
            background-color: #e3f2fd;
        }
        .bar-cell {
            width: 300px;
            padding: 8px 12px;
        }
        .bar-container {
            width: 100%;
            height: 30px;
            background-color: #f0f0f0;
            border-radius: 4px;
            overflow: hidden;
            position: relative;
        }
        .bar {
            height: 100%;
            background: linear-gradient(90deg, #4CAF50, #8BC34A);
            transition: width 0.3s ease;
            display: flex;
            align-items: center;
            justify-content: flex-end;
            padding-right: 8px;
            color: white;
            font-weight: bold;
            font-size: 12px;
        }
        .bar.high {
            background: linear-gradient(90deg, #f44336, #ff5722);
        }
        .bar.medium {
            background: linear-gradient(90deg, #ff9800, #ffc107);
        }
        .bar.low {
            background: linear-gradient(90deg, #4CAF50, #8BC34A);
        }
        .section-divider {
            border-top: 2px solid #1976d2;
            border-bottom: 2px solid #1976d2;
        }
        .section-divider:hover {
            background-color: #e3f2fd !important;
        }
        .chart-title {
            text-align: center;
            font-weight: bold;
            margin-bottom: 15px;
            color: #495057;
        }
        .summary-stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        .stat-card {
            background-color: #e3f2fd;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            border-left: 4px solid #2196f3;
        }
        .stat-value {
            font-size: 2em;
            font-weight: bold;
            color: #1976d2;
        }
        .stat-label {
            color: #555;
            margin-top: 5px;
        }
        .results-table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            background-color: white;
        }
        .results-table th,
        .results-table td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        .results-table th {
            background-color: #007bff;
            color: white;
            font-weight: bold;
        }
        .results-table tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        .results-table tr:hover {
            background-color: #e3f2fd;
        }
        .timestamp {
            text-align: center;
            color: #666;
            font-style: italic;
            margin-top: 20px;
        }
        .performance-tips {
            background-color: #fff3cd;
            border: 1px solid #ffeaa7;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
        }
        .performance-tips h3 {
            color: #856404;
            margin-top: 0;
        }
        .performance-tips ul {
            color: #856404;
        }
        .table-info {
            background-color: #e3f2fd;
            border: 1px solid #2196f3;
            border-radius: 4px;
            padding: 10px;
            margin: 10px 0;
            text-align: center;
        }
        .table-info p {
            margin: 0;
            color: #1976d2;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 パフォーマンステスト結果レポート</h1>
        
        <div class="timestamp">
            生成日時: $(date '+%Y年%m月%d日 %H:%M:%S')
        </div>

        <div class="summary-stats">
            <div class="stat-card">
                <div class="stat-value" id="total-tests">-</div>
                <div class="stat-label">総テスト数</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" id="avg-time">-</div>
                <div class="stat-label">平均実行時間 (ms)</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" id="fastest-test">-</div>
                <div class="stat-label">最速テスト (ms)</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" id="slowest-test">-</div>
                <div class="stat-label">最遅テスト (ms)</div>
            </div>
        </div>

        <div class="table-info">
            <p>📊 パフォーマンステスト結果一覧（実行時間降順）</p>
            <p style="font-size: 0.9em; margin-top: 5px; color: #666;">
                各テストの概要と実行時間を比較し、ボトルネックを特定できます
            </p>
        </div>
        
        <table class="performance-table">
            <thead>
                <tr>
                    <th>テスト名</th>
                    <th>テスト概要</th>
                    <th>実行時間 (ms)</th>
                    <th>パフォーマンスバー</th>
                </tr>
            </thead>
            <tbody id="performance-table-body">
                <!-- テーブル内容はJavaScriptで動的に生成 -->
            </tbody>
        </table>

        <div class="performance-tips">
            <h3>💡 ボトルネック分析と最適化のヒント</h3>
            <ul>
                <li><strong>ソート順の意味</strong>: 実行時間（遅い→速い）の順で、最もボトルネックとなるテストから表示</li>
                <li><strong>高ボトルネック（赤色）</strong>: 最大値の80%以上 - 最優先で最適化が必要</li>
                <li><strong>中ボトルネック（黄色）</strong>: 最大値の60-80% - 改善の余地あり</li>
                <li><strong>低ボトルネック（緑色）</strong>: 最大値の60%未満 - 良好な性能</li>
                <li><strong>データ量の影響</strong>: 大規模テーブル（1,000万行）では性能劣化が顕著</li>
                <li><strong>インデックスの効果</strong>: インデックスなしのクエリは大幅に遅くなる</li>
                <li><strong>結合の複雑さ</strong>: 複数結合やINNER JOINは性能に大きな影響</li>
                <li><strong>最適化の優先順位</strong>: 赤色のテストから最適化を開始</li>
                <li><strong>テスト概要</strong>: データ量、インデックス、結合タイプの組み合わせでテスト条件を確認</li>
                <li><strong>ボトルネック特定</strong>: 実行時間とパフォーマンスバーでボトルネックを特定</li>
            </ul>
        </div>
    </div>

    <script>
        // パフォーマンステーブルの生成
        function createPerformanceTable() {
            console.log('createPerformanceTable called');
            const data = JSON.parse('$test_results_json');
            console.log('Test results data:', data);
            
            // 実行時間で降順ソート
            data.sort((a, b) => parseFloat(b[4]) - parseFloat(a[4]));
            
            const tableBody = document.getElementById('performance-table-body');
            const maxTime = Math.max(...data.map(row => parseFloat(row[4])));
            
            data.forEach((row, index) => {
                const testName = row[0];
                const tableSize = row[1];
                const indexUsed = row[2] === '1' ? 'あり' : 'なし';
                const joinType = row[3];
                const time = parseFloat(row[4]);
                
                // テスト概要の生成
                const sizeLabel = tableSize === 'small' ? '小規模 (100行)' : 
                                tableSize === 'medium' ? '中規模 (100万行)' : 
                                '大規模 (1,000万行)';
                
                const joinLabel = joinType === 'none' ? 'なし' :
                                joinType === 'inner' ? 'INNER JOIN' :
                                joinType === 'left_join' ? 'LEFT JOIN' :
                                joinType === 'multiple' ? '複数結合' :
                                joinType === 'subquery' ? 'サブクエリ' : joinType;
                
                const testSummary = sizeLabel + ' | インデックス: ' + indexUsed + ' | 結合: ' + joinLabel;
                
                // ボトルネック度に応じた色分け
                const ratio = time / maxTime;
                let barClass = 'low';
                if (ratio > 0.8) barClass = 'high';
                else if (ratio > 0.6) barClass = 'medium';
                
                // バーの幅を計算（最大値に対する比率）
                const barWidth = (time / maxTime * 100).toFixed(1);
                
                const tableRow = document.createElement('tr');
                tableRow.innerHTML = 
                    '<td><strong>' + testName + '</strong></td>' +
                    '<td>' + testSummary + '</td>' +
                    '<td><strong>' + time.toFixed(1) + '</strong></td>' +
                    '<td class="bar-cell">' +
                        '<div class="bar-container">' +
                            '<div class="bar ' + barClass + '" style="width: ' + barWidth + '%">' +
                                time.toFixed(1) + 'ms' +
                            '</div>' +
                        '</div>' +
                    '</td>';
                tableBody.appendChild(tableRow);
            });
        }









        // 統計情報の更新
        function updateSummaryStats() {
            const data = JSON.parse('$test_results_json');
            const times = data.map(row => parseFloat(row[4]));
            
            document.getElementById('total-tests').textContent = times.length;
            document.getElementById('avg-time').textContent = (times.reduce((a, b) => a + b, 0) / times.length).toFixed(1);
            document.getElementById('fastest-test').textContent = Math.min(...times).toFixed(1);
            document.getElementById('slowest-test').textContent = Math.max(...times).toFixed(1);
        }

        // ページ読み込み時の初期化
        document.addEventListener('DOMContentLoaded', function() {
            console.log('DOM loaded, initializing performance table...');
            
            try {
                createPerformanceTable();
                updateSummaryStats();
                console.log('Performance table initialized successfully');
            } catch (error) {
                console.error('Error initializing performance table:', error);
            }
        });
    </script>
</body>
</html>
EOF

    log_info "HTMLレポートが生成されました: $REPORT_FILE"
}

# メイン処理
main() {
    log_header "パフォーマンステスト結果レポート生成を開始します"
    
    # 出力ディレクトリの作成
    mkdir -p "$OUTPUT_DIR"
    
    # HTMLレポートの生成
    generate_html_report
    
    log_header "レポート生成が完了しました"
    log_info "レポートファイル: $REPORT_FILE"
    log_info "ブラウザで開くには: open $REPORT_FILE"
}

# スクリプトの実行
main "$@"
