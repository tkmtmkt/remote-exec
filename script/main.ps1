<#
.SYNOPSIS
  リモートスクリプト一括実行

.DESCRIPTION
  WinSCPでサーバにスクリプトを転送して実行し、実行結果を取得する処理を
  複数のサーバに対して一括して実行する。

.PARAMETER
  local_dir - 端末側の作業ディレクトリ
  script_file - サーバ上で実行するスクリプト名
  cc_name - 契約区分
  ss_name - サブシステム名
  site_name - 拠点名
  host_name - ホスト名
#>
Param(
  [string]$local_dir,
  [string]$script_file = 'main.sh',
  [ValidateSet("ALL", "XX", "YY", "ZZ")]
  [string]$cc_name = 'ALL',
  [ValidateSet("ALL", "AAA", "BBB", "CCC")]
  [string]$ss_name = 'ALL',
  [ValidateSet("ALL", "MAIN", "SUB")]
  [string]$site_name = 'ALL',
  [string]$host_name = 'ALL'
)
Set-Alias winscp '$($Env:ProgramFiles(x86))\WinSCP\winscp.com'

# スクリプト確認
cd "$local_dir"
$script = Get-Item "in/$script_file" -ErrorAction Stop
$log_file = "$($script.BaseName).log"

# パスワード復号
Function GetPassword($pass) {
  $securePassword = ConvertTo-SecureString $pass -Key (1..16)
  $cred = New-Object System.Management.Automation.PSCredetial "dummy",$securePassword
  $cred.GetNetworkCredential().Password
}

# ホスト情報読み込み
$hosts = Import-Csv "$PSScriptRoot/hosts.csv" -Encoding Default

# ユーザ情報読み込み
$users = @{}
Import-Csv "$PSScriptRoot/users.csv" | %{
  $cc   = $_.CC
  $user = $_.USER
  $pass = $_.PASS
  if ($users[$cc] -eq $null) {
    $users[$cc] = @{}
  }
  $users[$cc][$user] = [PSCustomObject]$_

  # パスワード復号
  $users[$cc][$user].PASS = GetPassword($pass)
}

# コマンド実行
$Env:SCRIPT_FILE = "$script_file"
$Env:LOG_FILE = "$log_file"
$hosts | %{
  if ('ALL', $_.CC -contains $cc_name) {
    if ('ALL', $_.SS -contains $ss_name) {
      if ('ALL', $_.SITE -contains $site_name) {
        if ('ALL', $_.HOSTNAME -contains $host_name) {
          # 接続情報
          $Env:SITE      = $_.SITE
          $Env:HOSTNAME  = $_.HOSTNAME
          $Env:HOSTNAME2 = $_.HOSTNAME2
          $Env:HOSTKEY   = $_.HOSTKEY
          $Env:USER = $users[$_.CC][$_.USER].USER
          $Env:PASS = $users[$_.CC][$_.USER].PASS
          $Env:ROOTPASS = $users[$_.CC]["root"].PASS

          # 作業ディレクトリ、スクリプト
          $Env:WORK_DIR = "work_$(Get-Date -f 'yyyyMMdd')"
          $Env:OUT_DIR  = "out/$($_.CC)/$($_.SS)/$($_.SITE)/$($_.HOSTNAME)/$(Get-Date -f 'yyyyMMdd')"

          "----------------------------------------"
          "SITE        = $($Env:SITE)"
          "HOSTNAME    = $($Env:HOSTNAME)"
          "HOSTNAME2   = $($Env:HOSTNAME2)"
         #"HOSTKEY     = $($Env:HOSTKEY)"
          "USER        = $($Env:USER)"
         #"PASS        = $($Env:PASS)"
         #"ROOTPASS    = $($Env:ROOTPASS)"
          "WORK_DIR    = $($Env:WORK_DIR)"
          "OUT_DIR     = $($Env:OUT_DIR)"
          "SCRIPT_FILE = $($Env:SCRIPT_FILE)"
          "LOG_FILE    = $($Env:LOG_FILE)"
          winscp /script=$PSScriptRoot/main.scp #/log=winscp.log
        }
      }
    }
  }
}
