Using namespace System.Security.Principal

function Test-SessionElevated {

    [CmdletBinding()] [OutputType([Boolean])] Param()

    Return
}

If (-not (Get-Module -ListAvailable -Name Fonts)) {
    Write-Host -Object 'Installing Fonts module from PSGallery...' -ForegroundColor Green
    Find-Module -Name Fonts -Repository PSGallery |
        Where-Object -Property CompanyName -EQ -Value PSModule.io |
        Install-Module -Force -Scope CurrentUser
}
Import-Module -Force -Name Fonts

If (-not (Get-Font -Scope AllUsers -Name 'Delugia*' )) {

    If (-not (Get-Command -Name scoop)) { Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression }
    If (-not (& scoop info git)) { & scoop install git }
    Foreach ($n in 'nerd-fonts') {
        If ((& scoop bucket list | Select-Object -ExpandProperty Name) -notcontains $n) { & scoop bucket add $n }
        Foreach ($d in 'Delugia-Nerd-Font-Complete') {
            If (-not (& scoop info $d)) { & scoop install "$n/$d" }
        }
    }

    $delugiaFile = Get-ChildItem -FollowSymlink -Path (& scoop prefix 'Delugia*') |
        Get-ChildItem -File -Filter '*.ttf' |
        Select-Object -ExpandProperty FullName

    If ([WindowsPrincipal]::New([WindowsIdentity]::GetCurrent()).IsInRole([WindowsBuiltInRole]::Administrator)) {
        Install-Font -Scope AllUsers -Path $delugiaFile
    } Else {
        Start-Process -FilePath pwsh.exe -Verb RunAs -ArgumentList "-NoLogo -NoProfile -Command { Install-Font -Scope AllUsers -Path `"$delugiaFile`" }"
    }
}

Exit