Using namespace System.IO
Using namespace System.Management.Automation

Try {
    [Path]::Combine($env:UserProfile, '.dsc', 'packages.winget') | Resolve-Path -ErrorAction Stop |
        ForEach-Object {
            & winget configure --file "${_}" --accept-configuration-agreements
        }
} Catch [ItemNotFoundException] {
    Write-Error -Message $_.Exception.Message
    Exit 1
} Finally {
    Exit 0
}