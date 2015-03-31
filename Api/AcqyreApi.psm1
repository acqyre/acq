dir $PSScriptRoot -fil *.ps1 | ForEach-Object {
    . $_.FullName
}

function formula {
    param(
        [Parameter(Mandatory=$true, Position=0)][string]$Name,
        [Parameter(Mandatory=$true, Position=1)][scriptblock]$Body)

    $_CurrentSpec = New-Object PSObject -Property @{
        "Name" = $Name
        "Events" = @{}
    }
    & $Body
    
    $_CurrentSpec
}

function on() {
    param(
        [Parameter(Mandatory=$true, Position=0)][string]$Event,
        [Parameter(Mandatory=$true, Position=1)][scriptblock]$Body)

    $_CurrentEvent = New-Object PSCustomObject -Property @{
        "Name" = "install"
        "Actions" = @()
    }

    & $Body

    $_CurrentSpec.Events[$Event] = $_CurrentEvent

    Remove-Variable _CurrentEvent
}

Export-ModuleMember -Function *
