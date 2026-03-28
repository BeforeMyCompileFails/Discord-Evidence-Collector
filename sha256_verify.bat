@echo off
setlocal EnableDelayedExpansion
title Discord Evidence Collector - Generate SHA256 Checksums
color 0A

:: Discord Evidence Collector
:: https://github.com/BeforeMyCompileFails/Discord-Evidence-Collector
:: Author: https://github.com/BeforeMyCompileFails
::

echo ============================================================
echo   SHA256 CHECKSUM GENERATOR
echo   For court admissibility / chain of custody
echo ============================================================
echo.
echo This script generates a SHA256 cryptographic hash for every
echo file in your evidence folder.
echo.
echo WHY THIS MATTERS:
echo   A SHA256 hash is a unique "fingerprint" for each file.
echo   If even one byte changes, the hash changes completely.
echo   This proves to a court that the evidence has not been
echo   altered since it was collected.
echo.
echo Give the CHECKSUMS.txt file to law enforcement along with
echo your evidence folder.
echo.

:: ============================================================
:: GET EVIDENCE FOLDER
:: ============================================================

:: If a path was passed as an argument, use it
if not "%~1"=="" (
    set "EVIDENCE_DIR=%~1"
    echo Using folder: %~1
    goto generate
)

echo Enter the full path to your evidence folder and press Enter.
echo (This is the folder created by collect_evidence.bat or monitor.bat)
echo.
set /p "EVIDENCE_DIR=Evidence folder path: "

if "%EVIDENCE_DIR%"=="" (
    echo [ERROR] No folder entered. Exiting.
    pause
    exit /b 1
)

if not exist "%EVIDENCE_DIR%" (
    echo [ERROR] Folder not found: %EVIDENCE_DIR%
    pause
    exit /b 1
)

:generate
echo.
echo ============================================================
echo   Generating checksums for all files in:
echo   %EVIDENCE_DIR%
echo ============================================================
echo.

set "OUTFILE=%EVIDENCE_DIR%\CHECKSUMS.txt"

echo SHA256 Checksums - Discord Evidence Collection > "%OUTFILE%"
echo Generated: %DATE% %TIME% >> "%OUTFILE%"
echo Evidence folder: %EVIDENCE_DIR% >> "%OUTFILE%"
echo. >> "%OUTFILE%"
echo ---------------------------------------- >> "%OUTFILE%"
echo. >> "%OUTFILE%"

set "COUNT=0"

for /r "%EVIDENCE_DIR%" %%F in (*) do (
    :: Skip the checksums file itself and backup files
    if /i not "%%~nxF"=="CHECKSUMS.txt" (
        if /i not "%%~xF"==".backup" (
            set /a COUNT+=1
            echo Hashing: %%~nxF

            for /f "skip=1 tokens=* delims=" %%H in ('certutil -hashfile "%%F" SHA256 2^>nul') do (
                if not defined HASH_%%COUNT%% (
                    set "CURRENT_HASH=%%H"
                )
            )

            powershell -ExecutionPolicy Bypass -Command ^
            "$hash = (Get-FileHash '%%F' -Algorithm SHA256).Hash; ^
            $relPath = '%%F' -replace [regex]::Escape('%EVIDENCE_DIR%\'), ''; ^
            $size = (Get-Item '%%F').Length; ^
            $line = $hash + '  ' + $relPath + '  (' + $size + ' bytes)'; ^
            Add-Content '%OUTFILE%' $line;"
        )
    )
)

echo.
echo ---------------------------------------- >> "%OUTFILE%"
echo. >> "%OUTFILE%"
echo Total files hashed: %COUNT% >> "%OUTFILE%"
echo. >> "%OUTFILE%"
echo HOW TO VERIFY: >> "%OUTFILE%"
echo   In PowerShell: Get-FileHash "path\to\file.json" -Algorithm SHA256 >> "%OUTFILE%"
echo   The output hash must match the hash listed above. >> "%OUTFILE%"

echo.
echo ============================================================
echo   Done! %COUNT% files hashed.
echo   Checksums saved to: %OUTFILE%
echo ============================================================
echo.
echo Include CHECKSUMS.txt when handing evidence to police.
echo It proves the files have not been modified.
echo.
pause
