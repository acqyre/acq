function _overlaycontents($src, $dest) {
    Copy-Item "$src/*" -Destination $dest -Force -Recurse
    Remove-Item "$src" -Force -Recurse
}

Plugin -Type "Unpacker" -Name "7z" {
    param($package)

    if(!(Get-Command 7z -ErrorAction SilentlyContinue)) {
        throw "7zip not installed!"
    }

    $target = Convert-Path (Split-Path -Parent $package)
    $contents = Join-Path $target "ExtractTemp"

    7z x $package -o"$contents"
    
    _overlaycontents $contents $target
}

Plugin -Type "Unpacker" -Name "msi" {
    param($package)

    $target = Convert-Path (Split-Path -Parent $package)
    $contents = Join-Path $target "ExtractTemp"

    $logFile = Join-Path $target "bakery-unpack-msi.log"

    $exitCode = _exec msiexec /a (Convert-Path $package) /qn /log "$logFile" "INSTALLDIR=$contents" "TARGETDIR=$contents" "ALLUSERS=2" "MSIINSTALLPERUSER=1"

    if($exitCode -eq 1618) {
        throw "Cannot unpack MSI. The Windows Installer Service is busy with another installation..."
    }

    _overlaycontents $contents $target
}

Plugin -Type "Unpacker" -Name "zip" {
    param($package)

    $target = Convert-Path (Split-Path -Parent $package)
    $contents = Join-Path $target "ExtractTemp"

    $compressionLib = [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')

    if(!$compressionLib) {
        throw "Missing required assembly: System.IO.Compression.FileSystem"
    }

    [System.IO.Compression.ZipFile]::ExtractToDirectory($package, $contents)
    
    _overlaycontents $contents $target
}
