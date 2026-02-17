@echo off

powershell -command "exit $psversiontable.psversion.major"
IF %errorlevel% geq 3 (goto Menu) ELSE (goto Prompt)

:Menu
powershell -Command "& {unblock-file .\bin\EPPlus.dll}"
powershell -Command "& {unblock-file .\bin\Modules\ssh-sessions\Renci.SshNet35.dll}"
powershell -executionpolicy bypass .\Menu-CRG.ps1
goto :EOF

:Prompt
echo CRG 5.0.0.x requires Powershell Version 3.0 or above.
set /p ask=Would you like me to open the Microsoft Download site? (y/n)
if %ask%==y (start https://www.microsoft.com/en-us/download/details.aspx?id=40855)
goto :EOF