@echo off

rem update path to include git
set PATH=%USERPROFILE%\AppData\Local\Programs\Git\bin;%PATH%

rem update PATH to include local bin folder
set PATH=%~dp0bin;%PATH%

rem update variables for 99designs/aws-vault
set AWS_SDK_LOAD_CONFIG=1

rem run local configurations if present
if exist "%~dp0env.local.bat" (
  call "%~dp0env.local.bat"
)
