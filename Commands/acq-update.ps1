param([switch]$Force)
# Update collections
dir $LibraryPaths.Collections | ForEach-Object {
    $owner = $_.Name
    dir $_.FullName | ForEach-Object {
        Write-Host -ForegroundColor Green "Updating $owner/$($_.Name) ..."
        pushd $_.FullName
        if($Force) {
            git reset --hard
            git clean --force
        }
        git pull origin master
        popd
    }
}

# Update Acq
Write-Host -ForegroundColor Green "Updating Acqyre ..."
pushd $LibraryPaths.Acq
git pull origin master
popd
