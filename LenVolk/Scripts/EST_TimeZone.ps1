$tzName = "Eastern Standard Time"  
$estDateTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date), $tzName)
($estDateTime -split " " | select -First 1) -replace "/", "-"