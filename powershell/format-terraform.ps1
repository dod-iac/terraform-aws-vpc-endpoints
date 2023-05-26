Push-Location (Resolve-Path -Path "$(Split-Path -parent $PSCommandpath)\..")
Write-Host "Formatting $(Get-Location)"
terraform fmt
Pop-Location

Get-ChildItem -Directory -Path "$(Split-Path -parent $PSCommandpath)\.." -Exclude docs,powershell,scripts | ForEach-Object {
    Get-ChildItem -Directory -Path "$($_.FullName)" | ForEach-Object {
        if ([bool](Test-Path -Path "$($_.FullName)\main.tf")) {
            Write-Host "Formatting $($_.FullName)"
            Push-Location $_.FullName
            terraform fmt
            Pop-Location
        }
    }
}

