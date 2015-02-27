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

function _fetchurl($destination, $url) {
    Write-Host "Downloading $url ..."
    Invoke-WebRequest -Uri $url -OutFile $destination
}

function _exec {
    $cmd = $args[0]
    $cmdargs = $args[1..($args.Length - 1)]

    Write-Host "$($cmd): $cmdargs"

    $p = Start-Process -FilePath $cmd -ArgumentList $cmdargs -PassThru
    $p.WaitForExit();
    $p.ExitCode
}

function _overlaycontents($src, $dest) {
    Copy-Item "$src/*" -Destination $dest -Force -Recurse
    Remove-Item "$src" -Force -Recurse
}

function _unpack_7z($package) {
    if(!(Get-Command 7z -ErrorAction SilentlyContinue)) {
        throw "7zip not installed!"
    }

    $target = Convert-Path (Split-Path -Parent $package)
    $contents = Join-Path $target "ExtractTemp"

    7z x $package -o"$contents"
    
    _overlaycontents $contents $target
}

function _unpack_msi($package) {
    $target = Convert-Path (Split-Path -Parent $package)
    $contents = Join-Path $target "ExtractTemp"

    $logFile = Join-Path $target "bakery-unpack-msi.log"

    $exitCode = _exec msiexec /a (Convert-Path $package) /qn /log "$logFile" "INSTALLDIR=$contents" "TARGETDIR=$contents" "ALLUSERS=2" "MSIINSTALLPERUSER=1"

    if($exitCode -eq 1618) {
        throw "Cannot unpack MSI. The Windows Installer Service is busy with another installation..."
    }

    _overlaycontents $contents $target
}

function _unpack_zip($package) {
    $target = Convert-Path (Split-Path -Parent $package)
    $contents = Join-Path $target "ExtractTemp"

    $compressionLib = [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')

    if(!$compressionLib) {
        throw "Missing required assembly: System.IO.Compression.FileSystem"
    }

    [System.IO.Compression.ZipFile]::ExtractToDirectory($package, $contents)
    
    _overlaycontents $contents $target
}

function _unpack($package) {
    Write-Host "Unpacking $package ..."
    switch([IO.Path]::GetExtension($package)) {
        ".msi" { _unpack_msi $package }
        ".zip" { _unpack_zip $package }
        ".7z" { _unpack_7z $package }
    }
}

function _apply_bin($action) {
    if($action.Copy) {
        # Locate the file
        $packageRoot = Join-Path $LibraryPaths.Packages $_CurrentPackageRelativeDir
        $file = Join-Path $packageRoot $action.Path

        # Just copy the file
        Copy-Item $file $LibraryPaths.Bin
    } else {
        # Place a link file in the library bin
        $linkFile = @"
@"%~dp0..\Packages\$_CurrentPackageRelativeDir\$($action.Path)" %*
"@
        if($action.Content) {
            $linkFile = $action.Content
        } elseif($action.UseStart) {
            $linkFile = @"
@start "launcher" "%~dp0..\Packages\$_CurrentPackageRelativeDir\$($action.Path)" %*
"@  
        }
        $binaryName = [IO.Path]::GetFileNameWithoutExtension($action.Path)
        if($action.Name) {
            $binaryName = $action.Name
        }

        $linkName = $binaryName + ".cmd"
        
        $linkPath = Join-Path $LibraryPaths.Bin $linkName
        if(Test-Path $linkPath) {
            Remove-Item $linkPath
        }
        $linkFile | Out-File -FilePath $linkPath -Encoding ascii

        Write-Verbose "Placed bin-link $linkName"
    }
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
    try {
        if(!$spec.Name) {
            throw "Invalid spec. Missing name"
        }
        if(!$spec.Version) {
            throw "Invalid spec. Missing version"
        }
        if(!$spec.Packages -or ($spec.Packages.Length -eq 0)) {
            throw "Invalid spec. Missing Packages"
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

        # Fetch the Packages
        $spec.Packages | ForEach-Object {
            $name = ([uri]$_.Url).Segments[-1]
            if(!$name) {
                throw "Unable to detect file name for url $url"
            }
            $package = Join-Path $packageDir $name
            try {
                _fetchurl $package $_.Url
            } catch {
                throw $_
            }

            $actualHash = Get-FileHash -Algorithm SHA256 $package
            if($_.Hash) {
                if($actualHash.Hash -ne $_.Hash) {
                    throw "Actual package hash '$($actualHash.Hash)' did not match expected value"
                }
            } else {
                Write-Warning "Package '$name' does not have a recorded hash. One should be added to the formula!"
                Write-Warning "The hash of this download is: $($actualHash.Hash)"
            }

            # Unpack the package
            _unpack $package
        }

        # Run actions
        $installEvent = $spec.Events["install"]
        if($installEvent -and $installEvent.Actions -and ($installEvent.Actions.Length -gt 0)) {
            $installEvent.Actions | ForEach-Object {
                _apply $_
            }
        }

        del variable:\_CurrentPackageRelativeDir
    }
    catch {
        Write-Error $_
        Write-Host "Rolling back installation..."
        del -rec -for $packageDir
        throw "Installation Failed"
    }
}

function _loadspec($recipe) {
    # Locate the recipe
    $r = (dir -rec -fil "$Recipe.ps1" $LibraryPaths.Collections | select -first 1)
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
        # Check the Commands folder
        $cmdFile = Join-Path (Join-Path $LibraryPaths.Acq "Commands") "$prefix-$Command.ps1"

        if(Test-Path $cmdFile) {
            & $cmdFile @cmdargs
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
}