

# https://github.com/lenvolk/arc-windowsattest
# Contact cobeyerrett@microsoft.com
Connect-AzAccount -UseDeviceAuthentication

git clone https://github.com/cobeyerrett/arc-windowsattest.git

cd arc-windowsattes

.\attestArcServers.ps1 -subscriptionId "443eed72-f040-41c8-9033-05fe1227bb78" -tenantId "f1ab24dd-6f20-4b55-bc16-074d7aef4641"
