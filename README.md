### General Info

[install Git](https://github.com/git-for-windows/git/releases/download/v2.39.0.windows.2/Git-2.39.0.2-64-bit.exe)

[install vscode](https://code.visualstudio.com/Download)

[Latency Test](https://www.azurespeed.com/Azure/Latency)

[01 provision market place VM](/LenVolk/Scripts/MarketPlaceVMs.ps1)

[02a Add VMs to AD](/LenVolk/Scripts/AD_VMjoin_invoke.ps1)

[02b Add Vms to AAD](/LenVolk/Scripts/001_AADextention_RBAC.ps1)

[03 Add VMs to a hostpool](/LenVolk/Scripts/000_invoke_command.ps1#L57-L75)

[04 adjust fslogix profile](/LenVolk/Scripts/000_invoke_command.ps1#L29-L42)

----
## Images-using-azure-image-builder, sample of the pipeline 
(https://dev.azure.com/chrysalis-innersource/_git/Enterprise-scale%20Azure%20Data%20Factory%20Pipelines?path=/azure-pipelines.yml)

----
## Unlock The Secret of Image Builder
(https://www.youtube.com/watch?v=UEOZsNBjGJc&t=138s)

----
## You've never seen an Image Pipeline like this one | Azure Image Builder
(https://www.youtube.com/watch?v=zIdOutv0doE)


(https://github.com/DeanCefola/Azure-WVD/blob/master/WVDTemplates/WVD-NewHost/AVD-Win11-NewHost.json#L70-L74)

(https://github.com/danielsollondon/azvmimagebuilder/tree/master/solutions/14_Building_Images_WVD)

----
## AAD Joined VM
(https://learn.microsoft.com/en-us/azure/architecture/example-scenario/wvd/azure-virtual-desktop-azure-active-directory-join)

(https://rozemuller.com/how-to-join-azure-ad-automated/)

## Bicep
(https://github.com/fberson/Azure-Virtual-Desktop-as-a-gaming-console)

## AVD LZ
(https://github.com/Azure/avdaccelerator)


## TLS 1.2
[ref doc](https://learn.microsoft.com/en-us/mem/configmgr/core/plan-design/security/enable-tls-1-2-client#configure-for-strong-cryptography)

```powershell
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v2.0.50727' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord

Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
```

## Terraform
[AVD Terraform](https://github.com/lenvolk/Plan-and-Implement-Identity-and-Security-on-AVD)

## Bicep
[AVD Monitoring](https://github.com/jamesatighe/AVD-BICEP/blob/main/Bicep/Monitoring.bicep)