function Get-Formula($name) {
    # Locate the recipe
    $r = (dir -rec -fil "$name.ps1" $LibraryPaths.Collections | select -first 1)
    if(!$r) {
        throw "No such formula found: '$name'"
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
        $global:_CurrentPackageRelativeDir = Join-Path $formula.Name $formula.Version
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
        $formula.Packages | ForEach-Object {
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
        $installEvent = $formula.Events["install"]
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
