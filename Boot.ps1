param(
    $GitDownloadUrl = "https://github.com/msysgit/msysgit/releases/download/Git-1.9.5-preview20141217/Git-1.9.5-preview20141217.exe",
    $GitDownloadHash = "D7E78DA2251A35ACD14A932280689C57FF9499A474A448AE86E6C43B882692DD",
    $BakeryRepoUrl = "https://github.com/anurse/Bakery",
    $Library = "$env:SYSTEMDRIVE\Library")

function InstallGit() {
    # Download Git
    $GitName = $GitDownloadUrl.Substring($GitDownloadUrl.LastIndexOf("/") + 1)
    $m = [Regex]::Match($GitName, "^Git\-(?<version>.*)\.exe$")
    if(!($m.Success)) {
        throw "Unexpected format for Git Download URL!"
    }
    $GitVersion = $m.Groups["version"].Value
    $GitInstaller = Join-Path $Downloads $GitName

    if(Test-Path $GitInstaller) {
        # Check the hash
        $ActualHash = (Get-FileHash -Algorithm SHA256 $GitInstaller).Hash
        if($GitDownloadHash -ne $ActualHash) {
            del $GitInstaller
        }
    }

    if(!(Test-Path $GitInstaller)) {
        Write-Host "Downloading Git $GitVersion ..."
        curl $GitDownloadUrl -OutFile $GitInstaller
    }

    Write-Host "Installing Git $GitVersion ..."
    $GitPackageDir = Join-Path $Packages "Git\$GitVersion"
    if(!(Test-Path $GitPackageDir)) {
        mkdir $GitPackageDir | Out-Null
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.UseShellExecute = $false
    $psi.Verb = "runas"
    $psi.FileName = $GitInstaller
    $psi.Arguments = "/VERYSILENT /SUPPRESSMESSAGEBOXES /LOG=`"$GitPackageDir\install.log`" /DIR=`"$GitPackageDir`""

    $p = [System.Diagnostics.Process]::Start($psi);
    $p.WaitForExit();

    Write-Host "Testing git"

    $Git = Join-Path $GitPackageDir "cmd\git.exe"
    try {
        $ReportedVersion = &$Git --version
    } catch {
        throw "Failed to install git!"
    }

    # Create the symlink
    dir (Join-Path $GitPackageDir "cmd") | ForEach {
        $BaseName = [IO.Path]::GetFileNameWithoutExtension($_.Name)
        "@%~dp0..\Packages\Git\$GitVersion\cmd\$($_.Name) %*" | Out-File -FilePath "$Bin\$BaseName.cmd" -Encoding ascii
    }
}

# Create the Library if necessary
if(!(Test-Path $Library)) {
    mkdir $Library | Out-Null
}

# Create the download directory
$Downloads = Join-Path $Library "Downloads"
if(!(Test-Path $Downloads)) {
    mkdir $Downloads | Out-Null
}

# Create the packages directory
$Packages = Join-Path $Library "Packages"
if(!(Test-Path $Packages)) {
    mkdir $Packages | Out-Null
}

# Create the bin folder and put it on the path
$Bin = Join-Path $Library "Bin"
if(!(Test-Path $Bin)) {
    mkdir $Bin | Out-Null
}
$env:PATH = "$(Convert-Path $Bin);$($env:PATH)"

if((Get-Command -ErrorAction SilentlyContinue git)) {
    Write-Host "Git is already installed!"
} else {
    InstallGit
}

$Bakery = Join-Path $Library Bakery
if((Test-Path "$Bakery") -and (Test-Path "$Bakery\.git")) {
    # Update it
    pushd $Bakery | Out-Null
    git checkout master
    git pull origin master
    popd | Out-Null
} else {
    # Clone the Bakery repo
    pushd $Library | Out-Null
    git clone $BakeryRepoUrl Bakery
    popd | Out-Null
}

# Run the Bakery setup script
& $Bakery\Setup.ps1