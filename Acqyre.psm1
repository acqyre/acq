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

# Set up Acqyre Plugin Management
$AcqyrePlugins = @{} 
function Get-AcqyrePlugin($Type, $Name) {
    if($AcqyrePlugins[$Type]) {
        $AcqyrePlugins[$Type][$Name]
    }
}

function Plugin($Type, $Name, $Value) {
    $dict = $AcqyrePlugins[$Type]
    if(!$dict) {
        $dict = @{}
        $AcqyrePlugins[$Type] = $dict
    }
    $dict[$Name] = $Value
}

# Load functions
dir $PSScriptRoot\Functions\*.ps1 | ForEach-Object {
    . $_.FullName
}

function acq {
    Invoke-Subcommand "acq" @args
}

Export-ModuleMember -Function "acq"
