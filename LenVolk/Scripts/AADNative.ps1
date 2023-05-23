# Ref: https://www.youtube.com/watch?v=yJqTJh2Tgxo&t=1s  scroll to 12:00

write-host "Configuring FSLogix"


###################
#    Variables    #
###################
$fileServer="<StorageAccountName>.file.core.windows.net"
$user="localhost\<StorageAccountName>"
$profileShare="\\$($fileServer)\<ProfileShareName>"
$secret="<StorageAccountAccessKey>"


###########################################
#    Execute Command In SYSTEM Context    #
###########################################
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LsaCfgFlags" -Value 0 -force
cmd.exe /c "cmdkey.exe /add:$fileServer /user:$($user) /pass:$($secret)"


################
#    Profile   #
################
New-Item -Path "HKLM:\SOFTWARE" -Name "FSLogix" -ErrorAction Ignore
New-Item -Path "HKLM:\SOFTWARE\FSLogix" -Name "Profiles" -ErrorAction Ignore
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "Enabled" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "VHDLocations" -Value $profileShare -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "ConcurrentUserSessions" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "DeleteLocalProfileWhenVHDShouldApply" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "FlipFlopProfileDirectoryName" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "IsDynamic" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "KeepLocalDir" -Value 0 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "ProfileType" -Value 0 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "SizeInMBs" -Value 30000 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "VolumeType" -Value "VHDX" -force

New-ItemProperty -ErrorAction Stop `
-Path "HKLM:\SOFTWARE\FSLogix\Profiles" `
-Name "AccessNetworkAsComputerObject" `
-Type "Dword" `
-Value "1" `
-Force `
-Confirm:$false

write-host "Configuration Complete"

### PSExec
# downlaod https://learn.microsoft.com/en-us/sysinternals/downloads/psexec
#from CMD elevated 

# PsExec.exe -s cmd.exe /C "cmdkey /add:aadnativesa.file.core.windows.net /user:localhost\aadnativesa /pass:<StorageAccountAccessKey>"

# PsExec.exe /s cmdkey /list

