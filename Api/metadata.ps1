function version() {
    param(
        [Parameter(Mandatory=$true, Position=0)][string]$Version)
    
    Add-Member "Version" $Version -InputObject $_CurrentSpec -Force
}

