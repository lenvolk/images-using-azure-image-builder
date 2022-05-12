$aibRG = "imageBuilderRG"
$subscription = "25de1ca2-09a3-42e0-97cc-5fffbc53286f"
$VM_User = "aibadmin"
$WinVM_Password = "P@ssw0rdP@ssw0rd"
$location = "westus2"

$securePassword = ConvertTo-SecureString $WinVM_Password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($VM_User, $securePassword)