$script = @"
Import-Module $PSScriptRoot\..\Acq\Acqyre.psd1
try {
    acq @args
} finally {
    Remove-Module Acqyre
}
"@
$script | Out-File -Encoding Ascii -FilePath (Join-Path $LibraryPaths.Bin "acq.ps1")

"@powershell -NoLogo -File %~dp0acq.ps1 %*" | Out-File -Encoding Ascii -FilePath (Join-Path $LibraryPaths.Bin "acq.cmd")
