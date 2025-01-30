function New-Sp {
    param($Name, $Password)
  
    $spParams = @{ 
      StartDate = Get-Date
      EndDate = Get-Date -Year 2030
      Password = $Password
    }
  
    $cred= New-Object Microsoft.Azure.Commands.ActiveDirectory.PSADPasswordCredential -Property $spParams
    $sp = New-AzAdServicePrincipal -DisplayName $Name -PasswordCredential $cred
  
    Write-Output $sp
  }


  # New-Sp -Name AZSP -Password P@ssw0rd2020