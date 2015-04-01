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

function Unpack-Package($package) {
    # Look up the plugin
    $name = ([IO.Path]::GetExtension($package).TrimStart("."))
    $plugin = Get-AcqyrePlugin -Type "Unpacker" -Name $name
    if($plugin) {
        & $plugin $package
    }
}

function Invoke-Action($action) {
    # Look up the plugin
    $plugin = Get-AcqyrePlugin -Type "Action" -Name $action.Type
    if(!$plugin) {
        throw "Unknown action type: $($action.Type)"
    }
    & $plugin.Install $action
}

function Invoke-Subcommand {
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
