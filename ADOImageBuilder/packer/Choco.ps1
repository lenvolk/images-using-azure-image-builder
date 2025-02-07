Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco install azure-data-studio -y --no-progress -r
choco install kubernetes-cli -y --no-progress -r
choco install python -y --no-progress -r
choco install sqlserver-cmdlineutils -y --no-progress -r
choco install sql-server-management-studio -y --no-progress -r
choco install grep -y --no-progress -r
choco install googlechrome -y --no-progress -r --ignore-hash --ignore-checksum
choco install powershell-core -y --no-progress -r
