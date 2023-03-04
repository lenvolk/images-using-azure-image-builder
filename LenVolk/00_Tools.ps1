
#######################################
#     Create VNET and Subnet          #
#######################################
$RGname = "maintenance"
$location = "eastus2"
$VNETName="maintenanceVNET"
$SubnetName="MainSubnet"

$RGScope = (az group create -n $RGname -l $location --query id -o tsv)

az network vnet create --resource-group $RGname --address-prefixes 10.150.0.0/24 --name $VNETName `
                                                --subnet-prefixes 10.150.0.0/28 --subnet-name $SubnetName 
# # Disable Private Link Policy
# az network vnet subnet update --name $SubnetName --resource-group $RGname --vnet-name $VNETName `
#                               --disable-private-link-service-network-policies true 
# Retrieve the ID of that Subnet
$SubnetId = (az network vnet subnet show --resource-group $RGname --vnet-name $VNETName --name=$SubnetName --query id -o tsv)

#######################################
#              Create VM              #
#######################################
##########################################################################
# Get-AzVMImageSku -Location eastus2 -PublisherName MicrosoftWindowsDesktop -Offer office-365 | select Skus | Where-Object { $_.Skus -like 'win11*'}
# Get-AzVmImageSku -Location eastus2 -PublisherName 'MicrosoftWindowsDesktop' -Offer 'Windows-11'| Select Skus #!!! Only the -avd are multi-session
# az vm image list --publisher MicrosoftWindowsDesktop --sku g2 --output table --all
##########################################################################

$image = "MicrosoftWindowsDesktop:Windows-11:win11-22h2-avd:latest"
$vmName = "maintenanceVM"
$storageSku = "StandardSSD_LRS"
$size = "Standard_B2ms"
$VM_User = "vmadmin"
$WinVM_Password = "P@ssw0rdP@ssw0rd"
$securePassword = ConvertTo-SecureString $WinVM_Password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($VM_User, $securePassword)
# 
$VMIP = ( az vm create --resource-group $RGname --name $vmName `
                    --admin-username $VM_User --admin-password $WinVM_Password `
                    --image $image --location $location --public-ip-sku Standard `
                    --nsg '""' `
                    --size $size `
                    --storage-sku $storageSku `
                    --tags 'Owner=LenVolk' `
                    --license-type 'Windows_Client' `
                    --query publicIpAddress -o tsv
                    )

# Check out VMs
az vm list -g $RGname -o table
# Get disk size
# az vm show --resource-group $RGname --name $vmName --query storageProfile.osDisk.diskSizeGb
# Connect to VM
cmdkey /generic:$VMIP /user:$VM_User /pass:$WinVM_Password
mstsc /v:$VMIP /w:1600 /h:1200

# az group delete -g $RGname --yes --no-wait

#######################################
#        Installing Tools             #
#######################################

# install Git
# https://github.com/git-for-windows/git/releases/download/v2.39.0.windows.2/Git-2.39.0.2-64-bit.exe
# PowerShell Versions
# https://github.com/PowerShell/PowerShell/releases/tag/v7.2.9
# Bicept
# https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install

$PSVersionTable.PSVersion
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
# # Download and install chocolatey
# https://learn.microsoft.com/en-us/mem/configmgr/core/plan-design/security/enable-tls-1-2-client#configure-for-strong-cryptography
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v2.0.50727' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
# Install VSCode and Azure CLI
choco install vscode -y
choco install azure-cli -y
# choco install powershell-core --pre 
# choco install git
choco install bicep -y
# Install PowerShell Azure Modules Accounts & Resources
Install-Module -Name Az -AllowCLobber -Verbose -Confirm:$false
Import-Module -Name Az -Verbose
Install-Module AzureAd -AllowClobber -Verbose -Confirm:$false
# also in PS 5.1.x
Install-Module AzureAd -AllowClobber -Verbose -Confirm:$false
# now back in VSCode
Import-Module AzureAD -Verbose -UserWindowsPowerShell


# Install the VSCode extension from CMD
# code --list-extensions | % { "code --install-extension $_" }

code --install-extension 1tontech.angular-material
code --install-extension 4ops.terraform
code --install-extension akamud.vscode-theme-onedark
code --install-extension alefragnani.project-manager
code --install-extension Angular.ng-template
code --install-extension azemoh.one-monokai
code --install-extension bbenoist.shell
code --install-extension christian-kohler.npm-intellisense
code --install-extension christian-kohler.path-intellisense
code --install-extension CoenraadS.bracket-pair-colorizer-2
code --install-extension dai-shi.vscode-es-beautifier
code --install-extension dannysteenman.cloudformation-yaml-snippets
code --install-extension dbaeumer.vscode-eslint
code --install-extension eamodio.gitlens
code --install-extension eg2.vscode-npm-script
code --install-extension Equinusocio.vsc-community-material-theme
code --install-extension Equinusocio.vsc-material-theme
code --install-extension equinusocio.vsc-material-theme-icons
code --install-extension esbenp.prettier-vscode
code --install-extension fivethree.vscode-ionic-snippets
code --install-extension GrapeCity.gc-excelviewer
code --install-extension hashicorp.terraform
code --install-extension HookyQR.beautify
code --install-extension ionic-preview.ionic-preview
code --install-extension jasonnutter.search-node-modules
code --install-extension jchannon.csharpextensions
code --install-extension johnpapa.Angular2
code --install-extension leizongmin.node-module-intellisense
code --install-extension marvhen.reflow-markdown
code --install-extension ms-azuretools.vscode-azureterraform
code --install-extension ms-azuretools.vscode-bicep
code --install-extension ms-dotnettools.csharp
code --install-extension ms-dotnettools.vscode-dotnet-runtime
code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
code --install-extension ms-vscode.azure-account
code --install-extension ms-vscode.azurecli
code --install-extension ms-vscode.powershell
code --install-extension msazurermtools.azurerm-vscode-tools
code --install-extension redhat.vscode-yaml
code --install-extension rogalmic.bash-debug
code --install-extension rosshamish.kuskus-kusto-syntax-highlighting
code --install-extension run-at-scale.terraform-doc-snippets
code --install-extension samuelcolvin.jinjahtml
code --install-extension Shan.code-settings-sync
code --install-extension sohamkamani.code-eol
code --install-extension SolarLiner.linux-themes
code --install-extension streetsidesoftware.code-spell-checker
code --install-extension thenikso.github-plus-theme
code --install-extension tinkertrain.theme-panda
code --install-extension tombonnike.vscode-status-bar-format-toggle
code --install-extension usernamehw.errorlens
code --install-extension vscode-icons-team.vscode-icons
code --install-extension waderyan.nodejs-extension-pack
