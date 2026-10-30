# Setup Starship for Nu shell
mkdir ($nu.data-dir | path join 'vendor/autoload')
starship init nu | save -f ($nu.data-dir | path join 'vendor/autoload/starship.nu')