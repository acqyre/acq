param(
    [Parameter(Mandatory=$true)][string]$Formula,
    [Parameter()][switch]$Force)
   
$spec = Get-Formula $Formula
Invoke-Formula $spec -Force:$Force
