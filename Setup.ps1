# Locate the library
$Library = Split-Path -Parent $PSScriptRoot

function Add-Path {
    param($path, $pathStr)

    if($pathStr) {
        $elements = @($pathStr.Split(";"))
    } else {
        $elements = @()
    }

    if($elements -icontains $path) {
        $pathStr
    } else {
        "$path;$pathStr"
    }
}

# Write Environment variables
[Environment]::SetEnvironmentVariable("BAKERY_LIBRARY", $Library, "User")
[Environment]::SetEnvironmentVariable("BAKERY_LIBRARY", $Library, "Process")

# Set up PATH
$path = [Environment]::GetEnvironmentVariable("PATH", "User");
$path = Add-Path "$Library\Bin" $path
[Environment]::SetEnvironmentVariable("PATH", $path, "User");

$path = $env:PATH
$path = Add-Path "$Library\Bin" $path
$env:PATH = $path