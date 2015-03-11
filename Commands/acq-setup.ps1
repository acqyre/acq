$script = @"
Import-Module $($LibraryPaths.Root)\Acq\Acqyre.psd1
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
$userPath = Add-Path "%ACQYRE_LIBRARY%\Bin" $userPath
[Environment]::SetEnvironmentVariable("PATH", $userPath, "User")

[Environment]::SetEnvironmentVariable("ACQYRE_LIBRARY", $LibraryPaths.Root, "User")

$env:PATH = Add-Path "$env:ACQYRE_LIBRARY\Bin" $env:PATH
$env:ACQYRE_LIBRARY = $LibraryPaths.Root