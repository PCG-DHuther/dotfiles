& winget install twpayne.chezmoi --scope -user --silent --source winget -accept-package-agreements -accept-source-agreements

powershell.exe -NoExit -NoProfile -Command '& chezmoi init https://github.com/PCG-DHuther/dotfiles.git; & chezmoi apply'
