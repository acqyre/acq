Import-Module $PSScriptRoot\Acqyre.psd1
try {
    acq @args
} finally {
    Remove-Module Acqyre
}
