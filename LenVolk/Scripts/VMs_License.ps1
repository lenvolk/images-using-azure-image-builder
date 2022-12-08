
$VMRG = "imageBuilderRG"
$LicenseVMs = (get-azvm -ResourceGroupName $VMRG -Status) | Where-Object { $_.LicenseType -ne "Windows_Client" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 


    foreach($LicenseVM in $LicenseVMs){
       

        # Assign the machine to use 'Windows_Client' license type
        # This license type applies Azure Hybrid Benefits
        $LicenseVM.LicenseType = 'Windows_Client'

        # Update the VM configuration
        Update-AzVM -ResourceGroupName $VMRG -VM $LicenseVM
    }
