@echo off
setlocal enableextensions

sc.exe stop DtLegacyAgent >nul 2>&1
sc.exe delete DtLegacyAgent >nul 2>&1

echo Removed service DtLegacyAgent
exit /b 0