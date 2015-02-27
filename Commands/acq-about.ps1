param(
    [Parameter(Mandatory=$true)][string]$Name)
   
$spec = Get-Formula $Name

$spec
