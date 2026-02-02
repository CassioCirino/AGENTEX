@echo off
setlocal enableextensions

REM Usage:
REM install.cmd <DT_BASE_URL> <DT_API_TOKEN> [INSTALL_DIR] [EXE_PATH]
REM Example:
REM install.cmd https://<env>.live.dynatrace.com dt0c01... C:\Program Files\DtLegacyAgent
REM install.cmd https://<env>.live.dynatrace.com dt0c01... C:\Program Files\DtLegacyAgent C:\Temp\DtLegacyAgent.exe

if "%~1"=="" goto :usage
if "%~2"=="" goto :usage

set DT_BASE_URL=%~1
set DT_API_TOKEN=%~2
set INSTALL_DIR=%~3
set EXE_PATH=%~4
if "%INSTALL_DIR%"=="" set INSTALL_DIR=%ProgramFiles%\DtLegacyAgent
if "%EXE_PATH%"=="" (
  if exist "%~dp0DtLegacyAgent.exe" (
    set EXE_PATH=%~dp0DtLegacyAgent.exe
  ) else (
    if exist "%~dp0src\bin\Release\DtLegacyAgent.exe" (
      set EXE_PATH=%~dp0src\bin\Release\DtLegacyAgent.exe
    ) else (
      set EXE_PATH=%~dp0DtLegacyAgent.exe
      call :download_exe "%EXE_PATH%"
    )
  )
)

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

copy /y "%EXE_PATH%" "%INSTALL_DIR%\DtLegacyAgent.exe" >nul

REM Write config
(
  echo DT_BASE_URL=%DT_BASE_URL%
  echo DT_API_TOKEN=%DT_API_TOKEN%
  echo AGENT_OTLP_LISTEN=http://127.0.0.1:4318/
  echo AGENT_INTERVAL=15
  echo AGENT_HTTP_TIMEOUT=15
  echo AGENT_ENABLE_OTLP=true
  echo AGENT_ENABLE_METRICS=true
  echo AGENT_ENABLE_EVENTS=true
) > "%INSTALL_DIR%\agent.conf"

REM Install service
sc.exe stop DtLegacyAgent >nul 2>&1
sc.exe delete DtLegacyAgent >nul 2>&1
sc.exe create DtLegacyAgent binPath= "\"%INSTALL_DIR%\DtLegacyAgent.exe\"" start= auto DisplayName= "Dynatrace Legacy Agent"

REM Set config path for service
reg add "HKLM\SYSTEM\CurrentControlSet\Services\DtLegacyAgent" /v Environment /t REG_MULTI_SZ /d "AGENT_CONFIG=%INSTALL_DIR%\agent.conf" /f >nul

sc.exe start DtLegacyAgent

echo Installed. Service name: DtLegacyAgent
exit /b 0

:download_exe
set TARGET=%~1
if exist "%TARGET%" exit /b 0
set BASE=%AGENT_DOWNLOAD_BASE%
if "%BASE%"=="" set BASE=https://raw.githubusercontent.com/CassioCirino/AGENTEX/main/dist
echo Downloading DtLegacyAgent.exe from %BASE%

if exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" (
  "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "(New-Object Net.WebClient).DownloadFile('%BASE%/DtLegacyAgent.exe','%TARGET%')"
) else (
  if exist "%SystemRoot%\System32\bitsadmin.exe" (
    bitsadmin /transfer DtLegacyAgentDownload %BASE%/DtLegacyAgent.exe %TARGET%
  ) else (
    echo No PowerShell or bitsadmin available to download DtLegacyAgent.exe
    exit /b 2
  )
)

if not exist "%TARGET%" (
  echo Failed to download DtLegacyAgent.exe
  exit /b 2
)
exit /b 0

:usage
echo Usage: install.cmd ^<DT_BASE_URL^> ^<DT_API_TOKEN^> [INSTALL_DIR]
exit /b 1
