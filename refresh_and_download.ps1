<#
.SYNOPSIS
    Downloads Discord CDN media files (images, videos) before links expire.
    Updates JSON files with local file paths so HTML exports show media correctly.

.NOTES
    Discord Evidence Collector
    https://github.com/BeforeMyCompileFails/Discord-Evidence-Collector
    Author: https://github.com/BeforeMyCompileFails

.DESCRIPTION
    Discord CDN links expire after a short period. This script:
    1. Scans a JSON export file for Discord CDN attachment URLs
    2. Uses the Discord API to refresh expired URLs
    3. Downloads the files locally
    4. Updates the JSON so HTML exports display local files instead of broken CDN links

.PARAMETER Token
    Your child's Discord authentication token.

.PARAMETER JsonFile
    Path to the JSON export file to scan for media URLs.

.PARAMETER MediaFolder
    Folder where downloaded media files will be saved.

.EXAMPLE
    .\refresh_and_download.ps1 -Token "YOUR_TOKEN" -JsonFile "C:\Evidence\channel.json" -MediaFolder "C:\Evidence\MEDIA"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Token,

    [Parameter(Mandatory=$true)]
    [string]$JsonFile,

    [Parameter(Mandatory=$true)]
    [string]$MediaFolder
)

# ============================================================
# SETUP
# ============================================================

if (-not (Test-Path $JsonFile)) {
    Write-Host "[CDN] JSON file not found: $JsonFile" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $MediaFolder)) {
    New-Item -ItemType Directory -Path $MediaFolder -Force | Out-Null
}

Write-Host "[CDN] Scanning: $(Split-Path $JsonFile -Leaf)" -ForegroundColor Cyan

$jsonContent = Get-Content -Path $JsonFile -Raw -Encoding UTF8

# ============================================================
# FIND DISCORD CDN URLS
# ============================================================

# Extract all Discord CDN attachment URLs (strip query parameters for deduplication)
$pattern = 'https://cdn\.discordapp\.com/attachments/[^\s\x22\x27\?]+'
$matches = [regex]::Matches($jsonContent, $pattern)

$baseUrls = $matches.Value |
    ForEach-Object { $_ -replace '\?.*$', '' } |
    Select-Object -Unique

if ($baseUrls.Count -eq 0) {
    Write-Host "[CDN] No Discord CDN attachments found in this file." -ForegroundColor Gray
    exit 0
}

Write-Host "[CDN] Found $($baseUrls.Count) unique attachment(s). Processing..." -ForegroundColor Cyan

# ============================================================
# DOWNLOAD LOOP
# ============================================================

$downloaded = 0
$skipped    = 0
$failed     = 0
$urlMap     = @{}

foreach ($baseUrl in $baseUrls) {

    # Extract filename from URL
    $filename = $baseUrl -replace '.*/attachments/\d+/\d+/', ''
    $outPath  = Join-Path $MediaFolder $filename

    # Skip if already downloaded and file looks valid (>100 bytes)
    if ((Test-Path $outPath) -and (Get-Item $outPath).Length -gt 100) {
        $skipped++
        $urlMap[$baseUrl] = "MEDIA\$filename"
        continue
    }

    try {
        # Step 1: Refresh the CDN URL via Discord API
        $refreshEndpoint = "https://discord.com/api/v9/attachments/refresh-urls"
        $requestBody     = "{`"attachment_urls`":[`"$baseUrl`"]}"

        $headers = @{
            "Authorization" = $Token
            "Content-Type"  = "application/json"
            "User-Agent"    = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        }

        $response = Invoke-RestMethod `
            -Uri     $refreshEndpoint `
            -Method  Post `
            -Headers $headers `
            -Body    $requestBody `
            -ErrorAction Stop

        if ($response.refreshed_urls -and $response.refreshed_urls.Count -gt 0) {
            $freshUrl = $response.refreshed_urls[0].refreshed

            # Step 2: Download the file using the refreshed URL
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", "Mozilla/5.0")
            $webClient.DownloadFile($freshUrl, $outPath)
            $webClient.Dispose()

            $fileSizeMB = [math]::Round((Get-Item $outPath).Length / 1MB, 2)
            Write-Host "  [SAVED] $filename ($fileSizeMB MB)" -ForegroundColor Green
            $downloaded++

            $urlMap[$baseUrl] = "MEDIA\$filename"

        } else {
            Write-Host "  [SKIP] Could not refresh URL for: $filename" -ForegroundColor Yellow
            $failed++
        }

    } catch {
        Write-Host "  [FAIL] $filename - $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }

    # Small delay to avoid rate limiting
    Start-Sleep -Milliseconds 500
}

# ============================================================
# UPDATE JSON WITH LOCAL PATHS
# ============================================================

if ($urlMap.Count -gt 0) {

    Write-Host "[CDN] Updating JSON with local file paths..." -ForegroundColor Cyan

    # Back up the original JSON if no backup exists yet
    $backupPath = $JsonFile + ".backup"
    if (-not (Test-Path $backupPath)) {
        Copy-Item -Path $JsonFile -Destination $backupPath -Force
        Write-Host "[CDN] Backup saved: $(Split-Path $backupPath -Leaf)" -ForegroundColor Gray
    }

    $updatedJson = $jsonContent

    foreach ($oldUrl in $urlMap.Keys) {
        $localPath   = $urlMap[$oldUrl]
        # Replace the URL (including any query parameters) with the local path
        $urlPattern  = [regex]::Escape($oldUrl) + '[^\s\x22\x27]*'
        $updatedJson = [regex]::Replace($updatedJson, $urlPattern, $localPath)
    }

    Set-Content -Path $JsonFile -Value $updatedJson -Encoding UTF8 -NoNewline
    Write-Host "[CDN] JSON updated successfully." -ForegroundColor Green
}

# ============================================================
# SUMMARY
# ============================================================

Write-Host ""
Write-Host "[CDN] Done. Downloaded: $downloaded | Skipped (already existed): $skipped | Failed: $failed" -ForegroundColor Cyan

if ($failed -gt 0) {
    Write-Host "[CDN] Some files could not be downloaded. This may mean the links have fully expired." -ForegroundColor Yellow
    Write-Host "[CDN] Run the monitoring script earlier in future cases to avoid expiry." -ForegroundColor Yellow
}
