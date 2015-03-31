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


