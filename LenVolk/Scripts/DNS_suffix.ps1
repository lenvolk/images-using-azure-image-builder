#REF https://eddiejackson.net/lab/2022/03/08/powershell-add-dns-suffix-to-ethernet-connections/

#ipconfig /flushdns

Param (
    [string]$DnsSufix
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