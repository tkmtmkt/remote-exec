
### Excel

| 項目         | 値       |
|--------------|----------|
| 保管フォルダ | =MID(CELL("filename",A1,1,FIND("[",CELL("filename",A1))-1))&"out"
| 取得日       | YYYYMMDD |


#### q_取得日のファイル一覧

```powerquery
let
    パラメータ = Table.TransformColumn(Excel.CurrentWorkbook(){[Name="パラメータ"]}[Content],{{"値", type text}}),
    保管フォルダ = Table.SelectRows(パラメータ, each([項目] = "保管フォルダ"))[値]{0},
    取得日 = Table.SelectRows(パラメータ, wach([項目] = "取得日"))[値]{0},
    ソース = Folder.Files(保管フォルダ)
    取得日のファイル一覧 = Table.SelectRows(ソース, each Text.Contains([Folder Path], 取得日) and [Attribute]?[Size]>0)
in
    取得日のファイル一覧
```

#### f_テーブルに変換

```powerquery
let
    テーブルに変換 = (対象ファイル as binary) => let
        ソース = Csv.Document(対象ファイル, [Delimiter=";", Encoding=932, QuoteStyle=QuoteStyle.None]),
        テーブル = Table.PromoteHeaders(ソース, [PromoteAllScalars=true]),
    in
        テーブル
in
    テーブルに変換
```

#### f_データ抽出

```powerquery
let
    データ抽出 = (処理対象ファイル名の先頭文字列 as text) => let
        処理対象ファイル一覧 = Table.SelectRows(q_取得日のファイル一覧, each Text.StartWith([Name], 処理対象ファイル名の先頭文字列)),
        処理対象ファイル一覧_内容追加 = Table.AddCoumn(処理対象ファイル一覧, "テーブル", each f_テーブルに変換([Content])),
        処理対象ファイル一覧_列名変更 = Table.RenameColumns(処理対象ファイル一覧_内容追加, {"Name", "Source.Name"}),
        処理対象ファイル一覧_列削除 = Table.SelectColumns(処理対象ファイル一覧_列名変更, {"Source.Name", "テーブル"}),
        テーブル = Table.ExpandTableColumn(処理対象ファイル一覧_列削除, "テーブル", Table.ColumnNames(Table.LastN(処理対象ファイル一覧_列削除, 1)[テーブル]{0})),
        テーブル_行選択 = Table.SelectRows(テーブル, each not List.Contains({"interval", "-1", null}, [interval])),
        テーブル_列選択 = Table.RemoveColumns(テーブル_行選択, {"Source.Name", "interval"}),
        処理結果 = Table.Sort(テーブル_列選択, {{"timestamp", Order.Ascending}})
    in
        処理結果
in
    データ抽出
```


#### q_メモリ使用状況

```powerquery
let
    ソース = f_データ抽出("sar_r"),
    型変更 = Table.TransformColumnTypes(ソース, {{"timestamp", type datetime}, {"kbmemfree", type number}, {"kbmemused", type number}, {"%memused", type number}, {"kbcommit", type number}, {"%commit", type number}})
in
    型変更
```

#### q_ロードアベレージ状況

```powerquery
let
    ソース = f_データ抽出("sar_q"),
    型変更 = Table.TransformColumnTypes(ソース, {{"timestamp", type datetime}, {"runq-sz", type number}, {"plist-sz", type number}, {"ldavg-1", type number}, {"ldavg-5", type number}, {"ldavg-15", type number}, {"blocked", type number}})
in
    型変更
```

#### q_CPU使用状況

```powerquery
let
    ソース = f_データ抽出("sar_u"),
    型変更 = Table.TransformColumnTypes(ソース, {{"timestamp", type datetime}, {"%user", type number}, {"%nice", type number}, {"%system", type number}, {"%iowait", type number}, {"%steal", type number}, {"%idle", type number}, {"CPU", type Int64.Type}})
in
    型変更
```

#### q_HDD帯域幅使用状況

```powerquery
let
    ソース = f_データ抽出("sar_dp"),
    型変更 = Table.TransformColumnTypes(ソース, {{"timestamp", type datetime}, {"DEV", type number}, {"tps", type number}, {"rkB/s", type number}, {"wkB/s", type number}, {"dkB/s", type number}, {"areq-sz", type number}, {"aqu-sz", type number}, {"await", type number}, {"%util", type number}})
in
    型変更
```

#### q_ネットワーク使用状況

```powerquery
let
    ソース = f_データ抽出("sar_n_DEV"),
    型変更 = Table.TransformColumnTypes(ソース, {{"timestamp", type datetime}, {"", type number}, {"", type number}, {"", type number}, {"", type number}, {"", type number}, {"", type number}})
in
    型変更
```

#### q_ネットワークソケット使用状況

```powerquery
let
    ソース = f_データ抽出("sar_n_SOCK"),
    型変更 = Table.TransformColumnTypes(ソース, {{"timestamp", type datetime}, {"", type number}, {"", type number}, {"", type number}, {"", type number}, {"", type number}, {"", type number}})
in
    型変更
```

#### q_コンテキストスイッチ状況

```powerquery
let
    ソース = f_データ抽出("sar_w"),
    型変更 = Table.TransformColumnTypes(ソース, {{"timestamp", type datetime}, {"", type number}, {"", type number}, {"", type number}, {"", type number}, {"", type number}, {"", type number}})
in
    型変更
```

#### q_スワップ使用状況

```powerquery
let
    ソース = f_データ抽出("sar_S"),
    型変更 = Table.TransformColumnTypes(ソース, {{"timestamp", type datetime}, {"kbswpfree", type number}, {"kbswpused", type number}, {"%swpused", type number}, {"kbswpcad", type number}, {"%swpcad", type number}})
in
    型変更
```

#### q_ディスク使用状況

```powerquery
let
    ソース = f_データ抽出("sar_F"),
    型変更 = Table.TransformColumnTypes(ソース, {{"# hostname", type text}, {"timestamp", type datetime}, {"FILESYSTEM", type text}, {"MBfsfree", type Int64.Type}, {"MBfsused", type Int64.Type}, {"%fsused", type number}, {"%ufsused", type number}, {"Ifree", type Int64.Type}, {"Iused", type Int64.Type}, {"%Iused", type number}}),
    ソート = Table.Sort(型変更, {{"timestamp", Order.Ascending}, {"FILESYSTEM", Order.Ascending}})
in
    ソート
```
