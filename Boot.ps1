param(
    $ZipBallRoot = "https://github.com/acqyre/acqyre/zipball",
    $Branch = "master",
    $AcqyreRepoUrl = "https://github.com/acqyre/acqyre",
    $Library = "$env:SYSTEMDRIVE\Library",
    [switch]$Force)

# Stop the script on error!
$ErrorActionPreference="Stop"

# Check and load prereqs
$compressionLib = [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')
if($compressionLib -eq $null) {
    throw "Acq requires .NET 4.5 or higher be installed (regardless of PowerShell version)"
}

if(!$Force -and (Test-Path $Library)) {
    throw "Library already exists at $Library. Use -Force to force overwriting of library files"
}

# Create the Acq subdirectory to hold the actual code
$AcqRoot = Join-Path $Library "Acq"
if(Test-Path $AcqRoot) {
    Remove-Item -Recurse -Force $AcqRoot
}
New-Item -Type Directory $AcqRoot | Out-Null

# Get the source zipball
$zipballDownload = Join-Path ([IO.Path]::GetTempPath()) "acqyre-zipball.zip"
if(Test-Path $zipballDownload) {
    Write-Debug "Deleting existing zipball download"
    Remove-Item -Force $zipballDownload
}
Write-Host "Downloading latest Acq sources from $Branch branch..."
curl "$ZipBallRoot/$Branch" -OutFile $zipballDownload

# Unpack Acqyre into the target directory
[System.IO.Compression.ZipFile]::ExtractToDirectory(
    (Convert-Path $zipballDownload),
    (Convert-Path $AcqRoot))

# Pull the contents up a directory
$nestedDir = Get-ChildItem $AcqRoot -Attributes Directory | Select-Object -First 1
if(!$nestedDir) {
    throw "Unexpected directory structure!"
}
Move-Item -Path "$($nestedDir.FullName)\*" -Destination $AcqRoot
$version = [regex]::Replace($nestedDir.Name, "[^\-]*-[^\-]*-(.*)", "`$1")
Remove-Item -Recurse -Force $nestedDir.FullName
Write-Host "Installed Acqyre $Branch@$version"

# Run Acqyre Setup
& "$AcqRoot\acq.ps1" setup
