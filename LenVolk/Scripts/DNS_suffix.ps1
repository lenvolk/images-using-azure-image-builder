#REF https://eddiejackson.net/lab/2022/03/08/powershell-add-dns-suffix-to-ethernet-connections/
#
# Add-WindowsCapability -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0 -Online
# Get-Module -Name ActiveDirectory -ListAvailable
# $DnsSufix = $(get-addomain).dnsroot
#
# ncpa.cpl
# Properties
# Internet protocol version 4
# Advanced / DNS
#ipconfig /flushdns

Param (
    [string]$DnsSufix,
    [string]$SAfqdn,
    [string]$SApe
)

Set-DnsClientGlobalSetting -SuffixSearchList @("$DnsSufix")

# SUFFIX TO ADD
$Domain = "$DnsSufix"
 
# ONLY RETURN ETHERNET CONNECTIONS
$Nic = Get-DnsClient | Where-Object -Property InterfaceAlias -Match Ethernet
 
# ADD SUFFIX TO EACH ETHERNET CONNECTION
Foreach ($N in $Nic) {
    Set-DnsClient -ConnectionSpecificSuffix $Domain -InterfaceIndex $N.InterfaceIndex
}

# To update localhostfile
# $SAfqdn = "lvolklab11.file.core.windows.net"
# $SApe = "10.100.40.11"


add-Content -Path $env:windir\System32\drivers\etc\hosts -Value "`n$SApe`t$SAfqdn" -Force
# Get-Content $env:windir\system32\drivers\etc\hosts