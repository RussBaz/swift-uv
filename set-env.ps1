$inc = Read-Host "Please specify the path to 'uv.h' location"
$lnk = Read-Host "Please specify the path to 'uv.lib' location"

Write-Host "Would you like to copy the 'uv.dll' to the root of this project?"
$copy = Read-Host “Yes/No [default yes]”

If($copy -ne “No” -and $copy -ne “no”){
    $copyPath = Read-Host "Please specify the full path to 'uv.dll'"
    Copy-Item -Path $copyPath -Destination .
}
