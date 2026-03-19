# ============================================================
#  Pyodide Desktop - Download Offline Runtime + Science Packages
#  策略：先下載 pyodide-lock.json，動態解析出正確檔名，
#        再遞迴展開依賴，一次全部下載
# ============================================================
$ErrorActionPreference = "Stop"

$Version = "0.27.3"
$Base    = "https://cdn.jsdelivr.net/pyodide/v$Version/full"

# ── 目標資料夾 ────────────────────────────────────────────────
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Target    = Join-Path (Split-Path -Parent $ScriptDir) "pyodide"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Pyodide Desktop - Download Offline Runtime" -ForegroundColor Cyan
Write-Host "  Version : $Version (Python 3.12)" -ForegroundColor Cyan
Write-Host "  Target  : $Target" -ForegroundColor Gray
Write-Host "============================================================"
Write-Host ""

if (-not (Test-Path $Target)) { New-Item -ItemType Directory -Path $Target | Out-Null }

# ── 下載工具函式 ──────────────────────────────────────────────
function Download-File {
    param([string]$Url, [string]$Dest, [string]$Label)
    if (Test-Path $Dest) {
        Write-Host "  [SKIP] $Label (already exists)" -ForegroundColor DarkGray
        return
    }
    Write-Host "  [GET]  $Label" -ForegroundColor Yellow -NoNewline
    try {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($Url, $Dest)
        $mb = [math]::Round((Get-Item $Dest).Length / 1MB, 2)
        Write-Host "  $mb MB" -ForegroundColor Green
    } catch {
        Write-Host "  FAILED" -ForegroundColor Red
        throw "Download failed: $Url`n$_"
    }
}

# ── Phase 1：下載核心 Runtime 檔案 ───────────────────────────
Write-Host "Phase 1/3  Core runtime files" -ForegroundColor Magenta
Write-Host ""

$coreFiles = @(
    "pyodide.js",
    "pyodide.mjs",
    "pyodide.asm.js",
    "pyodide.asm.wasm",
    "python_stdlib.zip",
    "pyodide-lock.json"
)

foreach ($f in $coreFiles) {
    Download-File "$Base/$f" "$Target\$f" $f
}

# ── Phase 2：解析 pyodide-lock.json，展開依賴 ────────────────
Write-Host ""
Write-Host "Phase 2/3  Resolving package dependencies from pyodide-lock.json" -ForegroundColor Magenta
Write-Host ""

$lockPath = "$Target\pyodide-lock.json"
$lock     = Get-Content $lockPath -Raw | ConvertFrom-Json
$pkgs     = $lock.packages

# 科學計算套件清單（會遞迴展開所有依賴）
$wantedPkgs = @(
    "numpy",
    "matplotlib",
    "scipy",
    "pandas",
    "scikit-learn",
    "pillow",
    "sympy",
    "micropip",
    "contourpy",
    "kiwisolver",
    "cycler",
    "pyparsing",
    "python-dateutil",
    "pytz",
    "mpmath",
    "packaging",
    "six",
    "fonttools",
    "openblas"
)

# 遞迴展開依賴
function Get-AllDeps {
    param([string]$PkgName, [System.Collections.Generic.HashSet[string]]$Seen)
    if ($Seen.Contains($PkgName)) { return }
    $pkgInfo = $pkgs.PSObject.Properties[$PkgName]
    if ($null -eq $pkgInfo) {
        Write-Host "    [WARN] Package not found in lock: $PkgName" -ForegroundColor DarkYellow
        return
    }
    $Seen.Add($PkgName) | Out-Null
    $deps = $pkgInfo.Value.depends
    if ($deps) {
        foreach ($dep in $deps) {
            Get-AllDeps -PkgName $dep -Seen $Seen
        }
    }
}

$allPkgNames = [System.Collections.Generic.HashSet[string]]::new()
foreach ($p in $wantedPkgs) {
    Get-AllDeps -PkgName $p -Seen $allPkgNames
}

# 收集所有要下載的 file_name
$filesToDownload = [System.Collections.Generic.List[hashtable]]::new()
foreach ($pname in ($allPkgNames | Sort-Object)) {
    $info = $pkgs.PSObject.Properties[$pname]
    if ($null -eq $info) { continue }
    $fname = $info.Value.file_name
    if ($fname -and $fname -ne "") {
        $filesToDownload.Add(@{ Name=$pname; File=$fname }) | Out-Null
    }
}

Write-Host "  Resolved $($filesToDownload.Count) packages (including dependencies):" -ForegroundColor Cyan
foreach ($item in $filesToDownload) {
    Write-Host "    $($item.Name) -> $($item.File)" -ForegroundColor DarkGray
}
Write-Host ""

# ── Phase 3：下載所有套件 .whl / .js 檔案 ────────────────────
Write-Host "Phase 3/3  Downloading packages" -ForegroundColor Magenta
Write-Host ""

$i = 1; $total = $filesToDownload.Count
foreach ($item in $filesToDownload) {
    $label = "[$i/$total] $($item.Name)  ($($item.File))"
    Download-File "$Base/$($item.File)" "$Target\$($item.File)" $label
    $i++
}

# ── 完成統計 ──────────────────────────────────────────────────
$totalMB = [math]::Round(
    (Get-ChildItem $Target | Measure-Object -Property Length -Sum).Sum / 1MB, 1
)
$fileCount = (Get-ChildItem $Target).Count

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  Done!  $fileCount files,  ${totalMB} MB total" -ForegroundColor Green
Write-Host "  $Target" -ForegroundColor Gray
Write-Host ""
Write-Host "  Run pyodide-desktop.exe - fully offline, includes:" -ForegroundColor Green
Write-Host "  numpy / matplotlib / scipy / pandas / scikit-learn" -ForegroundColor Green
Write-Host "  pillow / sympy / and all their dependencies" -ForegroundColor Green
Write-Host "============================================================"
Write-Host ""
Read-Host "Press Enter to exit"
