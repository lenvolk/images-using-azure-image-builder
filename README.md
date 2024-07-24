### General Info

[Azure Virtual Desktop for the enterprise](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/wvd/windows-virtual-desktop)

[install Git](https://github.com/git-for-windows/git/releases/download/v2.39.0.windows.2/Git-2.39.0.2-64-bit.exe)

[install vscode](https://code.visualstudio.com/Download)

[Latency Test](https://www.azurespeed.com/Azure/Latency)

[Round-trip latency figures](https://learn.microsoft.com/en-us/azure/virtual-machines/availability-set-overview)

[01 provision market place VM](/LenVolk/Scripts/MarketPlaceVMs.ps1)

[02a Add VMs to AD](/LenVolk/Scripts/AD_VMjoin_invoke.ps1)

[02b Add Vms to AAD](/LenVolk/Scripts/001_AADextention_RBAC.ps1)

[03 Add VMs to a hostpool](/LenVolk/Scripts/000_invoke_command.ps1#L57-L75)

[04 adjust fslogix profile](/LenVolk/Scripts/000_invoke_command.ps1#L29-L42)

----
## Images-using-azure-image-builder, sample of the pipeline 
(https://dev.azure.com/chrysalis-innersource/_git/Enterprise-scale%20Azure%20Data%20Factory%20Pipelines?path=/azure-pipelines.yml)

[AVD Image Creation](https://dev.azure.com/Supportability/WindowsVirtualDesktop/_wiki/wikis/WindowsVirtualDesktop/810747/AVD-Image-Creation)

----
## Unlock The Secret of Image Builder
(https://www.youtube.com/watch?v=UEOZsNBjGJc&t=138s)

----
## You've never seen an Image Pipeline like this one | Azure Image Builder
(https://www.youtube.com/watch?v=zIdOutv0doE)


(https://github.com/DeanCefola/Azure-WVD/blob/master/WVDTemplates/WVD-NewHost/AVD-Win11-NewHost.json#L70-L74)

(https://github.com/danielsollondon/azvmimagebuilder/tree/master/solutions/14_Building_Images_WVD)

----
## Office
[Install Office in shared computer activation mode](https://learn.microsoft.com/en-us/azure/virtual-desktop/install-office-on-wvd-master-image#install-office-in-shared-computer-activation-mode)

----
## AAD Joined VM
(https://learn.microsoft.com/en-us/azure/architecture/example-scenario/wvd/azure-virtual-desktop-azure-active-directory-join)

## AD Hybrid VM SSO
(https://learn.microsoft.com/en-us/azure/virtual-desktop/configure-single-sign-on)

(https://techcommunity.microsoft.com/t5/azure-architecture-blog/setup-hybrid-joined-avd-single-sign-on/ba-p/3643845)

(https://rozemuller.com/how-to-join-azure-ad-automated/)
----
[Sync between two Azure file shares](https://github.com/Azure-Samples/azure-files-samples/tree/master/SyncBetweenTwoAzureFileSharesForDR)
----
## Bicep
(https://github.com/fberson/Azure-Virtual-Desktop-as-a-gaming-console)

----
## AVD LZ
(https://github.com/Azure/avdaccelerator)

----
## AVD Planning

[HowTo](https://techcommunity.microsoft.com/t5/azure-virtual-desktop/azure-virtual-desktop-planning-a-little-guide-please-don-t/m-p/3785144)

[library](https://azure.github.io/Azure-Proactive-Resiliency-Library-v2/azure-specialized-workloads/avd/#implement-a-multi-region-bcdr-plan)
----
## AVD SessionHostReplacer
(https://github.com/Azure/AVDSessionhostreplacer)
----
## TLS 1.2
[ref doc](https://learn.microsoft.com/en-us/mem/configmgr/core/plan-design/security/enable-tls-1-2-client#configure-for-strong-cryptography)

```powershell
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v2.0.50727' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord

Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
```
----
## Terraform
[AVD Terraform](https://github.com/lenvolk/Plan-and-Implement-Identity-and-Security-on-AVD)

----
## Policies
[T-Shooting](https://jloudon.com/cloud/How-To-Win-vs-Azure-Policy-Non-Compliance/)

[Community-Policy](https://github.com/Azure/Community-Policy/tree/master/Policies/Compute)

[Azure-Capacity-Reservations-with-Automatic-Consumption](https://techcommunity.microsoft.com/t5/azure-compute-blog/azure-capacity-reservations-with-automatic-consumption/ba-p/4193167)
----
## Bicep
[AVD Monitoring](https://github.com/jamesatighe/AVD-BICEP/blob/main/Bicep/Monitoring.bicep)

----
### Azure Network Security
https://mslearn.cloudguides.com/guides/Azure%20network%20security

----
## Monitoring & Alerting
[Alerts](https://github.com/JCoreMS/AVDAlerts)

----
## Debugging Azure Virtual Desktop - WorkBook
[Link](https://blog.itprocloud.de/AVD-Azure-Virtual-Desktop-Error-Drill-Down-Workbook/)

----
[Azure Virtual Desktop Experience Estimator](https://azure.microsoft.com/en-us/products/virtual-desktop/assessment/#estimation-tool)
----
## CheckList
[AVD Check List](https://github.com/Azure/review-checklists)

----
## FinOps
[The Azure FinOps Guide](https://techcommunity.microsoft.com/t5/fasttrack-for-azure/the-azure-finops-guide/ba-p/3704132)

[Cut out waste with Monitoring WorkBook](https://github.com/dolevshor/azure-orphan-resources)

----
## Labs
[Zero Trust Lab](https://ztlabguide.com/)

----
## Entra ID Export Scripts
[Repo](https://github.com/debaxtermsft/debaxtermsft/tree/main)
