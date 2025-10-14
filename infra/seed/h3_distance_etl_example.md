# H3 Distance Matrix ETL 流程

## 概述
本文件說明如何使用 OSRM 伺服器計算並導入全台灣 H3 res=10 格子對（k=40 範圍內）的距離資料。

## 前置條件
1. 自架 OSRM 伺服器（台灣地圖資料）
2. H3 格子清單（全台灣 res=10）
3. PostgreSQL/Supabase 資料庫

## ETL 步驟

### 1. 產生 H3 格子清單
```python
# generate_h3_cells.py
import h3
from shapely.geometry import box

# Taiwan bounding box
taiwan_bbox = box(120.0, 21.9, 122.0, 25.3)

# Generate all H3 cells covering Taiwan at res=10
cells = h3.polyfill_geojson(
    {
        'type': 'Polygon',
        'coordinates': [list(taiwan_bbox.exterior.coords)]
    },
    res=10
)

# Save to file
with open('taiwan_h3_res10.txt', 'w') as f:
    for cell in cells:
        f.write(f"{cell}\n")

print(f"Generated {len(cells)} H3 cells")
```

### 2. 計算距離矩陣（OSRM 批次查詢）
```python
# compute_distances.py
import requests
import json
from itertools import product

# Load H3 cells
with open('taiwan_h3_res10.txt') as f:
    cells = [line.strip() for line in f]

# OSRM server URL
OSRM_URL = "http://localhost:5000"

# Output CSV
output = []

# For each cell, query distances to k=40 neighbors
for from_cell in cells:
    # Get k=40 ring neighbors
    neighbors = h3.k_ring(from_cell, 40)

    # Batch query OSRM (max 100 destinations per request)
    for i in range(0, len(neighbors), 100):
        batch = list(neighbors)[i:i+100]

        # Get coordinates
        from_coord = h3.h3_to_geo(from_cell)
        to_coords = [h3.h3_to_geo(c) for c in batch]

        # OSRM table request
        coords_str = f"{from_coord[1]},{from_coord[0]};" + \
                     ";".join([f"{c[1]},{c[0]}" for c in to_coords])

        response = requests.get(
            f"{OSRM_URL}/table/v1/driving/{coords_str}",
            params={'sources': '0', 'annotations': 'duration,distance'}
        )

        if response.status_code == 200:
            data = response.json()
            durations = data['durations'][0]  # First row (source 0)
            distances = data['distances'][0]

            for j, to_cell in enumerate(batch):
                time_min = int(durations[j+1] / 60)  # Convert seconds to minutes
                dist_km = distances[j+1] / 1000  # Convert meters to km

                output.append({
                    'from_h3': from_cell,
                    'to_h3': to_cell,
                    'time_minutes': time_min,
                    'distance_km': round(dist_km, 2)
                })

    if len(output) % 10000 == 0:
        print(f"Processed {len(output)} pairs...")

# Save to CSV
import csv
with open('h3_distance_matrix.csv', 'w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=['from_h3', 'to_h3', 'time_minutes', 'distance_km'])
    writer.writeheader()
    writer.writerows(output)

print(f"Generated {len(output)} distance pairs")
```

### 3. 導入 Supabase
```sql
-- Load CSV into Supabase (use Supabase Studio or psql)
COPY h3_distance_matrix(from_h3, to_h3, time_minutes, distance_km)
FROM '/path/to/h3_distance_matrix.csv'
DELIMITER ','
CSV HEADER;

-- Verify
SELECT COUNT(*) FROM h3_distance_matrix;
SELECT * FROM h3_distance_matrix LIMIT 10;
```

或使用 Supabase Client (Dart):
```dart
// bulk_import.dart
final csv = File('h3_distance_matrix.csv').readAsLinesSync();
final rows = csv.skip(1).map((line) {
  final parts = line.split(',');
  return {
    'from_h3': parts[0],
    'to_h3': parts[1],
    'time_minutes': int.parse(parts[2]),
    'distance_km': double.parse(parts[3]),
  };
}).toList();

// Batch insert (max 1000 per request)
for (var i = 0; i < rows.length; i += 1000) {
  final batch = rows.skip(i).take(1000).toList();
  await supabase.from('h3_distance_matrix').insert(batch);
  print('Inserted ${i + batch.length} / ${rows.length}');
}
```

## 資料量估算
- 台灣 H3 res=10 格子數：約 3,000 個
- 每格 k=40 範圍：約 (81)² ≈ 6,561 格（實際因陸地形狀會少一些）
- 總資料筆數：3,000 × 1,000（平均）= 300 萬筆
- 儲存空間：每筆約 50 bytes → 150 MB

## 更新策略
- 初次載入：完整計算與導入
- 定期更新：週或月（路況變化較小可降低頻率）
- 增量更新：僅更新有變化的 pairs（比對 distance_km 差異）

## 查詢效能
- Primary key `(from_h3, to_h3)`：點查詢 O(1)
- 批量查詢（get_batch_eta RPC）：單次查詢 100 對約 5-10ms

## 注意事項
- OSRM 伺服器需足夠記憶體（建議 8GB+）
- 批次計算建議分批進行，避免 timeout
- CSV 檔案較大（數百 MB），建議壓縮傳輸

