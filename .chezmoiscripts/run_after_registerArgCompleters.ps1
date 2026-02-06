#region functions
# I have made very minor modifications to the function below but its source is: https://gist.github.com/BradKnowles/14ed0a263112a571e26d070d07b58e4e
function Get-ArgumentCompleter {
    <#
    .SYNOPSIS
    Lists all registered argument completers created with Register-ArgumentCompleter.

    .DESCRIPTION
    This function retrieves all custom argument completers registered in the current PowerShell session
    using Register-ArgumentCompleter and displays their script block contents.

    .PARAMETER ShowScriptBlock
    If specified, displays the full script block content in a readable format.

    .EXAMPLE
    Get-ArgumentCompleter
    Lists all registered argument completers.

    .EXAMPLE
    Get-ArgumentCompleter -ShowScriptBlock
    Lists all registered argument completers with full script block content.
    #>

    [CmdletBinding()] [OutputType([PSCustomObject])] Param([Parameter()][Switch]$ShowScriptBlock)

    try {
        $completers = @()

        # Access the internal ExecutionContext to get to the CommandDiscovery
        $contextField = $ExecutionContext.GetType().GetField('_context', [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance)
        if (-not $contextField) {
            throw 'Could not access ExecutionContext._context field'
        }

        $internalContext = $contextField.GetValue($ExecutionContext)
        if (-not $internalContext) {
            throw 'Could not get internal ExecutionContext'
        }

        # Get the AutomationEngine
        $engineField = $internalContext.GetType().GetField('<Engine>k__BackingField', [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance)
        if (-not $engineField) {
            throw 'Could not access Engine field'
        }

        $automationEngine = $engineField.GetValue($internalContext)
        if (-not $automationEngine) {
            throw 'Could not get AutomationEngine'
        }

        # Get the CommandDiscovery
        $commandDiscoveryField = $automationEngine.GetType().GetField('<CommandDiscovery>k__BackingField', [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance)
        if (-not $commandDiscoveryField) {
            throw 'Could not access CommandDiscovery field'
        }

        $commandDiscovery = $commandDiscoveryField.GetValue($automationEngine)
        if (-not $commandDiscovery) {
            throw 'Could not get CommandDiscovery'
        }

        # Look for argument completer storage in CommandDiscovery
        $discoveryFields = $commandDiscovery.GetType().GetFields([System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Public)

        foreach ($field in $discoveryFields) {
            try {
                $value = $field.GetValue($commandDiscovery)
                if ($value -ne $null -and $value.GetType().Name -like '*Dictionary*') {
                    # Check if this dictionary contains script blocks (likely completers)
                    foreach ($kvp in $value.GetEnumerator()) {
                        if ($kvp.Value -and $kvp.Value.GetType().Name -eq 'ScriptBlock') {
                            $completers += [PSCustomObject]@{
                                CommandName     = $kvp.Key
                                CompleterSource = "CommandDiscovery.$($field.Name)"
                                ScriptBlock     = if ($ShowScriptBlock) { $kvp.Value.ToString() } else { $kvp.Value.ToString().Substring(0, [Math]::Min(100, $kvp.Value.ToString().Length)) + '...' }
                                FullScriptBlock = $kvp.Value
                            }
                        }
                    }
                }
            } catch {
                # Ignore fields we can't access
                continue
            }
        }

        # If we didn't find completers in CommandDiscovery, try looking in the execution context itself
        if ($completers.Count -eq 0) {
            $contextFields = $internalContext.GetType().GetFields([System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Public)

            foreach ($field in $contextFields) {
                try {
                    $value = $field.GetValue($internalContext)
                    if ($value -ne $null -and $value.GetType().Name -like '*Dictionary*') {
                        foreach ($kvp in $value.GetEnumerator()) {
                            if ($kvp.Value -and $kvp.Value.GetType().Name -eq 'ScriptBlock') {
                                $completers += [PSCustomObject]@{
                                    CommandName     = $kvp.Key
                                    CompleterSource = "ExecutionContext.$($field.Name)"
                                    ScriptBlock     = if ($ShowScriptBlock) { $kvp.Value.ToString() } else { $kvp.Value.ToString().Substring(0, [Math]::Min(100, $kvp.Value.ToString().Length)) + '...' }
                                    FullScriptBlock = $kvp.Value
                                }
                            }
                        }
                    }
                } catch {
                    continue
                }
            }
        }

        # Return results
        if ($completers.Count -gt 0) {
            $result = $completers | Sort-Object CommandName

            if ($ShowScriptBlock) {
                foreach ($completer in $result) {
                    Write-Host "`n=== $($completer.CommandName) ===" -ForegroundColor Green
                    Write-Host "Source: $($completer.CompleterSource)" -ForegroundColor Yellow
                    Write-Host 'Script Block:' -ForegroundColor Cyan
                    Write-Host $completer.FullScriptBlock.ToString() -ForegroundColor White
                    Write-Host ('-' * 50) -ForegroundColor Gray
                }
            } else {
                $result | Select-Object CommandName, CompleterSource, ScriptBlock
            }
        } else {
            Write-Warning 'No argument completers found in the current session.'
            Write-Host "`nThis could be because:" -ForegroundColor Yellow
            Write-Host '  1. No completers have been registered with Register-ArgumentCompleter' -ForegroundColor Cyan
            Write-Host '  2. The internal storage mechanism has changed in this PowerShell version' -ForegroundColor Cyan
            Write-Host '  3. Completers are stored in a location not yet discovered by this function' -ForegroundColor Cyan
            Write-Host "`nTo register a new completer, use:" -ForegroundColor Yellow
            Write-Host "Register-ArgumentCompleter -CommandName 'YourCommand' -ScriptBlock { param(`$commandName, `$parameterName, `$wordToComplete, `$commandAst, `$fakeBoundParameter) }" -ForegroundColor Cyan
        }
    } catch {
        Write-Error "Failed to retrieve argument completers: $($_.Exception.Message)"
        Write-Host "`nThis error suggests the internal PowerShell structure may have changed." -ForegroundColor Yellow
        Write-Host "Please report this issue with your PowerShell version: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
    }
}

<#
# This doesn't work as well as I would like for some reason.
function Update-CarapaceRegistration {

    [CmdletBinding()] [OutputType([Void])] Param()

    [Hashtable]$onlyOverlap = @{
        IncludeEqual     = $true
        ExcludeDifferent = $true
        ReferenceObject  = & carapace --list | ForEach-Object { $_.Split(' ')[0] }
        DifferenceObject = Get-Command -CommandType Application | ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_.Name) }
    }

    [Hashtable]$missingCompleter = @{
        ReferenceObject  = Compare-Object @onlyOverlap | Select-Object -ExpandProperty InputObject
        DifferenceObject = Get-ArgumentCompleter | Select-Object -ExpandProperty CommandName
    }

    Compare-Object @missingCompleter | Where-Object -Property SideIndicator -EQ '<=' | Foreach-Object {
        & carapace $_.InputObject powershell | Out-String | Invoke-Expression
    }
}
#>
#endregion functions

#region logic
If ($argumentCompleterList -notcontains 'dsc') { & dsc completer powershell | Out-String | Invoke-Expression }

#Update-CarapaceRegistration
& carapace _carapace powershell | Out-String | Invoke-Expression

# Install vincent
New-Item -ItemType Directory -Path "$env:UserProfile\bin\" | Foreach-Object {
    $destinationArchive = Join-Path -Path $_ -ChildPath 'vincent_windows_amd64.zip'
    $destinationDirectory = Join-Path -Path $_ -ChildPath 'vincent'
    Invoke-WebRequest -Uri 'https://github.com/rsteube/vincent/releases/download/v0.1.4/vincent_windows_amd64.zip' -OutFile $destinationArchive
    Expand-Archive -Force -Path $destinationArchive -DestinationPath $destinationDirectory
    [Environment]::SetEnvironmentVariable('Path', $("${env:path};$destinationDirectory"), [EnvironmentVariableTarget]::User)
    Push-Location -Path $destinationDirectory
    & .\vincent _carapace | Out-String | Invoke-Expression
    Pop-Location
}

#endregion logic