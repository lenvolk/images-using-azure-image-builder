Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose

$sa_name = [Environment]::GetEnvironmentVariable('sa_name')
$sa_key = [Environment]::GetEnvironmentVariable('sa_key')
# $fslogix_share = [Environment]::GetEnvironmentVariable('fslogix_share')

# $tst = "cmdkey /add:`"$sa_name.file.core.windows.net`" /user:`"Azure\$sa_name`" /pass:`"$sa_key`""
# $tst | Out-File -FilePath "c:\buildInformation.txt"


$connectTestResult = Test-NetConnection -ComputerName imageartifactsa01.file.core.windows.net -Port 445
#$connectTestResult = Test-NetConnection -ComputerName $sa_name.file.core.windows.net -Port 445
if ($connectTestResult.TcpTestSucceeded) {
    # Save the password so the drive will persist on reboot
    cmd.exe /C "cmdkey /add:`"$sa_name.file.core.windows.net`" /user:`"Azure\$sa_name`" /pass:`"$sa_key`""
    # Mount the drive
    New-PSDrive -Name Z -PSProvider FileSystem -Root "\\$sa_name.file.core.windows.net\packages" -Persist
}
else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}


mkdir C:\installers -Force
Copy-Item Z:\* C:\installers\ -Recurse