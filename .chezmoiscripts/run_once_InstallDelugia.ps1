Set-StrictMode -Version Latest

If (-not (Get-Command -Name scoop)) {
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
}

Foreach ($n in 'nerd-fonts') {
    If ((& scoop bucket list | Select-Object -ExpandProperty Name) -notcontains $n) {
        & scoop bucket add $n
    }

    Foreach ($d in 'Delugia-Nerd-Font-Complete') {
        If (-not (& scoop info $d)) {
            & scoop install "$n/$d"
        }
    }
}