# AAD SA join
# https://learn.microsoft.com/en-us/azure/storage/files/storage-files-identity-auth-azure-active-directory-enable#enable-azure-ad-kerberos-authentication-for-hybrid-user-accounts-preview
#
# New-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles -Name VHDLocations -PropertyType Multistring -Value "\\lvolklab01.file.core.windows.net\labshare\Profiles" -Force -Confirm:$false
New-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles -Name VHDLocations -PropertyType Multistring -Value "\\imagesaaad.file.core.windows.net\avdprofiles\profiles" -Force -Confirm:$false
reg add HKLM\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters /v CloudKerberosTicketRetrievalEnabled /t REG_DWORD /d 1