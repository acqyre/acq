param($Name)

$idx = $Name.IndexOf("/")
$Owner = $Name.Substring(0, $idx)
$Repo = $Name.Substring($idx+1)
$Url = "https://github.com/$Owner/acqyre-$Repo"
$Root = Join-Path $LibraryPaths.Collections $Owner
if(!(Test-Path $Root)) {
     mkdir $Root
}
pushd $Root
git clone $Url
popd
