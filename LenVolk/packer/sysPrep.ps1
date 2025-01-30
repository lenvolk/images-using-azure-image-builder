# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose

if (Test-Path $Env:SystemRoot\\windows\\system32\\Sysprep\\unattend.xml) {
    Remove-Item $Env:SystemRoot\\windows\\system32\\Sysprep\\unattend.xml -Force
}

# Launch Sysprep
Write-Host "We'll now launch Sysprep."
C:\Windows\System32\Sysprep\Sysprep.exe /generalize /shutdown /oobe /mode:vm 


while ($true) {
    $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select-Object ImageState
    if ($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') {
        Write-Output $imageState.ImageState
        Start-Sleep -s 10
    }
    else { break }
}

# pkr-Resource-Group-7cg1v4g9yv