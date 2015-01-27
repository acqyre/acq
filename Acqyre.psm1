﻿# Locate the library
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
[Environment]::SetEnvironmentVariable("ACQYRE_LIBRARY", $Library, "User") 
[Environment]::SetEnvironmentVariable("ACQYRE_LIBRARY", $Library, "Process")

# Set up PATH
$path = [Environment]::GetEnvironmentVariable("PATH", "User");
$path = Add-Path "$Library\Bin" $path
[Environment]::SetEnvironmentVariable("PATH", $path, "User");

$path = $env:PATH
$path = Add-Path "$Library\Bin" $path
$env:PATH = $path

# Set up Library paths
$LibraryPaths = New-Object PSObject -Property @{
    "Root" = $Library
    "Bin" = Join-Path $Library "Bin"
    "Books" = Join-Path $Library "Books"
    "Packages" = Join-Path $Library "Packages"
    "Acq" = Join-Path $Library "Acq"
}
Export-ModuleMember -Variable LibraryPaths

function _fetchurl($destination, $url) {
    Write-Host "Downloading $url ..."
    Invoke-WebRequest -Uri $url -OutFile $destination
}

function _exec {
    $cmd = $args[0]
    $cmdargs = $args[1..($args.Length - 1)]

    Write-Host "$($cmd): $cmdargs"

    Start-Process -FilePath $cmd -ArgumentList $cmdargs -Wait
}

function _unpack_msi($package) {
    $target = Convert-Path (Split-Path -Parent $package)
    $contents = Join-Path $target "ExtractTemp"

    $logFile = Join-Path $target "bakery-unpack-msi.log"

    _exec msiexec /a (Convert-Path $package) /qn /log "$logFile" "INSTALLDIR=$contents" "TARGETDIR=$contents" "ALLUSERS=2" "MSIINSTALLPERUSER=1"
    mv "$contents/*" $target -Force
    rm $contents -Recurse -Force
}

function _unpack_zip($package) {
    $target = Convert-Path (Split-Path -Parent $package)
    $contents = Join-Path $target "ExtractTemp"

    $compressionLib = [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')

    if(!$compressionLib) {
        throw "Missing required assembly: System.IO.Compression.FileSystem"
    }

    [System.IO.Compression.ZipFile]::ExtractToDirectory($package, $contents)
    mv "$contents/*" $target -Force
    rm $contents -Recurse -Force
}

function _unpack($package) {
    switch([IO.Path]::GetExtension($package)) {
        ".msi" { _unpack_msi $package }
        ".zip" { _unpack_zip $package }
        default { throw "Unknown package type: $package" }
    }
}

function _apply_bin($action) {
    # Place a link file in the library bin
    $linkFile = @"
@%~dp0..\Packages\$_CurrentPackageRelativeDir\$($action.Path) %*
"@
    $linkName = [IO.Path]::GetFileNameWithoutExtension($action.Path) + ".cmd"
    
    $linkFile | Out-File -FilePath (Join-Path $LibraryPaths.Bin $linkName) -Encoding ascii

    Write-Verbose "Placed bin-link $linkName"
}

function _apply_startmenu($action) {
    Write-Host "TODO: Apply StartMenu"
}

function _apply($action) {
    switch($action.Type) {
        "bin" { _apply_bin $action }
        "startmenu" { _apply_startmenu $action }
        default { throw "Unknown action type: $action" }
    }
}

function _runspec($spec, [switch]$Force) {
    if(!$spec.Name) {
        throw "Invalid spec. Missing name"
    }
    if(!$spec.Version) {
        throw "Invalid spec. Missing version"
    }
    if(!$spec.Url) {
        throw "Invalid spec. Missing URL"
    }

    Write-Verbose "Running spec: $($spec.Name)"

    # Assign the package directory
    $packageDir = Join-Path (Join-Path $LibraryPaths.Packages $spec.Name) $spec.Version
    Write-Verbose "Target directory: $packageDir"
    $global:_CurrentPackageRelativeDir = Join-Path $spec.Name $spec.Version
    if(Test-Path $packageDir) {
        if($Force) {
            Write-Verbose "Cleaning target..."
            rm -rec -for $packageDir
        } else {
            throw "Destination already exists '$packageDir', use -Force to force install."
        }
    }
    mkdir $packageDir | Out-Null

    # Fetch the URL
    $name = ([uri]$spec.Url).Segments[-1]
    if(!$name) {
        throw "Unable to detect file name for url $url"
    }
    $package = Join-Path $packageDir $name
    try {
        _fetchurl $package $spec.Url
    } catch {
        throw $_
    }

    if($spec.Hash) {
        $actualHash = Get-FileHash -Algorithm SHA256 $package
        if($actualHash -ne $spec.Hash) {
            throw "Actual package hash '$actualHash' did not match expected value"
        }
    }

    # Unpack the package
    _unpack $package

    # Run actions
    $installEvent = $spec.Events["install"]
    if($installEvent -and $installEvent.Actions -and ($installEvent.Actions.Length -gt 0)) {
        $installEvent.Actions | ForEach-Object {
            _apply $_
        }
    }

    del variable:\_CurrentPackageRelativeDir
}

function _loadspec($recipe) {
    # Locate the recipe
    $r = (dir -rec -fil "$Recipe.ps1" $LibraryPaths.Books | select -first 1)
    if(!$r) {
        throw "No such recipe found: '$Recipe'"
    }

    # Load the Api Module
    Import-Module "$PSScriptRoot\Api\AcqyreApi.psm1"

    # Execute the script
    try {
        $spec = & ($r.FullName)
    } finally {
        # Remove the Api Module
        Remove-Module AcqyreApi
    }

    if(!$spec) {
        throw "Recipe did not return a spec! Make sure it begins with the 'Recipe NAME { }' block."
    }

    $spec
}

function _dispatch_subcommand {
    $prefix = $args[0];
    $Command = $args[1];
    if(!$Command) {
        $Command = "help"
    }
    if($args.Length -gt 2) {
        $cmdargs = $args[2..($args.Length - 1)]
    } else {
        $cmdargs = @()
    }

    $fn = "function:\$prefix-$Command"
    if(Test-Path $fn) {
        & (cat $fn) @cmdargs
    }
    else {
        $cmd = Get-Command "$prefix-$Command" -ErrorAction SilentlyContinue
        if($cmd) {
            & $cmd @cmdargs
        }
        else {
            throw "Unknown Command: $prefix-$Command"
        }
    }
}

function acq-help {
    Write-Host "TODO: Acq help"
}

function acq-about {
    param(
        [Parameter(Mandatory=$true)][string]$Recipe)
       
    $spec = _loadspec $Recipe

    $spec
}

function acq-install {
    param(
        [Parameter(Mandatory=$true)][string]$Recipe,
        [Parameter()][switch]$Force)
       
    $spec = _loadspec $Recipe
    _runspec $spec -Force:$Force
}

function acq {
    _dispatch_subcommand "acq" @args
}

Export-ModuleMember -Function "acq"