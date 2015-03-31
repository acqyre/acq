function url() {
    param(
        [Parameter(Mandatory=$true, Position=0)][string]$Url,
        [Parameter(Mandatory=$false)][string]$Hash)
    
    $obj = New-Object PSCustomObject -Property @{
        "Url" = $Url
        "Hash" = $Hash
    }

    if(!$_CurrentSpec.Packages) {
        Add-Member "Packages" @() -InputObject $_CurrentSpec -Force
    }
    $_CurrentSpec.Packages += $obj
}
