Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction']='Stop'
function ThrowOnNativeFailure {
    if (-not $?)
    {
        throw 'Native Failure'
    }
}

$dir = Split-Path -parent $PSCommandpath

$path_parts = $env:PATH.Split(";")

if (-Not ($path_parts -contains "$env:LOCALAPPDATA\Programs\Git\bin")) {
    Write-Host "Prepending git directory to PATH: $env:LOCALAPPDATA\Programs\Git\bin"
    $env:PATH = "{0};{1}" -f "$env:LOCALAPPDATA\Programs\Git\bin", $env:PATH
}

if (-Not ($path_parts -contains "$dir\bin")) {
    Write-Host "Prepending local bin directory to PATH: $dir\bin"
    $env:PATH = "{0};{1}" -f "$dir\bin", $env:PATH
}

# update variables for 99designs/aws-vault
$env:AWS_SDK_LOAD_CONFIG = "1"

if ([bool](Test-Path -Path "$dir\env.local.ps1")) {
    Write-Host "Detected local modifications to environmental configuration: $dir\env.local.ps1"
    . $dir\env.local.ps1
}
