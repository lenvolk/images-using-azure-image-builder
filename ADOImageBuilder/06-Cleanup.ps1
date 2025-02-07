$refVmRg = 'ImageRefRG' 
$CompGalRg = "CompGalRG"

Remove-AzResourceGroup -Name $refVmRg -Verbose -Force
Remove-AzResourceGroup -Name $CompGalRg -Verbose -Force
