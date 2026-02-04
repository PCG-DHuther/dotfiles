#Requires -PSEdition Core
#Requires -Version 7.1

[String]$winFormattedChezmoiSourcePath = (& chezmoi source-path).Replace("$([io.path]::AltDirectorySeparatorChar)", "$([IO.path]::DirectorySeparatorChar)") #| Join-Path -ChildPath ([String]::Empty)

Join-Path -Path ([IO.Path]::GetDirectoryName($PSScriptRoot)) -ChildPath AppData | Get-ChildItem -File -Recurse | Where-Object -FilterScript {

    Test-Path -Path $($_.FullName.Replace($winFormattedChezmoiSourcePath, $env:UserProfile) -replace '\.tmpl$')
}

Get-ChildItem -File -Recurse -Path

Get-Item $Home/.config/powershell/*profile.ps1 | ForEach-Object {
    $linkPath = Join-Path $basePath $_.Name
    if ((Get-Item $linkPath -erroraction silentlycontinue).linktype -ne 'SymbolicLink') {
        Write-Host "Removing existing profile $linkPath to link to chezmoi profile. Confirm or cancel and move it."
        Remove-Item $linkPath -Confirm:$true
        New-Item -ItemType HardLink -Path $linkPath -Target $_.FullName
    }
}