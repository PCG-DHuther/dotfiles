Using namespace Security.Principal

# Self-elevate the script if required
If (-not ([WindowsPrincipal] [WindowsIdentity]::GetCurrent()).IsInRole([WindowsBuiltInRole] 'Administrator')) {

    If ([Int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {

        [Hashtable]$rerunElevated = @{
            Wait       = $true
            FilePath   = 'PowerShell.exe'
            Verb       = 'Runas'
            ArgumentList = "-NoExit -NoProfile -File `"$($MyInvocation.MyCommand.Path)`" $($MyInvocation.UnboundArguments)"
        }
        Start-Process @rerunElevated
        Exit
    }
}

# Enable permission to create symlinks through Developer Mode
# Add-WindowsCapability -Online -Name Tools.DeveloperMode.Core~~~~0.0.1.0 # add Developer Mode features to Windows
# Set-ItemProperty -Force -Name 'AllowDevelopmentWithoutDevLicense' -Value 1 -Type DWord -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' # enable Developer Mode
# DSC can apparently also do this within a winget configuration??

