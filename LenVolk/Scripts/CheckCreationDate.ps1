# Ref https://github.com/johnthebrit/RandomStuff/blob/master/AzureVMs/CheckCreationDate.ps1



$token = Get-AzAccessToken #This will default to Resource Manager endpoint
$authHeader = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $token.Token
}

$subid = 'f043b87b-e870-4884-b2d1-d665cc58f247'

$r2 = Invoke-RestMethod -Uri https://management.azure.com/subscriptions/$subid/providers/Microsoft.Compute/locations/southcentralus/virtualMachines?api-version=2022-03-01 `
    -Method GET -Headers $authHeader

foreach($value in $r2.value)
{
    Write-Output "$($value.name) - $($value.properties.timeCreated)"
}