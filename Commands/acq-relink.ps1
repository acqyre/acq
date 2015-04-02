<#
.SYNOPSIS
    Re-runs the 'on install' actions for a package that has already been downloaded
#>
param(
    [Parameter(Mandatory=$true, Position=0)][string]$Package)

$spec = Get-Formula $Package

try {
    $global:_CurrentPackageRelativeDir = Get-PackageRoot $spec.Name 
    Invoke-FormulaEvent $spec -Event install
} finally {
    $global:_CurrentPackageRelativeDir = "" 
}
