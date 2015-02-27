param(
    [Parameter(Mandatory=$true)][string]$Recipe,
    [Parameter()][switch]$Force)
   
$spec = _loadspec $Recipe
_runspec $spec -Force:$Force
