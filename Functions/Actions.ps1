Plugin -Type "Action" -Name "bin" @{
    "Install"={
        param($action)

        if($action.Copy) {
            # Locate the file
            $packageRoot = Join-Path $LibraryPaths.Packages $_CurrentPackageRelativeDir
            $file = Join-Path $packageRoot $action.Path

            # Just copy the file
            Write-InstallAction " copying binary $($action.Path)"
            Copy-Item $file $LibraryPaths.Bin
        } else {
            # Place a link file in the library bin
            $linkFile = @"
@"%~dp0..\Packages\$_CurrentPackageRelativeDir\$($action.Path)" %*
"@
            if($action.Content) {
                $linkName = $action.Name
                $linkFile = $action.Content
            } elseif($action.UseStart) {
                $linkFile = @"
@start "launcher" "%~dp0..\Packages\$_CurrentPackageRelativeDir\$($action.Path)" %*
"@  
            }
            
            if(!$linkName) {
                $binaryName = [IO.Path]::GetFileNameWithoutExtension($action.Path)
                if($action.Name) {
                    $binaryName = $action.Name
                }

                $linkName = $binaryName + ".cmd"
            }
            
            $linkPath = Join-Path $LibraryPaths.Bin $linkName
            if(Test-Path $linkPath) {
                Remove-Item $linkPath
            }
            Write-InstallAction " placing binary link to $($action.Path)"
            $linkFile | Out-File -FilePath $linkPath -Encoding ascii
        }
    }
    "Uninstall"={throw "can't uninstall yet!"}
}

