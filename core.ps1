#Requires -PSEdition Core

#region functions
function Register-MasterPackager {
    [CmdletBinding()]

    Param(
        [Parameter(Mandatory)][MailAddress]$UserPrincipalName,
        [Parameter(Mandatory)][String]$LicenseKey
    )

    Foreach ($p in "${env:ProgramFiles(x86)}\Master Packager Ltd\Master Packager\mrp.exe") {
        If (Test-Path -Path $p) {
            & $p activate -email $UserPrincipalName -licensekey $LicenseKey -allusers
        } Else {
            Write-Error -Message "The path '$p' does not exist."
        }
    }
}
#endregion functions

# Install ModuleFast
Invoke-WebRequest -Uri bit.ly/modulefast | Invoke-Expression


$psgallery = @{
    AcceptLicense = $true
    Scope         = 'CurrentUser'
    Repository    = 'PSGallery'
}

$resourceList = @(
    'CredentialManager'
    'Ctypes'
    'Evergreen'
    #'ExcelFast'
    'ImpliedReflection'
    'ImportExcel'
    'IntuneStuff' #?
    'LocalMDM'
    'Microsoft.Graph'
    'Microsoft.PowerShell.SecretManagement'
    'ModuleBuilder'
    'Pester'
    'PoshTypes'
    'platyPS'
    'PSAppDeployToolkit'
    'PSAppDeployToolkit.Tools'
    'PSClassUtils'
    'PSCSharpInvoker'
    'PSDetour'
    'PSScriptAnalyzer'
    'PSWindowsUpdate'
    'SecretManagement.Keeper'
    'TeamViewerPS'
)

Install-Module @psgallery -Force -Name Microsoft.PowerShell.PSResourceGet
Foreach ($m in $resourceList) { Install-PSResource -Name $m -TrustRepository @psgallery }
<#
ah shoot, Secret Management won't work on 5.1
get MP license key from Keeper Secret Management
#>
Register-MasterPackager -UserPrincipalName $(& whoami /upn) -LicenseKey ''