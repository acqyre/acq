function Get-Formula($name) {
    # Locate the recipe
    $r = (dir -rec -fil "$name.ps1" $LibraryPaths.Collections | select -first 1)
    if(!$r) {
        # Try again in the built-in set
        $r = (dir -rec -fil "$name.ps1" (Join-Path $LibraryPaths.Acq "Formulae") | select -first 1)
        if(!$r) {
            throw "No such formula found: '$name'"
        }
    }

    # Load the Api Module
    Import-Module "$($LibraryPaths.Acq)\Api\AcqyreApi.psm1"

    # Execute the script
    try {
        $spec = & ($r.FullName)
    } finally {
        # Remove the Api Module
        Remove-Module AcqyreApi
    }

    if(!$spec) {
        throw "Formula did not return a spec! Make sure it begins with the 'formula NAME { }' block."
    }

    $spec
}

function Get-PackageRoot($name) {
    $ver = (dir (Join-Path $LibraryPaths.Packages $name) | select -first 1).Name
    Join-Path $name $ver
}

function Invoke-Formula($formula, [switch]$Force) {
    try {
        if(!$formula.Name) {
            throw "Invalid formula. Missing name"
        }
        if(!$formula.Version) {
            throw "Invalid formula. Missing version"
        }
        if(!$formula.Packages -or ($formula.Packages.Length -eq 0)) {
            throw "Invalid formula. Missing Packages"
        }

        Write-Verbose "Running formula: $($formula.Name)"

        # Assign the package directory
        $packageDir = Join-Path (Join-Path $LibraryPaths.Packages $formula.Name) $formula.Version
        Write-Verbose "Target directory: $packageDir"
        try {
            $global:_CurrentPackageRelativeDir = Join-Path $formula.Name $formula.Version
            if(Test-Path $packageDir) {
                if($Force) {
                    Write-Verbose "Cleaning target..."
                    Remove-Item -rec -for $packageDir
                } else {
                    throw "Destination already exists '$packageDir', use -Force to force install."
                }
            }

            Unpack-Formula $formula $packageDir

            Write-InstallAction "installing package..."
            Invoke-FormulaEvent -Event "install" $formula

            # Serialize the formula and save it
            $formula | Export-CliXml (Join-Path $packageDir ".acqformula.xml")
        } finally {
            $global:_CurrentPackageRelativeDir = ""
        }
    }
    catch {
        Write-Error $_
        Write-Host "Rolling back installation..."
        del -rec -for $packageDir
        throw "Installation Failed"
    }
}

function Unpack-Formula($formula, $packageDir) {
    New-Item -Type Directory $packageDir | Out-Null

    # Fetch the Packages
    $formula.Packages | ForEach-Object {
        $name = ([uri]$_.Url).Segments[-1]
        if(!$name) {
            throw "Unable to detect file name for url $url"
        }
        $package = Join-Path $packageDir $name
        try {
            Write-InstallAction "downloading package $($_.Url)"
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
        Unpack-Package $package
    }
}

function Invoke-FormulaEvent($Event, $formula) {
    
    # Run actions
    $event = $formula.Events[$Event]
    if($event -and $event.Actions -and ($event.Actions.Length -gt 0)) {
        $event.Actions | ForEach-Object {
            Invoke-Action $_
        }
    }
}

