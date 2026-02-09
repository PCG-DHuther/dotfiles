Using namespace System.Management.Automation

Try {
    Join-Path -Path $env:UserProfile -ChildPath .dsc | Join-Path -ChildPath packages.winget | Resolve-Path -ErrorAction Stop |
        ForEach-Object {
            & winget configure --file "${_}" --accept-configuration-agreements
        }
} Catch [ItemNotFoundException] {
    Write-Error -Message $_.Exception.Message
    Exit 1
} Finally {
    Exit 0
}