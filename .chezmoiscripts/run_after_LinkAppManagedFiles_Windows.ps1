# Using namespace System.IO

# [String]$winChezmoiSourcePath = (& chezmoi source-path).Replace("$([Path]::AltDirectorySeparatorChar)", "$([Path]::DirectorySeparatorChar)") #| Join-Path -ChildPath ([String]::Empty)

# Join-Path -Path ([Path]::GetDirectoryName($PSScriptRoot)) -ChildPath AppData | Get-ChildItem -File -Recurse | Where-Object -FilterScript {

#     Test-Path -Path $($_.FullName.Replace($winChezmoiSourcePath, $env:UserProfile) -replace '\.tmpl$')
# }

# Get-ChildItem -File -Recurse -Path

# Get-Item $Home/.config/powershell/*profile.ps1 | ForEach-Object {
#     $linkPath = Join-Path $basePath $_.Name
#     if ((Get-Item $linkPath -erroraction silentlycontinue).linktype -ne 'SymbolicLink') {
#         Write-Host "Removing existing profile $linkPath to link to chezmoi profile. Confirm or cancel and move it."
#         Remove-Item $linkPath -Confirm:$true
#         New-Item -ItemType HardLink -Path $linkPath -Target $_.FullName
#     }
# }