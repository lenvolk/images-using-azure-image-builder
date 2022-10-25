Configuration DSCPostConfigV1
{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xDSCDomainjoin'
    Import-DscResource -ModuleName 'SecurityPolicyDSC'
    [pscredential]$credObject = Get-AutomationPSCredential -Name djoincred
    Node localhost
    {
        Script SentinelOne {
            SetScript  = {
                Set-Location "%logonserver%\Temp"
                .\SentinelInstaller-x64_windows_64bit_v4_6_14_304.exe /SITE_TOKEN= $Site_Token /quiet
                sleep -s 180
            }
            TestScript = { 
                $service = Get-Service SentinelAgent -ErrorAction SilentlyContinue 
                if ($service) {
                    return $true
                }
                else {
                    return $false
                }
            }
            GetScript  = {
                return @{'Result' = Get-Service SentinelAgent }
            }
            DependsOn  = "[xDSCDomainjoin]JoinDomain"
        }
        Script App1 {
            SetScript  = {
                Set-Location C:\installers\App1
                $App1setup = "universal.msi"
                $App1cmd = "/i $App1setup /quiet /norestart /l* fe.log"
                start-process -FilePath "msiexec" -ArgumentList $App1cmd -Wait

                sleep -s 60
            }
            TestScript = { 
                if ((Get-Service xagt -ErrorAction SilentlyContinue) -and (Get-Service FEWSCService -ErrorAction SilentlyContinue)) {
                    return $true
                }
                else {
                    return $false
                }
            }
            GetScript  = {
                return @{'Result' = '' }
            }
            DependsOn  = "[xDSCDomainjoin]JoinDomain"

        }
        xDSCDomainjoin JoinDomain
        {
            Domain     = "lvolk.com"
            Credential = $credObject
            JoinOU     = "OU=WVDSessionHosts,DC=lvolk,DC=com"
        }
        Script AddFirewallRule {
            SetScript  = {
                New-NetFirewallRule -DisplayName "TSAgent/5009" -Direction inbound -Profile Any -Action Allow -LocalPort 5009 -Protocol TCP
                Restart-Service -force -Name PanTaService
            }
            TestScript = {  
                if((Get-NetFirewallRule).DisplayName -contains "TSAgent/5009"){
                    return $true
                }
                else {
                    return $false
                }

            }
            GetScript  = {
                return @{'Result' = '' }
            }
        }
        Script LocalAdministrator {
            SetScript  = {
                Add-LocalGroupMember -Group "Administrators" -Member "lvolk\WVDADMIN"
            }
            TestScript = { 
                if ((Get-LocalGroupMember -Group "Administrators").Name -contains "lvolk\WVDADMIN") {
                    return $true
                }
                else {
                    return $false
                }
            }
            GetScript  = {
                return @{'Result' = '' }
            }
            DependsOn  = "[xDSCDomainjoin]JoinDomain"
        }
        Script WVDusers {
            SetScript  = {
                Add-LocalGroupMember -Group "Remote Desktop Users" -Member "lvolk\WVDUsers"
            }
            TestScript = { 
                if ((Get-LocalGroupMember -Group "Remote Desktop Users").Name -contains "lvolk\WVDUsers") {
                    return $true
                }
                else {
                    return $false
                }
            }
            GetScript  = {
                return @{'Result' = '' }
            }
            DependsOn  = "[xDSCDomainjoin]JoinDomain"
        }
        Script RenameGuestAccount {
            SetScript  = {
                $guest = (Get-LocalUser | ? { $_.Description -like "Built-in account for guest access to the computer/domain" }).Name
                Rename-LocalUser -Name $guest -NewName lv777
            }
            TestScript = {  
                if ((Get-LocalUser | ? { $_.Description -like "Built-in account for guest access to the computer/domain" }).Name -ne "lv777") {
                    return $false
                }
                else {
                    return $true
                }
            }
            GetScript  = {
                return @{'Result' = '' }
            }
        }
        Script DisableAdminAccount {
            SetScript  = {
                $user = (Get-LocalUser | ? { $_.Description -like "Built-in account for administering the computer/domain" }).Name
                Disable-LocalUser $user
            }
            TestScript = {  
                if ((Get-LocalUser | ? { $_.Description -like "Built-in account for administering the computer/domain" }).Enabled -ne $false) {
                    return $false
                }
                else {
                    return $true
                }

            }
            GetScript  = {
                return @{'Result' = '' }
            }
        }
        # Script FSLogixPath {
        #     SetScript  = {
        #         New-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles -Name VHDLocations -PropertyType Multistring -Value "\\imagesaaad.file.core.windows.net\avdprofiles\profiles" -Force -Confirm:$false
        #     }
        #     TestScript = {  
        #         if ((Get-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles -Name VHDLocations).VHDLocations -eq "\\imagesaaad.file.core.windows.net\avdprofiles\profiles") {
        #             return $true
        #         }
        #         else {
        #             return $false
        #         }

        #     }
        #     GetScript  = {
        #         return @{'Result' = '' }
        #     }
        # }
        # Script ConfigOneDrive {
        #     SetScript  = {
        #         $shell = New-Object -COM WScript.Shell
        #         $shortcut = $shell.CreateShortcut("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\OneDrive.lnk")
        #         $shortcut.TargetPath = "C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe"
        #         $shortcut.Save()
        #     }
        #     TestScript = {  
        #         $sh = New-Object -ComObject WScript.Shell
        #         $target = $sh.CreateShortcut("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\OneDrive.lnk").TargetPath
        #         if($target -eq "C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe"){
        #             return $true
        #         }
        #         else {
        #             return $false
        #         }

        #     }
        #     GetScript  = {
        #         return @{'Result' = '' }
        #     }
        # }
    }
}