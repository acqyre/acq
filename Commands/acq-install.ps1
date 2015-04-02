param(
    [Parameter(Mandatory=$true)][string]$Package,
    [Alias("-f")][Parameter()][switch]$Force)
   
$spec = Get-Formula $Package
Invoke-Formula $spec -Force:$Force
