#Ref 
# https://www.youtube.com/watch?v=NtzRiZAJAHw&t=0s
# https://www.youtube.com/watch?v=bqW0ZbcLOaQ&t=313s

winget find vlc #look for "VLC UWP 9NBLGGH4VVNH"

winget find whatsapp #look for "WhatsApp 9NKSQGP7F2NH"

# which ever package starts from 9 is MSIX package 


install-module -name evergreen
import-module evergreen
get-command -module evergreen

find-evergreenapp microsoftterminal
find-evergreenapp vlc | Get-EvergreenApp 
Find-EvergreenApp firefox | Get-EvergreenApp | Where-Object {$_.Type -eq 'MSIX' -and $_.Architecture -eq 'x64'}
# Download the MSIX package https://download-installer.cdn.mozilla.net/pub/firefox/releases/115.6.0esr/win64/multi/Firefox%20Setup%20115.6.0esr.msix
# Doanload MSIXMGR tool https://learn.microsoft.com/en-us/azure/virtual-desktop/app-attach-create-msix-image?tabs=vhdx

cd C:\Temp\msixmgr\x64
.\msixmgr.exe -Unpack -packagePath "C:\Temp\FireFox\Firefox Setup 115.6.0esr.msix" -destination "C:\Temp\FireFox\Firefox.vhdx" -applyACLs -create -fileType vhdx -rootDirectory apps

