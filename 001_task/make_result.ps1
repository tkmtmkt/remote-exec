<#
.SYNOPSIS
  取得データを表示する
#>
Get-ChildItem out memory.txt -r | %{
  $path = $_.FullName -split '/'
  $memory = Select-String $_.FullName -Pattern '(kb|Ave)' | %{
    $_.Line -replace ' +',','
  } | ConvertFrom-Csv

  $result = [PSCustomObject]@{
    date = $path[-2]
    cc   = $path[-6]
    ss   = $path[-5]
    site = $path[-4]
    hostname   = $path[-3]
    kbcommit   = $memory.kbcommit
    '%commit'  = $memory.'%commit'
    kbmemused  = $memory.kbmemused
    '%memused' = $memory.'%memused'
    kbbuffers  = $memory.kbbuffers
    kbcached   = $memory.kbcached
  }
  $result
} | Export-Csv "out/result.csv" -NoTypeInformation
