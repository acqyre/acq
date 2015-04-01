function version() {
    param(
        [Parameter(Mandatory=$true, Position=0)][string]$Value)
    
    Add-Member "Version" $Value -InputObject $_CurrentSpec -Force
}

function author() {
    param(
        [Parameter(Mandatory=$true, Position=0)][string]$Value)
    
    Add-Member "Author" $Value -InputObject $_CurrentSpec -Force
}

function packager() {
    param(
        [Parameter(Mandatory=$true, Position=0)][string]$Value)
    
    Add-Member "Packager" $Value -InputObject $_CurrentSpec -Force
}

