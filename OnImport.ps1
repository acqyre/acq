# Write Environment variables
[Environment]::SetEnvironmentVariable("ACQYRE_LIBRARY", $Library, "User") 
[Environment]::SetEnvironmentVariable("ACQYRE_LIBRARY", $Library, "Process")

# Set up PATH
$path = [Environment]::GetEnvironmentVariable("PATH", "User");
$path = Add-Path "$Library\Bin" $path
[Environment]::SetEnvironmentVariable("PATH", $path, "User");

$path = $env:PATH
$path = Add-Path "$Library\Bin" $path
$env:PATH = $path

