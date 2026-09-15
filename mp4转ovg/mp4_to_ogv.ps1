# MP4/MOV -> OGV for Godot (Theora + Vorbis)
# Usage: drag files/folders onto mp4_to_ogv.bat, or:
#   powershell -File mp4_to_ogv.ps1 path1 path2 ...

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Inputs
)

$ErrorActionPreference = "Continue"

# Optional: set absolute path if ffmpeg is not on PATH
$FfmpegFallback = "E:\浏览器下载\ffmpeg-2026-08-06-git-95c43d7df7-essentials_build\ffmpeg-2026-08-06-git-95c43d7df7-essentials_build\bin\ffmpeg.exe"

function Resolve-Ffmpeg {
    if ($env:FFMPEG -and (Test-Path -LiteralPath $env:FFMPEG)) {
        return $env:FFMPEG
    }
    $cmd = Get-Command ffmpeg -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    if ($FfmpegFallback -and (Test-Path -LiteralPath $FfmpegFallback)) {
        return $FfmpegFallback
    }
    return $null
}

function Get-VideoFiles {
    param([string[]]$Paths)
    $exts = @(".mp4", ".mov", ".MP4", ".MOV")
    $files = New-Object System.Collections.Generic.List[string]
    foreach ($p in $Paths) {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }
        $p = $p.Trim('"')
        if (-not (Test-Path -LiteralPath $p)) {
            Write-Host "[skip] not found: $p" -ForegroundColor Yellow
            continue
        }
        $item = Get-Item -LiteralPath $p
        if ($item.PSIsContainer) {
            Get-ChildItem -LiteralPath $item.FullName -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $exts -contains $_.Extension } |
                ForEach-Object { $files.Add($_.FullName) }
        }
        elseif ($exts -contains $item.Extension) {
            $files.Add($item.FullName)
        }
        else {
            Write-Host "[skip] not mp4/mov: $p" -ForegroundColor Yellow
        }
    }
    return $files
}

$ffmpeg = Resolve-Ffmpeg
if (-not $ffmpeg) {
    Write-Host ""
    Write-Host "ffmpeg.exe not found." -ForegroundColor Red
    Write-Host "1) Install FFmpeg and add it to PATH, or"
    Write-Host "2) Edit FfmpegFallback at the top of mp4_to_ogv.ps1"
    Write-Host ""
    Write-Host "Download: https://www.gyan.dev/ffmpeg/builds/ (essentials)"
    exit 1
}

if (-not $Inputs -or $Inputs.Count -eq 0) {
    Write-Host "Drag .mp4/.mov files or a folder onto mp4_to_ogv.bat"
    Write-Host "Or: .\mp4_to_ogv.ps1 `"C:\path\to\video.mp4`""
    exit 0
}

Write-Host "Using ffmpeg: $ffmpeg"
$videos = Get-VideoFiles -Paths $Inputs
if ($videos.Count -eq 0) {
    Write-Host "No .mp4/.mov files to convert." -ForegroundColor Yellow
    exit 0
}

$ok = 0
$skip = 0
$fail = 0

foreach ($src in $videos) {
    $out = [System.IO.Path]::ChangeExtension($src, ".ogv")
    if (Test-Path -LiteralPath $out) {
        Write-Host "[skip] exists: $out"
        $skip++
        continue
    }
    Write-Host "[convert] $src"
    & $ffmpeg -hide_banner -loglevel error -n -i $src -c:v libtheora -q:v 7 -c:a libvorbis -q:a 5 $out
    if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $out)) {
        Write-Host "  -> $out" -ForegroundColor Green
        $ok++
    }
    else {
        Write-Host "  FAILED (exit $LASTEXITCODE)" -ForegroundColor Red
        $fail++
    }
}

Write-Host ""
Write-Host "Done. ok=$ok  skip=$skip  fail=$fail  total=$($videos.Count)"
