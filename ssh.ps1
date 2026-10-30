#Requires -RunAsAdministrator

Get-Service -Name ssh-agent | Set-Service -Force -StartupType Automatic
Start-Service -Name ssh-agent

<#
run as user AFTER chezmoi has set up the .ssh folder and copied in the keys:
# ssh-keygen -t ed25519 -f .\.ssh\id_ed25519 -C "$(& whoami /upn)" # to create a new key
& ssh-agent -s
ssh-add .\.ssh\id_ed25519
#>