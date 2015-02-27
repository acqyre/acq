function warn() {
    Write-Warning @args
}

function trace() {
    Write-Verbose @args
}

function info() {
    Write-Host @args
}

function url() {
    param(
        [Parameter(Mandatory=$true, Position=0)][string]$Url,
        [Parameter(Mandatory=$false)][string]$Hash)
    
    $obj = New-Object PSCustomObject -Property @{
        "Url" = $Url
        "Hash" = $Hash
    }

    if(!$_CurrentSpec.Packages) {
        Add-Member "Packages" @() -InputObject $_CurrentSpec -Force
    }
    $_CurrentSpec.Packages += $obj
}

function hash() {
    param(
        [Parameter(Mandatory=$true, Position=0)][string]$Hash)

    Add-Member "Hash" $Hash -InputObject $_CurrentSpec -Force
}

function version() {
    param(
        [Parameter(Mandatory=$true, Position=0)][string]$Version)
    
    Add-Member "Version" $Version -InputObject $_CurrentSpec -Force
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

function bin() {
    [CmdletBinding(DefaultParameterSetName="Path")]
    param(
        [Parameter(Mandatory=$true, Position=0, ParameterSetName="Path")][string]$Path,
        [Parameter(Mandatory=$true, ParameterSetName="Content")][string]$Name,
        [Parameter(Mandatory=$true, ParameterSetName="Content")][string]$Content,
        [Parameter(ParameterSetName="Path")][switch]$Copy,
        [Parameter(ParameterSetName="Path")][switch]$UseStart)
    if(!$_CurrentEvent) { throw "This command must be used in an 'on [event]' block" }

    if($PSCmdlet.ParameterSetName -eq "Content") {
        $_CurrentEvent.Actions += @(New-Object PSCustomObject -Property @{
            "Type"="bin"
            "Name"=$Name
            "Content"=$Content
            "Copy"=$Copy.IsPresent
            "UseStart"=$UseStart.IsPresent
        })
    } else {
        $_CurrentEvent.Actions += @(New-Object PSCustomObject -Property @{
            "Type"="bin"
            "Path"=$Path
            "Copy"=$Copy.IsPresent
            "UseStart"=$UseStart.IsPresent
        })
    }
}

function startmenu() {
    param(
        [Parameter(Mandatory=$true, Position=0)][string]$Path,
        [Parameter(Mandatory=$true, Position=1)][string]$Name)
    if(!$_CurrentEvent) { throw "This command must be used in an 'on [event]' block" }

    $_CurrentEvent.Actions += @(New-Object PSCustomObject -Property @{
        "Type"="startmenu"
        "Path"=$Path
        "Name"=$Name
    })
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

Export-ModuleMember -Function *
