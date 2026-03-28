@echo off
setlocal EnableDelayedExpansion
title Discord Evidence Collector - One-Time Export
color 0A

:: Discord Evidence Collector
:: https://github.com/BeforeMyCompileFails/Discord-Evidence-Collector
:: Author: https://github.com/BeforeMyCompileFails
::

echo ============================================================
echo   DISCORD EVIDENCE COLLECTOR - One-Time Channel Export
echo   For parents collecting evidence for law enforcement
echo ============================================================
echo.
echo This script will export Discord channels and/or DM conversations
echo to HTML files (viewable in browser) and JSON files (raw data).
echo.
echo BEFORE YOU START:
echo   - You need your child's Discord TOKEN (see README.md for how)
echo   - You need the CHANNEL ID(s) you want to export (see README.md)
echo   - Do NOT close this window while exporting
echo.
echo Press any key to continue, or close this window to cancel.
pause >nul

:: ============================================================
:: LOCATE TOOL
:: ============================================================
set "SCRIPT_DIR=%~dp0"
set "TOOLS_DIR=%SCRIPT_DIR%..\tools"
set "DCE=%TOOLS_DIR%\DiscordChatExporter.Cli.exe"

if not exist "%DCE%" (
    echo.
    echo [ERROR] DiscordChatExporter.Cli.exe not found in tools\ folder.
    echo.
    echo Please run setup\download_dce.bat first, or read README.md
    echo for manual setup instructions.
    echo.
    pause
    exit /b 1
)

:: ============================================================
:: GET TOKEN
:: ============================================================
echo.
echo ============================================================
echo   STEP 1 OF 4 - Your Discord Token
echo ============================================================
echo.
echo Paste your child's Discord token below and press Enter.
echo (The token will not be shown on screen for security.)
echo.
echo If you don't have a token yet, see README.md for instructions.
echo.

set /p "TOKEN=Token: "

if "%TOKEN%"=="" (
    echo [ERROR] No token entered. Exiting.
    pause
    exit /b 1
)

:: ============================================================
:: GET OUTPUT FOLDER
:: ============================================================
echo.
echo ============================================================
echo   STEP 2 OF 4 - Evidence Output Folder
echo ============================================================
echo.
echo Where should the evidence be saved?
echo.
echo Press Enter to use the default (a folder on your Desktop),
echo or type a full path (e.g. D:\Evidence) and press Enter.
echo.

set "DEFAULT_OUTPUT=%USERPROFILE%\Desktop\DiscordEvidence_%DATE:~-4,4%%DATE:~-7,2%%DATE:~-10,2%"
set /p "OUTPUT=Output folder [%DEFAULT_OUTPUT%]: "

if "%OUTPUT%"=="" set "OUTPUT=%DEFAULT_OUTPUT%"

:: Create output directories
mkdir "%OUTPUT%\HTML" 2>nul
mkdir "%OUTPUT%\JSON" 2>nul
mkdir "%OUTPUT%\MEDIA" 2>nul

echo.
echo Evidence will be saved to: %OUTPUT%

:: ============================================================
:: GET CHANNELS
:: ============================================================
echo.
echo ============================================================
echo   STEP 3 OF 4 - Channels / DMs to Export
echo ============================================================
echo.
echo How many channels or DM conversations do you want to export?
echo You can enter 1 to 20. If unsure, start with 1 to test.
echo.

set /p "NUM_CHANNELS=Number of channels: "

if "%NUM_CHANNELS%"=="" set NUM_CHANNELS=1

set CHANNEL_COUNT=0

:collect_channels
if %CHANNEL_COUNT% GEQ %NUM_CHANNELS% goto start_export

set /a CHANNEL_COUNT+=1
echo.
echo --- Channel %CHANNEL_COUNT% of %NUM_CHANNELS% ---
echo.
echo Paste the Channel ID (a long number, e.g. 1234567890123456789):
set /p "CH_ID_%CHANNEL_COUNT%=Channel ID: "

echo Give this channel a short name (used for the filename, no spaces):
set /p "CH_NAME_%CHANNEL_COUNT%=Label (e.g. general or DM_John): "

goto collect_channels

:: ============================================================
:: EXPORT
:: ============================================================
:start_export
echo.
echo ============================================================
echo   STEP 4 OF 4 - Exporting (please wait)
echo ============================================================
echo.

set "LOGFILE=%OUTPUT%\export_log.txt"
set "ERRORS=0"

echo Discord Evidence Collector - Export Log > "%LOGFILE%"
echo Started: %DATE% %TIME% >> "%LOGFILE%"
echo Output: %OUTPUT% >> "%LOGFILE%"
echo. >> "%LOGFILE%"

set CHANNEL_COUNT=0

:export_loop
if %CHANNEL_COUNT% GEQ %NUM_CHANNELS% goto export_done

set /a CHANNEL_COUNT+=1

:: Retrieve the stored channel ID and name for this iteration
:: We use call to evaluate the variable names dynamically
call set "CURRENT_ID=%%CH_ID_%CHANNEL_COUNT%%%"
call set "CURRENT_NAME=%%CH_NAME_%CHANNEL_COUNT%%%"

echo.
echo [%CHANNEL_COUNT%/%NUM_CHANNELS%] Exporting: %CURRENT_NAME% (ID: %CURRENT_ID%)
echo [%TIME%] Exporting %CURRENT_NAME% (ID: %CURRENT_ID%) >> "%LOGFILE%"

:: Export JSON
:: --delay 20000 = 20 second pause between page requests inside DCE
:: This is critical to avoid Discord rate-limiting or flagging the account
"%DCE%" export ^
    -t "%TOKEN%" ^
    -c "%CURRENT_ID%" ^
    -o "%OUTPUT%\JSON\%CURRENT_NAME%.json" ^
    -f Json ^
    --media ^
    --media-dir "%OUTPUT%\MEDIA" ^
    --reuse-media ^
    --delay 20000

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Export failed for %CURRENT_NAME% >> "%LOGFILE%"
    echo [!] WARNING: Export of %CURRENT_NAME% failed. Channel may not be accessible.
    set /a ERRORS+=1
) else (
    echo [OK] JSON exported: %CURRENT_NAME%.json >> "%LOGFILE%"
    echo [OK] JSON saved.
)

:: Pause between JSON and HTML export of the same channel
echo        Waiting 20 seconds before HTML conversion...
timeout /t 20 /nobreak >nul

:: Export HTML (human-readable)
echo        Converting to HTML...
"%DCE%" export ^
    -t "%TOKEN%" ^
    -c "%CURRENT_ID%" ^
    -o "%OUTPUT%\HTML\%CURRENT_NAME%.html" ^
    -f HtmlDark ^
    --media ^
    --media-dir "%OUTPUT%\MEDIA" ^
    --reuse-media ^
    --delay 20000

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] HTML export failed for %CURRENT_NAME% >> "%LOGFILE%"
    echo [!] WARNING: HTML conversion failed for %CURRENT_NAME%.
    set /a ERRORS+=1
) else (
    echo [OK] HTML exported: %CURRENT_NAME%.html >> "%LOGFILE%"
    echo [OK] HTML saved.
)

:: 20 second pause between channels before the next export
echo        Waiting 20 seconds before next channel...
timeout /t 20 /nobreak >nul
goto export_loop

:export_done
echo.
echo ============================================================
echo   Export complete! Errors: %ERRORS%
echo ============================================================
echo.
echo Finished: %DATE% %TIME% >> "%LOGFILE%"
echo Total errors: %ERRORS% >> "%LOGFILE%"

if %ERRORS% GTR 0 (
    echo Some channels failed to export. This may mean:
    echo   - You no longer have access to that channel
    echo   - The channel or server was deleted
    echo   - The token is incorrect
    echo.
    echo IMPORTANT: A deleted server or channel is itself evidence.
    echo Note the date and time this happened in your statement to police.
    echo.
)

echo Your evidence files are saved here:
echo   %OUTPUT%
echo.
echo HTML files (open in browser):  %OUTPUT%\HTML\
echo JSON files (raw data):         %OUTPUT%\JSON\
echo Media files (images/videos):   %OUTPUT%\MEDIA\
echo Export log:                    %OUTPUT%\export_log.txt
echo.
echo ---------------------------------------------------------
echo NEXT STEP: Run sha256_verify.bat to generate checksums
echo for court admissibility. This proves files are unaltered.
echo ---------------------------------------------------------
echo.

:: Ask if they want to run checksum tool now
set /p "RUN_CHECKSUMS=Generate SHA256 checksums now? (Y/N): "
if /i "%RUN_CHECKSUMS%"=="Y" (
    call "%SCRIPT_DIR%sha256_verify.bat" "%OUTPUT%"
)

echo.
echo Done. You can close this window.
echo.
pause
