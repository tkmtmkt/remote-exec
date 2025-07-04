# 性能監視

### Excel

| 項目         | 値       |
|--------------|----------|
| 保管フォルダ | =MID(CELL("filename",$A$1,1,FIND("[",CELL("filename",$A$1))-1))&"out"
| ホスト名     | hostname |
| 取得日       | YYYYMMDD |


### PowerQuery

```
性能監視
|-- ヘルパークエリ
|   |-- q_取得日のファイル一覧
|   |-- f_テーブルに変換
|   `-- f_データ抽出
|-- q_メモリ使用状況
|-- q_ロードアベレージ
|-- q_CPU使用状況
|-- q_HDD帯域幅使用状況
|-- q_ネットワーク使用状況
|-- q_ネットワークソケット使用状況
|-- q_コンテキストスイッチ状況
|-- q_スワップ使用状況
`-- q_ディスク使用状況
```

#### q_取得日のファイル一覧

```powerquery
let
    パラメータ = Table.TransformColumn(Excel.CurrentWorkbook(){[Name="パラメータ"]}[Content], {{"値", type text}}),
    保管フォルダ = Table.SelectRows(パラメータ, each([項目] = "保管フォルダ"))[値]{0},
    ホスト名 = Table.SelectRows(パラメータ, each([項目] = "ホスト名"))[値]{0},
    取得日 = Table.SelectRows(パラメータ, each([項目] = "取得日"))[値]{0},
    ソース = Folder.Files(保管フォルダ)
    取得日のファイル一覧 = Table.SelectRows(ソース, each Text.Contains([Folder Path], ホスト名) and Text.Contains([Folder Path], 取得日) and [Attribute]?[Size]>0)
in
    取得日のファイル一覧
```

#### f_テーブルに変換

```powerquery
let
    テーブルに変換 = (対象ファイル as binary) =>
    let
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
    データ抽出 = (処理対象ファイル名の先頭文字列 as text) =>
    let
        処理対象ファイル一覧 = Table.SelectRows(q_取得日のファイル一覧, each Text.StartsWith([Name], 処理対象ファイル名の先頭文字列)),
        処理対象ファイル一覧_内容追加 = Table.AddColumn(処理対象ファイル一覧, "テーブル", each f_テーブルに変換([Content])),
        処理対象ファイル一覧_列名変更 = Table.RenameColumns(処理対象ファイル一覧_内容追加, {"Name", "Source.Name"}),
        処理対象ファイル一覧_列選択 = Table.SelectColumns(処理対象ファイル一覧_列名変更, {"Source.Name", "テーブル"}),
        テーブル = Table.ExpandTableColumn(処理対象ファイル一覧_列選択, "テーブル", Table.ColumnNames(Table.LastN(処理対象ファイル一覧_列選択, 1)[テーブル]{0})),
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
    ソース = f_データ抽出("sar_-r"),
    型変更 = Table.TransformColumnTypes(ソース, {{"timestamp", type datetime}, {"kbmemfree", type number}, {"kbmemused", type number}, {"%memused", type number}, {"kbcommit", type number}, {"%commit", type number}})
in
    型変更
```

#### q_ロードアベレージ

```powerquery
let
    ソース = f_データ抽出("sar_-q"),
    型変更 = Table.TransformColumnTypes(ソース, {{"timestamp", type datetime}, {"runq-sz", type number}, {"plist-sz", type number}, {"ldavg-1", type number}, {"ldavg-5", type number}, {"ldavg-15", type number}, {"blocked", type number}})
in
    型変更
```

#### q_CPU使用状況

```powerquery
let
    ソース = f_データ抽出("sar_-u"),
    型変更 = Table.TransformColumnTypes(ソース, {{"timestamp", type datetime}, {"%user", type number}, {"%nice", type number}, {"%system", type number}, {"%iowait", type number}, {"%steal", type number}, {"%idle", type number}, {"CPU", Int64.Type}})
in
    型変更
```

#### q_HDD帯域幅使用状況

```powerquery
let
    ソース = f_データ抽出("sar_-dp"),
    型変更 = Table.TransformColumnTypes(ソース, {{"timestamp", type datetime}, {"DEV", type number}, {"tps", type number}, {"rkB/s", type number}, {"wkB/s", type number}, {"dkB/s", type number}, {"areq-sz", type number}, {"aqu-sz", type number}, {"await", type number}, {"%util", type number}})
in
    型変更
```

#### q_ネットワーク使用状況

```powerquery
let
    ソース = f_データ抽出("sar_-n_DEV"),
    型変更 = Table.TransformColumnTypes(ソース, {{"timestamp", type datetime}, {"rxpck/s", type number}, {"txpck/s", type number}, {"rxkB/s", type number}, {"txkB/s", type number}, {"rxcmp/s", type number}, {"txcmp/s", type number}, {"rxmcst/s", type number}, {"%ifutil", type number}})
    ソート = Table.Sort(型変更, {{"timestamp", Order.Ascending}, {"IFACE", Order.Ascending}})
in
    ソート
```

#### q_ネットワークソケット使用状況

```powerquery
let
    ソース = f_データ抽出("sar_-n_SOCK"),
    型変更 = Table.TransformColumnTypes(ソース, {{"timestamp", type datetime}, {"totsck", Int64.Type}, {"tcpsck", Int64.Type}, {"udpsck", Int64.Type}, {"rawsck", Int64.Type}, {"ip-frag", Int64.Type}, {"tcp-tw", Int64.Type}})
in
    型変更
```

#### q_コンテキストスイッチ状況

```powerquery
let
    ソース = f_データ抽出("sar_-w"),
    型変更 = Table.TransformColumnTypes(ソース, {{"timestamp", type datetime}, {"proc/s", type number}, {"cswch/s", type number}})
in
    型変更
```

#### q_スワップ使用状況

```powerquery
let
    ソース = f_データ抽出("sar_-S"),
    型変更 = Table.TransformColumnTypes(ソース, {{"timestamp", type datetime}, {"kbswpfree", Int64.Type}, {"kbswpused", Int64.Type}, {"%swpused", type number}, {"kbswpcad", Int64.Type}, {"%swpcad", type number}})
in
    型変更
```

#### q_ディスク使用状況

```powerquery
let
    ソース = f_データ抽出("sar_-F"),
    型変更 = Table.TransformColumnTypes(ソース, {{"# hostname", type text}, {"timestamp", type datetime}, {"FILESYSTEM", type text}, {"MBfsfree", Int64.Type}, {"MBfsused", Int64.Type}, {"%fsused", type number}, {"%ufsused", type number}, {"Ifree", Int64.Type}, {"Iused", Int64.Type}, {"%Iused", type number}}),
    ソート = Table.Sort(型変更, {{"timestamp", Order.Ascending}, {"FILESYSTEM", Order.Ascending}})
in
    ソート
```
