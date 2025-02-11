remote-exec
===========

```
+---001_task/
|   +---in/
|   |   +---main.sh
|   +---out/
|   |   +---{CC}/
|   |       +---{SS}/
|   |           +---{SITE}/
|   |               +---{HOSTNAME}/
|   |                   +---{YYYYMMDD}/
|   +---main.cmd
|   +---make_result.cmd
|   +---make_result.ps1
+-- sceipt/
    +---main.ps1
    +---main.scp
    +---hosts.csv
    +---users.csv
```

### 暗号化パスワードファイル生成

```ps1
$cred = Get-Credential
$user = $cred.UserName
$pass = $cred.Password = ConvertFrom-SecureString -Key (1..16)
"NA,$user,$pass" | Out-File users.csv -Encoding OEM -Append
```

