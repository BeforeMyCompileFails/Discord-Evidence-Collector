@echo off
title Discord Evidence Collector - Setup
color 0A

:: Discord Evidence Collector
:: https://github.com/BeforeMyCompileFails/Discord-Evidence-Collector
:: Author: https://github.com/BeforeMyCompileFails
::

echo ============================================================
echo   SETUP: Downloading DiscordChatExporter (pinned v2.43.3)
echo ============================================================
echo.
echo This will download DiscordChatExporter CLI into the tools\ folder.
echo Pinned to version 2.43.3 for guaranteed compatibility.
echo.
echo Original project: https://github.com/Tyrrrz/DiscordChatExporter
echo License: MIT
echo.
pause

:: Create tools directory
if not exist "%~dp0..\tools" mkdir "%~dp0..\tools"

echo.
echo [1/3] Downloading DiscordChatExporter.Cli.zip ...
echo.

powershell -ExecutionPolicy Bypass -Command ^
"$url = 'https://github.com/Tyrrrz/DiscordChatExporter/releases/download/2.43.3/DiscordChatExporter.Cli.zip'; ^
$out = '%~dp0..\tools\DiscordChatExporter.Cli.zip'; ^
try { ^
    $wc = New-Object System.Net.WebClient; ^
    $wc.DownloadFile($url, $out); ^
    Write-Host 'Download complete.' -ForegroundColor Green; ^
} catch { ^
    Write-Host 'ERROR: Download failed.' -ForegroundColor Red; ^
    Write-Host $_.Exception.Message; ^
    exit 1; ^
}"

if not exist "%~dp0..\tools\DiscordChatExporter.Cli.zip" (
    echo.
    echo [ERROR] Download failed. Please download manually:
    echo   https://github.com/Tyrrrz/DiscordChatExporter/releases/tag/2.43.3
    echo   Extract DiscordChatExporter.Cli.zip into the tools\ folder.
    pause
    exit /b 1
)

echo.
echo [2/3] Extracting...
echo.

powershell -ExecutionPolicy Bypass -Command ^
"Expand-Archive -Path '%~dp0..\tools\DiscordChatExporter.Cli.zip' -DestinationPath '%~dp0..\tools' -Force; ^
Write-Host 'Extraction complete.' -ForegroundColor Green;"

echo.
echo [3/3] Verifying...
echo.

if exist "%~dp0..\tools\DiscordChatExporter.Cli.exe" (
    echo [OK] DiscordChatExporter.Cli.exe found.
    echo.
    echo ============================================================
    echo   Setup complete! You can now run the scripts in scripts\
    echo ============================================================
) else (
    echo [ERROR] DiscordChatExporter.Cli.exe not found after extraction.
    echo Please extract the zip manually into the tools\ folder.
)

echo.
pause
