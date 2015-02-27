param(
    [Parameter(Mandatory=$true)][string]$Recipe)
   
$spec = _loadspec $Recipe

$spec
