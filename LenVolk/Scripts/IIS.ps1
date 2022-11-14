Add-WindowsFeature Web-Server
Add-Content -Path "C:\inetpub\wwwroot\Default.htm" -Value $($env:computername)
New-Item -ItemType directory -Path "C:\inetpub\wwwroot\images"
New-Item -ItemType directory -Path "C:\inetpub\wwwroot\video"
$imagevalue = "Images: " + $($env:computername)
Add-Content -Path "C:\inetpub\wwwroot\images\test.htm" -Value $imagevalue   # http://localhost/images/test.htm
$videovalue = "Video: " + $($env:computername)
Add-Content -Path "C:\inetpub\wwwroot\video\test.htm" -Value $videovalue    # http://localhost/video/test.htm