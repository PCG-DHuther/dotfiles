Param(
    [Parameter(ParameterSetName = 'FromRepo')][Uri]$Repository, # git@github.com:/PCG-DHuther/dotfiles.git - with SSH
    [Parameter(ParameterSetName = 'New')][Switch]$New
)

Begin {
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    Try { Get-Command -Name winget } Catch {
        Throw 'winget is not installed. Please install winget and re-run this script.'
    }
    Try { Get-Command -Name chezmoi } Catch {
        Write-Host 'chezmoi is not installed. Installing chezmoi...'
        & winget install twpayne.chezmoi --scope -user --silent --source winget
    }
    $ErrorActionPreference = $previousErrorActionPreference
}

Process {
    Switch ($PSCmdlet.ParameterSetName) {
        'FromRepo' {
            Write-Host "Initializing chezmoi from repository: $Repository"
            & chezmoi init "$Repository"
        }
        'New' {
            Write-Host 'Initializing new chezmoi configuration'
            & chezmoi init
            & chezmoi edit-config-template
            <#
            pager = "less -R"
            encryption = "gpg"

            [add]
                secrets = "error"

            [edit]
                command = "code"
                args = ["--wait"]
                apply = true

            [git]
                autoCommit = true
                autoPush = true

            [gpg]
                recipient = "{email}}"

            [hooks.edit-config-template.post]
                command = "chezmoi"
                args = ["init"]
            #>
            & chezmoi init
            & chezmoi apply
        }
    }
}