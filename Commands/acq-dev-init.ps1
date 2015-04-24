<#
.SYNOPSIS
    Initialize a new acqyre collection
.PARAMETER Name
    The name of the collection
#>
param($Name)

$idx = $Name.IndexOf("/")
$Owner = $Name.Substring(0, $idx)
$Repo = $Name.Substring($idx+1)

$CollectionRoot = Join-Path (Join-Path $LibraryPaths.Collections "$Owner") "acqyre-$Repo"
New-Item -Type Directory $CollectionRoot | Out-Null
Push-Location $CollectionRoot
try {
    git init
    git remote set-url origin https://github.com/$Owner/acqyre-$Repo
} finally {
    Pop-Location
}
