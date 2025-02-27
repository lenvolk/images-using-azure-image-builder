# Install-Module -Name Az -AllowClobber -Force

Connect-AzAccount -Identity
Update-AzConfig -DefaultSubscriptionForLogin "ARC-Demo"

az login --identity
Update-AzConfig -DefaultSubscriptionForLogin "ARC-Demo"