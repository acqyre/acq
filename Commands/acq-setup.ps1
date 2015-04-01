if(!(Test-Path $LibraryPaths.Bin)) {
    New-Item -Type Directory $LibraryPaths.Bin | Out-Null
}

$script = @"
Import-Module `$PSScriptRoot\..\Acq\Acqyre.psd1
try {
    acq @args
} finally {
    Remove-Module Acqyre
}
"@
$script | Out-File -Encoding Ascii -FilePath (Join-Path $LibraryPaths.Bin "acq.ps1")

"@powershell -NoLogo -File %~dp0acq.ps1 %*" | Out-File -Encoding Ascii -FilePath (Join-Path $LibraryPaths.Bin "acq.cmd")

# Set up environment variables
$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$userPath = Add-Path "$($LibraryPaths.Bin)" $userPath
[Environment]::SetEnvironmentVariable("PATH", $userPath, "User")

[Environment]::SetEnvironmentVariable("ACQYRE_LIBRARY", $LibraryPaths.Root, "User")

$env:PATH = Add-Path "$env:ACQYRE_LIBRARY\Bin" $env:PATH
$env:ACQYRE_LIBRARY = $LibraryPaths.Root

# Install mandatory formulae
acq install 7zip
acq install git

# Subscribe to core formulae set
acq subscribe acqyre/core

# Now bind the Acqyre code to the git repo
pushd $LibraryPaths.Acq
git init
git remote set-url origin "https://github.com/acqyre/acqyre"
git fetch origin master:master --update-head-ok
git checkout -f master
popd 
