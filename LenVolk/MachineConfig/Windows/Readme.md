# Guide: Authoring and Deploying Custom Azure Machine Configuration Policies with PowerShell

This guide explains how to create, test, and deploy custom Azure Machine Configuration policies using PowerShell, based on the provided video demonstration.

## I. Understand the Prerequisites

# References

- [Azure Machine Configuration Overview](https://learn.microsoft.com/en-us/azure/governance/machine-configuration/overview)

## Prerequisites

- [Deploy requirements for Azure Virtual Machines](https://learn.microsoft.com/en-us/azure/governance/machine-configuration/overview#deploy-requirements-for-azure-virtual-machines)
- Initiative: **"Deploy prerequisites to enable Guest Configuration policies on virtual machines"**

Before you begin, ensure the following are in place:

1.  **Guest Configuration Extension Enabled:** The Azure Guest Configuration (
Azure Machine Configuration extension for Windows ) extension must be active in your Azure environment.
    *   **Recommendation:** Deploy the prerequisite initiative via Azure Policy.
2.  **Latest GuestConfiguration PowerShell Module:** Install the most recent version of the `GuestConfiguration` PowerShell module on your authoring machine.
3.  **Desired State Configuration (DSC) Resources:** You'll need the relevant DSC resources for the settings you wish to manage.
4.  **Storage Account Access:** A storage account (e.g., Azure Blob Storage) is required to host the configuration package (`.zip` file).
    *   If using private storage, a user-assigned managed identity with appropriate permissions will be necessary for the Guest Configuration agent to access the package.

## II. Authoring and Testing the Custom Configuration

*(The presenter uses Visual Studio Code for these steps).*

### Step 1: Create the DSC Configuration File (e.g., `1timeZoneConfig.ps1`)

This script defines the desired state for your target machines.

*   **Objective:** Define the machine's desired time zone.
*   **Action:**
    1.  Create a new PowerShell script file (`.ps1`).
    2.  Define a `Configuration` block. Example: `TimeZoneCustom`.
    3.  Import the required DSC resource(s). For time zone management:
        ```powershell
        Import-DscResource -ModuleName ComputerManagementDsc -Name TimeZone
    4.  Define the resource block with the specific settings. Example for "Eastern Standard Time":
        ```powershell
        Configuration TimeZoneCustom {
            Import-DscResource -ModuleName ComputerManagementDsc -Name TimeZone
            TimeZone TimeZoneConfig {
                TimeZone = 'Eastern Standard Time'
                IsSingleInstance = 'Yes' # Ensures only one time zone setting is applied
            }
        }
        TimeZoneCustom # Invokes the configuration to compile it
    5.  Execute this script. It will compile the DSC configuration and generate a `.mof` file (e.g., `localhost.mof`) located in a subfolder named after your configuration (e.g., `.\TimeZoneCustom\localhost.mof`).

### Step 2: Create the Guest Configuration Package (e.g., `2timeZonePackage.ps1`)

This script packages the compiled `.mof` file into a `.zip` archive for the Guest Configuration agent.

*   **Objective:** Bundle the `.mof` file into a deployable package.
*   **Action:**
    1.  Create a new PowerShell script.
    2.  Define a hashtable of parameters for the `New-GuestConfigurationPackage` cmdlet:
        ```powershell
        $params = @{
            Name          = 'TimeZone'  # Name for your configuration package
            Configuration = '.\TimeZoneCustom\localhost.mof' # Path to the generated .mof file
            Type          = 'AuditAndSet' # Or 'Audit'
            Force         = $true         # Overwrites if the package already exists
        }
        New-GuestConfigurationPackage @params
        ```
        *   **`Type` parameter:**
            *   `'AuditAndSet'`: Checks for compliance and enforces the configuration if the machine is non-compliant.
            *   `'Audit'`: Only checks and reports compliance status without making changes.
    3.  Run this script. This will produce a `.zip` file (e.g., `TimeZone.zip`) in your current working directory.

### Step 3: Test the Configuration Package Locally (e.g., `3timeZoneTest.ps1`)

Before deploying to Azure, validate the package's behavior on a local machine or a designated test environment.

*   **Objective:** Verify the package functions as intended.
*   **Action:**
    1.  Create a new PowerShell script.
    2.  **Check Compliance (Get):** Use the `Get-GuestConfigurationPackageComplianceStatus` cmdlet to assess if the current machine aligns with the package's defined state.
        ```powershell
        # Test Get function
        Get-GuestConfigurationPackageComplianceStatus .\TimeZone.zip -Verbose
        ```
        This command outputs compliance details, including a `complianceStatus` (True/False).
    3.  **Apply Remediation (Set):** If the machine is not compliant and you want to apply the settings (and your package `Type` is `AuditAndSet`), use `Start-GuestConfigurationPackageRemediation`.
        ```powershell
        # Test Set function
        Start-GuestConfigurationPackageRemediation .\TimeZone.zip -Verbose
        ```
        After execution, the machine's configuration (e.g., time zone) should reflect the settings in the package.
    4.  Re-run `Get-GuestConfigurationPackageComplianceStatus` to confirm that `complianceStatus` is now `True`.

## III. Deploying the Configuration Policy to Azure

### Step 4: Publish the Package and Create the Azure Policy Definition (e.g., `6timeZonePolicy.ps1`)

This step involves uploading your package to a location accessible by Azure and then defining the Azure Policy that will use this package.

*   **Objective:** Make the configuration package accessible to Azure and define a policy to enforce it.
*   **Action:**
    1.  **Upload Package:** Upload the generated `.zip` package (e.g., `TimeZone.zip`) to:
        *   A publicly accessible URI.
        *   Azure Blob Storage. (If private, ensure your user-assigned managed identity has read access).
        *   Note down the URI of the uploaded package (`contentUri`).
    2.  Create a PowerShell script to define and create the Azure Policy.
    3.  **Define Policy Parameters:** Prepare parameters for the `New-GuestConfigurationPolicy` cmdlet:
        ```powershell
        $PolicyConfig = @{
            PolicyId                 = (New-Guid).Guid # Or a predefined GUID
            ContentUri               = 'YOUR_BLOB_STORAGE_URI/TimeZone.zip' # URI of your uploaded package
            DisplayName              = 'Windows TimeZone EST Policy'
            Description              = 'AuditAndSet to ensure VMs are set to Eastern Standard Time.'
            Path                     = '.\policies' # Local directory to save generated policy files
            Platform                 = 'Windows' # Can be 'Windows' or 'Linux'
            PolicyVersion            = '1.0.0'
            Mode                     = 'ApplyAndAutoCorrect' # Other options: 'Audit', 'ApplyAndMonitor'
            LocalContentPath         = 'C:\path\to\your\local\TimeZone.zip' # Path to the local .zip for hash generation
            ManagedIdentityResourceId = '$ManagedIdentityResourceId' # Optional: Resource ID of the user-assigned managed identity if using private storage
        }
        New-GuestConfigurationPolicy @PolicyConfig # Add -ExcludeArcMachines if MI is used and Arc support for it is limited for this scenario
        ```
        *   **`LocalContentPath`:** This is crucial for generating a hash of the package to ensure the integrity of the content deployed.
        *   **`ManagedIdentityResourceId` & `-ExcludeArcMachines`:** Only include these if your package is in private storage requiring a managed identity for access. `-ExcludeArcMachines` might be needed if the managed identity feature for guest configuration on Arc machines has limitations.
    4.  Running `New-GuestConfigurationPolicy` will generate JSON files for the Azure Policy definition (e.g., `auditIfNotExists.json`, `deployIfNotExists.json`) and an initiative definition in the directory specified by `Path`.
    5.  **Create Policy Definition(s) in Azure:** Use the `New-AzPolicyDefinition` cmdlet to upload the generated policy JSON file(s) to Azure.
        ```powershell
        New-AzPolicyDefinition -Name 'TimeZone_DeployIfNotExists' -Policy '.\policies\deployIfNotExists.json'
        New-AzPolicyDefinition -Name 'TimeZone_AuditIfNotExists' -Policy '.\policies\auditIfNotExists.json'
        # You can also create an initiative using New-AzPolicySetDefinition
        ```
    6.  After execution, the new policy definitions will be available in the Azure portal under Policy > Definitions.

### Step 5: Assign the Azure Policy

*   **Objective:** Apply your custom configuration policy to the desired Azure resources.
*   **Action:**
    1.  Navigate to **Policy > Assignments** in the Azure portal.
    2.  Click **Assign policy** (or **Assign initiative**).
    3.  Select the custom policy definition you created in the previous step.
    4.  Define the **Scope** (e.g., Management Group, Subscription, Resource Group) where this policy should be enforced.
    5.  Configure any **Parameters** that your policy definition might expose (e.g., if you made the time zone value a parameter).
    6.  If your policy uses a `deployIfNotExists` or `modify` effect, you may need to create a **Remediation task** to bring existing non-compliant resources into compliance.

By following these steps, you can effectively create, test, and deploy custom machine configurations across your Azure and Azure Arc-enabled servers.