Configuration EnsureNanoNotInstalled
{
    # Import the specific version of PSDscResources module
    # Replace 'X.Y.Z.W' with the actual version you want to use from Get-Module output
    Import-DscResource -ModuleName @{ ModuleName="PSDscResources"; RequiredVersion="2.12.0.0" }

    Node localhost
    {
        nxPackage RemoveNanoEditor
        {
            Name              = 'nano'
            Ensure            = 'Absent'
            PackageManager    = 'Yum'
        }
    }
}