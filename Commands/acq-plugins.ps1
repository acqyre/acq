$AcqyrePlugins.Keys | ForEach-Object {
    Write-Host "$_ Plugins"
    $AcqyrePlugins[$_].Keys | ForEach-Object {
        "* $_"
    }
}
