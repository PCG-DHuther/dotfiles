
Using namespace System.Management.Automation

#region Cursor Beacon
# https://www.tenforums.com/tutorials/101584-turn-off-show-pointer-location-ctrl-key-windows.html#post2441622
function Get-UserPreferencesMask {

    [CmdletBinding()] [OutputType([Byte[]])] Param()

    [Hashtable]$userPreferencesMask = @{
        Path        = 'Registry::HKEY_CURRENT_USER\Control Panel\Desktop'
        Name        = 'UserPreferencesMask'
        ErrorAction = [ActionPreference]::Stop
    }

    Try { Get-ItemPropertyValue @userPreferencesMask } Catch {
        Throw "Failed to get UserPreferencesMask from registry: $_"
    }
}

function Set-UserPreferencesMask {

    [CmdletBinding()] [OutputType([Void])]

    Param(
        [Parameter(Mandatory)]
        [ValidateScript({

            })]
        [Byte[]]$InputObject)

    [Hashtable]$userPreferencesMask = @{
        Force       = $true
        Path        = 'Registry::HKEY_CURRENT_USER\Control Panel\Desktop'
        Name        = 'UserPreferencesMask'
        Value       = $InputObject
        ErrorAction = [ActionPreference]::Stop
    }

    Try { Set-ItemProperty @userPreferencesMask } Catch {
        Throw "Failed to set UserPreferencesMask: $_"
    }
}

function Enable-CursorBeacon {

    [CmdletBinding()] [OutputType([Void])] Param()

    [Byte[]]$newMask = Get-UserPreferencesMask
    $newMask[1] = $newMask[1] -bor 0x40
    Set-UserPreferencesMask -InputObject $newMask
}

function Disable-CursorBeacon {

    [CmdletBinding()] [OutputType([Void])] Param()

    [Byte[]]$newMask = Get-UserPreferencesMask
    $newMask[1] = $newMask[1] -band -bnot 0x40
    Set-UserPreferencesMask -InputObject $newMask
}
#endregion Cursor Beacon

[Hashtable]$ea = @{ErrorAction = [ActionPreference]::SilentlyContinue }
$regControlPanel = 'HKCU:\Control Panel'
$regWindows = 'HKCU:\Software\Microsoft\Windows\CurrentVersion'
$regExplorerAdvanced = "$regWindows\Explorer\Advanced"
$regContentDelivery = "$regWindows\ContentDeliveryManager"
$regUserProfileEngagement = "$regWindows\UserProfileEngagement"
$regAdvertisingInfo = "$regWindows\AdvertisingInfo"
$regPrivacy = "$regWindows\Privacy"

#Set-ItemProperty -Name 'RealTimeIsUniversal' -Value 1 -Type DWord-Path -Path "HKLM:\System\CurrentControlSet\Control\TimeZoneInformation'" # Make Windows treat hardware clock as UTC (example use case: dual boot with Linux)
Set-TimeZone -Id 'Central Standard Time'
Start-Process -Wait -FilePath wt32m.exe -ArgumentList '/resync'

# Set short date format to ISO 8601 (YYYY-MM-DD)
Set-ItemProperty -Path "$regControlPanel\International" -Name 'sShortDate' -Value 'yyyy-MM-dd'
# As of 2025-11, this affects the format of Obsidian's Date properties. It may be controllable separately in the future.

# Disable Sticky Keys trigger
Set-ItemProperty -Path "$regControlPanel\Accessibility\StickyKeys" -Name 'Flags' -Value 498
# Change what closing the lid does (do nothing)
Foreach ($s in @('setacvalueindex', 'setdcvalueindex')) {
    Start-Process -FilePath powercfg.exe -ArgumentList "-$s SCHEME_ALL SUB_BUTTONS LIDACTION 0"
}

# Show location of pointer when I press CTRL key
Enable-CursorBeacon

# https://www.elevenforum.com/t/disable-ads-in-windows-11.8004/
Set-ItemProperty @ea -Path $regExplorerAdvanced -Name ShowSyncProviderNotifications -Value 0         # Sync provider notifications in File Explorer
Set-ItemProperty @ea -Path $regExplorerAdvanced -Name Start_IrisRecommendations -Value 0             # Show recommendations for tips, shortcuts, new apps, and more on Start Menu
#Set-ItemProperty @ea -Path $regExplorerAdvanced -Name Start_AccountNotifications -Value 0           # Show Microsoft account-related notifications on Start Menu
Set-ItemProperty @ea -Path $regContentDelivery -Name 'RotatingLockScreenOverlayEnabled' -Value 0     # Get fun facts, tips, tricks, and more on your lock screen
Set-ItemProperty @ea -Path $regContentDelivery -Name 'SubscribedContent-338387Enabled' -Value 0      # | -
Set-ItemProperty @ea -Path $regContentDelivery -Name 'SubscribedContent-338393Enabled' -Value 0      # Show suggested content in Settings app
Set-ItemProperty @ea -Path $regContentDelivery -Name 'SubscribedContent-353694Enabled' -Value 0      # | -
Set-ItemProperty @ea -Path $regContentDelivery -Name 'SubscribedContent-353696Enabled' -Value 0      # | -
Set-ItemProperty @ea -Path $regContentDelivery -Name 'SubscribedContent-338389Enabled' -Value 0      # Get tips and suggestions when using Windows
Set-ItemProperty @ea -Path $regContentDelivery -Name 'SubscribedContent-310093Enabled' -Value 0      # Show me the Windows welcome experience after updates and occasionally when I sign in to highlight what's new and suggested
Set-ItemProperty @ea -Path $regUserProfileEngagement -Name 'ScoobeSystemSettingEnabled' -Value 0     # Suggest ways to get the most out of Windows and finish setting up this device
Set-ItemProperty @ea -Path $regAdvertisingInfo -Name 'Enabled' -Value 0                              # Let apps show me personalized ads by using my advertising ID
Set-ItemProperty @ea -Path $regPrivacy -Name 'TailoredExperiencesWithDiagnosticDataEnabled' -Value 0 # Tailored experiences

Set-ItemProperty @ea -Path $regExplorerAdvanced -Name PersistantWindowPositions -Value 1             # Remember window positions
Set-ItemProperty @ea -Path $regExplorerAdvanced -Name DontPrettyPath -Value 1                        #

# ? Disable "When I snap a window, suggest what I can snap next to it" ?
# ? Disable "When I drag a window, let me snap it without dragging it all the way to the screen edge" ?
# Disable "Title bar window shake"