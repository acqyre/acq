# Locate the library
$Library = Split-Path -Parent $PSScriptRoot

# Set up Library paths
$LibraryPaths = New-Object PSObject -Property @{
    "Root" = $Library
    "Bin" = Join-Path $Library "Bin"
    "Collections" = Join-Path $Library "Collections"
    "Packages" = Join-Path $Library "Packages"
    "Acq" = Join-Path $Library "Acq"
}
Export-ModuleMember -Variable LibraryPaths

# Load functions
dir $PSScriptRoot\Functions\*.ps1 | ForEach-Object {
    . $_.FullName
}

function acq {
    _dispatch_subcommand "acq" @args
}

Export-ModuleMember -Function "acq"
