@echo off
setlocal EnableDelayedExpansion
title Discord Evidence Monitor - Running
color 0A

:: Discord Evidence Collector
:: https://github.com/BeforeMyCompileFails/Discord-Evidence-Collector
:: Author: https://github.com/BeforeMyCompileFails
::

echo ============================================================
echo   DISCORD EVIDENCE MONITOR - Continuous Capture
echo   Checks for new messages every 5 minutes
echo ============================================================
echo.
echo Use this when you want to capture ongoing activity over time.
echo The script runs in a loop and saves a new snapshot whenever
echo new messages are detected.
echo.
echo Press Ctrl+C at any time to stop monitoring.
echo.
echo BEFORE YOU START:
echo   - You need your child's Discord TOKEN (see README.md)
echo   - You need up to 3 Channel IDs to monitor (see README.md)
echo   - Keep this window open while monitoring
echo.
echo Press any key to continue, or close this window to cancel.
pause >nul

:: ============================================================
:: LOCATE TOOL
:: ============================================================
set "SCRIPT_DIR=%~dp0"
set "TOOLS_DIR=%SCRIPT_DIR%..\tools"
set "DCE=%TOOLS_DIR%\DiscordChatExporter.Cli.exe"
set "PS_SCRIPT=%SCRIPT_DIR%refresh_and_download.ps1"

if not exist "%DCE%" (
    echo.
    echo [ERROR] DiscordChatExporter.Cli.exe not found in tools\ folder.
    echo Please run setup\download_dce.bat first.
    echo.
    pause
    exit /b 1
)

:: ============================================================
:: CONFIGURATION
:: ============================================================
echo.
echo ============================================================
echo   CONFIGURATION
echo ============================================================
echo.

:: Token
echo Paste your child's Discord token and press Enter:
set /p "TOKEN=Token: "
if "%TOKEN%"=="" (
    echo [ERROR] No token entered. Exiting.
    pause
    exit /b 1
)

:: Output folder
echo.
set "DEFAULT_OUTPUT=%USERPROFILE%\Desktop\DiscordMonitor_%DATE:~-4,4%%DATE:~-7,2%%DATE:~-10,2%"
echo Where should monitoring captures be saved?
echo Press Enter for default, or type a path:
set /p "OUTPUT=Output folder [%DEFAULT_OUTPUT%]: "
if "%OUTPUT%"=="" set "OUTPUT=%DEFAULT_OUTPUT%"

:: Channels - up to 3
echo.
echo How many channels/DMs do you want to monitor? (1, 2, or 3)
set /p "NUM_CH=Number of channels: "
if "%NUM_CH%"=="" set NUM_CH=1
if %NUM_CH% GTR 3 set NUM_CH=3
if %NUM_CH% LSS 1 set NUM_CH=1

set CH1_ID=
set CH1_NAME=
set CH2_ID=
set CH2_NAME=
set CH3_ID=
set CH3_NAME=

echo.
echo Enter Channel ID and a short label for each channel:
echo.

echo --- Channel 1 ---
set /p "CH1_ID=Channel 1 ID: "
set /p "CH1_NAME=Channel 1 label (no spaces, e.g. general or DM_John): "

if %NUM_CH% GEQ 2 (
    echo.
    echo --- Channel 2 ---
    set /p "CH2_ID=Channel 2 ID: "
    set /p "CH2_NAME=Channel 2 label: "
)

if %NUM_CH% GEQ 3 (
    echo.
    echo --- Channel 3 ---
    set /p "CH3_ID=Channel 3 ID: "
    set /p "CH3_NAME=Channel 3 label: "
)

:: Check for CDN script
if not exist "%PS_SCRIPT%" (
    echo.
    echo [NOTE] refresh_and_download.ps1 not found in scripts\ folder.
    echo        Videos from Discord CDN may expire and not be saved.
    echo        Make sure all scripts from the repository are present.
    echo.
)

:: Create output dirs
mkdir "%OUTPUT%\SNAPSHOTS" 2>nul
mkdir "%OUTPUT%\MEDIA" 2>nul
mkdir "%OUTPUT%\TEMP" 2>nul

set "LOGFILE=%OUTPUT%\monitor_log.txt"
set "COUNT=0"
set "ERRORS=0"

echo.
echo ============================================================
echo   Monitoring started. Press Ctrl+C to stop.
echo   Captures saved to: %OUTPUT%
echo ============================================================
echo.

echo Discord Evidence Monitor - Log > "%LOGFILE%"
echo Started: %DATE% %TIME% >> "%LOGFILE%"
echo Monitoring %NUM_CH% channel(s) >> "%LOGFILE%"
echo. >> "%LOGFILE%"

:: ============================================================
:: MONITORING LOOP
:: ============================================================
:loop
set /a COUNT+=1

:: Timestamp for this cycle (safe for filenames)
for /f "tokens=1-3 delims=/ " %%a in ("%DATE%") do set "DATEPART=%%c%%b%%a"
for /f "tokens=1-3 delims=:." %%a in ("%TIME: =0%") do set "TIMEPART=%%a%%b%%c"
set "TIMESTAMP=%DATEPART%_%TIMEPART%"

echo.
echo ============================
echo  Cycle #%COUNT% - %DATE% %TIME%
echo ============================

echo [%DATE% %TIME%] --- Cycle #%COUNT% --- >> "%LOGFILE%"

:: ---- CHANNEL 1 (always present) ----
:: --delay 20000 = 20 second pause between internal page requests
:: This prevents Discord from rate-limiting or flagging the account
if not "%CH1_ID%"=="" (
    echo [%CH1_NAME%] Capturing...
    "%DCE%" export -t "%TOKEN%" -c "%CH1_ID%" -o "%OUTPUT%\TEMP\%CH1_NAME%_NEW.json" -f Json --delay 20000 2>nul

    if exist "%OUTPUT%\TEMP\%CH1_NAME%_NEW.json" (
        call :compare_and_save "%CH1_NAME%"
    ) else (
        echo [!] %CH1_NAME%: Export failed - channel may have been deleted!
        echo [%TIME%] FAILED - %CH1_NAME% may have been deleted >> "%LOGFILE%"
        set /a ERRORS+=1
    )
)

:: 20 second pause between channel exports
if not "%CH2_ID%"=="" timeout /t 20 /nobreak >nul

:: ---- CHANNEL 2 (if configured) ----
if not "%CH2_ID%"=="" (
    echo [%CH2_NAME%] Capturing...
    "%DCE%" export -t "%TOKEN%" -c "%CH2_ID%" -o "%OUTPUT%\TEMP\%CH2_NAME%_NEW.json" -f Json --delay 20000 2>nul

    if exist "%OUTPUT%\TEMP\%CH2_NAME%_NEW.json" (
        call :compare_and_save "%CH2_NAME%"
    ) else (
        echo [!] %CH2_NAME%: Export failed - channel may have been deleted!
        echo [%TIME%] FAILED - %CH2_NAME% may have been deleted >> "%LOGFILE%"
        set /a ERRORS+=1
    )
)

:: 20 second pause between channel exports
if not "%CH3_ID%"=="" timeout /t 20 /nobreak >nul

:: ---- CHANNEL 3 (if configured) ----
if not "%CH3_ID%"=="" (
    echo [%CH3_NAME%] Capturing...
    "%DCE%" export -t "%TOKEN%" -c "%CH3_ID%" -o "%OUTPUT%\TEMP\%CH3_NAME%_NEW.json" -f Json --delay 20000 2>nul

    if exist "%OUTPUT%\TEMP\%CH3_NAME%_NEW.json" (
        call :compare_and_save "%CH3_NAME%"
    ) else (
        echo [!] %CH3_NAME%: Export failed - channel may have been deleted!
        echo [%TIME%] FAILED - %CH3_NAME% may have been deleted >> "%LOGFILE%"
        set /a ERRORS+=1
    )
)

:: ---- CDN MEDIA REFRESH ----
if exist "%PS_SCRIPT%" (
    echo [MEDIA] Downloading/refreshing media files...
    for %%F in ("%OUTPUT%\SNAPSHOTS\*_LATEST.json") do (
        powershell -ExecutionPolicy Bypass -File "%PS_SCRIPT%" ^
            -Token "%TOKEN%" ^
            -JsonFile "%%F" ^
            -MediaFolder "%OUTPUT%\MEDIA" 2>nul
    )
)

echo.
echo Cycle #%COUNT% done. Errors this session: %ERRORS%
echo Waiting 5 minutes before next capture...
echo (Press Ctrl+C to stop)
echo.
timeout /t 300 /nobreak >nul

goto loop

:: ============================================================
:: SUBROUTINE: Compare new file to previous, save if changed
:: ============================================================
:compare_and_save
set "CHNAME=%~1"
set "NEWFILE=%OUTPUT%\TEMP\%CHNAME%_NEW.json"
set "PREVFILE=%OUTPUT%\TEMP\%CHNAME%_PREV.json"
set "SAVEFILE=%OUTPUT%\SNAPSHOTS\%CHNAME%_%TIMESTAMP%.json"
set "LATESTFILE=%OUTPUT%\SNAPSHOTS\%CHNAME%_LATEST.json"

powershell -ExecutionPolicy Bypass -Command ^
"$new = '%NEWFILE%'; ^
$prev = '%PREVFILE%'; ^
$save = '%SAVEFILE%'; ^
$latest = '%LATESTFILE%'; ^
$log = '%LOGFILE%'; ^
$name = '%CHNAME%'; ^
try { ^
    if (Test-Path $prev) { ^
        $newSize = (Get-Item $new).Length; ^
        $prevSize = (Get-Item $prev).Length; ^
        $changed = $false; ^
        if ($newSize -ne $prevSize) { ^
            $changed = $true; ^
            Write-Host ('  [' + $name + '] NEW MESSAGES DETECTED (size changed)') -ForegroundColor Green; ^
        } else { ^
            $h1 = (Get-FileHash $new -Algorithm MD5).Hash; ^
            $h2 = (Get-FileHash $prev -Algorithm MD5).Hash; ^
            if ($h1 -ne $h2) { ^
                $changed = $true; ^
                Write-Host ('  [' + $name + '] NEW MESSAGES DETECTED (content changed)') -ForegroundColor Green; ^
            } else { ^
                Write-Host ('  [' + $name + '] No new messages.') -ForegroundColor Gray; ^
            } ^
        } ^
        if ($changed) { ^
            Copy-Item $new $save -Force; ^
            Copy-Item $new $prev -Force; ^
            Copy-Item $new $latest -Force; ^
            Add-Content $log \"[$((Get-Date).ToString('HH:mm:ss'))] CHANGED - saved $($name)_snapshot\"; ^
        } ^
    } else { ^
        Write-Host ('  [' + $name + '] First capture - saving baseline.') -ForegroundColor Yellow; ^
        Copy-Item $new $save -Force; ^
        Copy-Item $new $prev -Force; ^
        Copy-Item $new $latest -Force; ^
        Add-Content $log \"[$((Get-Date).ToString('HH:mm:ss'))] FIRST CAPTURE - $name\"; ^
    } ^
} catch { ^
    Write-Host ('  [ERROR] ' + $_.Exception.Message) -ForegroundColor Red; ^
}"

goto :eof
