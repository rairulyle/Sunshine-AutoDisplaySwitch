

param (
    [string]$mode = ""
)

$validModes = @("external", "internal", "clone", "extend")

if ($validModes -contains $mode) {
    DisplaySwitch.exe /$mode
}
else {
    Write-Output "Use one of the following options:"
    Write-Output "  internal = (1) Primary Screen Only"
    Write-Output "  external = (2) Second Screen Only"
    Write-Output "  clone    = (3) Duplicate"
    Write-Output "  extend   = (4) Extend"
}
