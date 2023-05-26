Push-Location (Resolve-Path -Path "$(Split-Path -parent $PSCommandpath)\..")
Write-Host "Updating $(Get-Location)\README.md"
            
$FinalFile = "$(Get-Location)\README.md"
$TemporaryFile = "$(Get-Location)\TMP_README.md"

# Generate new README
terraform-docs markdown "$(Get-Location)" --output-file "$TemporaryFile" | Out-Null

# Replace header
[IO.File]::WriteAllText($TemporaryFile, ([IO.File]::ReadAllText($TemporaryFile) -replace '<!-- BEGIN_TF_DOCS -->', '<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->'))

# Replace trailer
[IO.File]::WriteAllText($TemporaryFile, ([IO.File]::ReadAllText($TemporaryFile) -replace '<!-- END_TF_DOCS -->', '<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->'))

# Append final new line
[IO.File]::WriteAllText($FinalFile, ([IO.File]::ReadAllText($TemporaryFile) + "`n"))

# Remove intermediate file
Remove-Item -Path $TemporaryFile
Pop-Location

Get-ChildItem -Directory -Path "$(Split-Path -parent $PSCommandpath)\.." -Exclude docs,powershell,scripts | ForEach-Object {
    Get-ChildItem -Directory -Path "$($_.FullName)" | ForEach-Object {
        if ([bool](Test-Path -Path "$($_.FullName)\main.tf")) {
            Write-Host "Updating $($_.FullName)\README.md"
            
            $FinalFile = "$($_.FullName)\README.md"
            $TemporaryFile = "$($_.FullName)\TMP_README.md"

            # Generate new README
            terraform-docs markdown "$($_.FullName)" --output-file "$TemporaryFile" | Out-Null

            # Replace header
            [IO.File]::WriteAllText($TemporaryFile, ([IO.File]::ReadAllText($TemporaryFile) -replace '<!-- BEGIN_TF_DOCS -->', '<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->'))

            # Replace trailer
            [IO.File]::WriteAllText($TemporaryFile, ([IO.File]::ReadAllText($TemporaryFile) -replace '<!-- END_TF_DOCS -->', '<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->'))

            # Append final new line
            [IO.File]::WriteAllText($FinalFile, ([IO.File]::ReadAllText($TemporaryFile) + "`n"))

            # Remove intermediate file
            Remove-Item -Path $TemporaryFile

        }
    }
}

