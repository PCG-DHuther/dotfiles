Using namespace System.Collections.Generic

[Hashtable]$install = @{
    NoNewWindow = $true
    Wait        = $true
    FilePath    = 'winget.exe'
}

[List[Object]]$appList = Get-Content -Path "$PSScriptRoot\winget.json" | ConvertFrom-Json

Foreach ($a in $appList) {
    [List[String]] $arguments = @(
        'install',
        '--id',
        $a.Id,
        '--scope',
        $a.Scope
        '--source',
        $a.Source,
        '--silent',
        '--accept-source-agreements',
        '--accept-package-agreements'
    )
    if ($a.version) { $arguments += @('--version', $a.version) }
    Start-Process @install -ArgumentList $arguments
}