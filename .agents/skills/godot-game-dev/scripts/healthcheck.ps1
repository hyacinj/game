# Skill 健康自检脚本（v1.0）
# 对照 _meta/healthcheck.md 的检查项自动执行

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillDir = (Get-Item "$ScriptDir\..").FullName
$ConfigFile = "$SkillDir\config\project.toml"
$VersionFile = "$SkillDir\_meta\version.txt"

$issues = @()
$warnings = @()
$passes = @()

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Skill Healthcheck" -ForegroundColor Cyan
Write-Host " Target: $SkillDir" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# 1. 文件完整性
# ------------------------------------------------------------
Write-Host "--- 1. 文件完整性 ---" -ForegroundColor Yellow

$requiredFiles = @(
    "SKILL.md",
    "_meta/version.txt",
    "_meta/changelog.md",
    "_meta/healthcheck.md",
    "config/project.toml",
    "references/_index.md",
    "references/troubleshooting.md",
    "references/architecture/overview.md",
    "references/architecture/file-classification.md",
    "references/design/design.md",
    "references/design/specs/combat.md",
    "references/design/specs/terrain.md",
    "references/design/specs/units.md",
    "references/design/specs/cards.md",
    "references/design/specs/relics.md",
    "references/design/specs/roguelike.md",
    "references/design/specs/ui.md",
    "references/lessons/_template.md",
    "references/lessons/physics.md",
    "references/lessons/rendering.md",
    "references/lessons/script.md",
    "conventions/gdscript-style.md",
    "conventions/testing.md",
    "scripts/test.ps1"
)

foreach ($file in $requiredFiles) {
    $fullPath = Join-Path $SkillDir $file
    if (Test-Path $fullPath) {
        $passes += "File exists: $file"
    } else {
        $issues += "MISSING: $file"
    }
}

# ------------------------------------------------------------
# 2. 版本号检查
# ------------------------------------------------------------
Write-Host "--- 2. 版本号 ---" -ForegroundColor Yellow

if (Test-Path $VersionFile) {
    $version = (Get-Content $VersionFile -Raw).Trim()
    if ($version -match '^\d+\.\d+\.\d+$') {
        $passes += "Version: $version"
    } else {
        $issues += "版本号格式不正确: '$version' (应为 X.Y.Z)"
    }
}

# ------------------------------------------------------------
# 3. 配置有效性
# ------------------------------------------------------------
Write-Host "--- 3. 配置有效性 ---" -ForegroundColor Yellow

if (Test-Path $ConfigFile) {
    function Parse-TomlValue {
        param([string]$File, [string]$Section, [string]$Key)
        $inSection = $false
        foreach ($line in (Get-Content $File -Encoding UTF8)) {
            if ($line -match '^\s*\[(.+)\]') {
                $inSection = ($Matches[1] -eq $Section)
                continue
            }
            if ($inSection -and $line -match '^\s*(\S+)\s*=\s*(.+)$') {
                if ($Matches[1] -eq $Key) {
                    return $Matches[2].Trim('"').Trim("'").Trim()
                }
            }
        }
        return $null
    }

    $godotExe    = Parse-TomlValue $ConfigFile "godot" "exe"
    $projectPath = Parse-TomlValue $ConfigFile "project" "path"
    $entryScene  = Parse-TomlValue $ConfigFile "project" "entry_scene"

    if (Test-Path $godotExe) {
        $passes += "Godot exe: $godotExe"
    } else {
        $issues += "Godot 路径不存在: $godotExe"
    }

    if (Test-Path $projectPath) {
        $passes += "Project path: $projectPath"
    } else {
        $issues += "项目路径不存在: $projectPath"
    }

    # 检查入口场景是否存在（把 res:// 转换为实际路径）
    $entryFile = $entryScene -replace '^res://', ''
    $entryFull = Join-Path $projectPath $entryFile
    if (Test-Path $entryFull) {
        $passes += "Entry scene: $entryScene"
    } else {
        $issues += "入口场景不存在: $entryScene → $entryFull"
    }
}

# ------------------------------------------------------------
# 4. 索引一致性
# ------------------------------------------------------------
Write-Host "--- 4. 索引一致性 ---" -ForegroundColor Yellow

$indexFile = Join-Path $SkillDir "references/_index.md"
if (Test-Path $indexFile) {
    $indexContent = Get-Content $indexFile -Raw

    # 只扫描 references/ 的已知子目录（避免 -Recurse 溢出到项目目录）
    $refDir = Join-Path $SkillDir "references"
    $knownSubdirs = @("architecture", "design", "lessons")
    $actualFiles = @()
    foreach ($sub in $knownSubdirs) {
        $subPath = Join-Path $refDir $sub
        if (Test-Path $subPath) {
            $files = Get-ChildItem -Path $subPath -File -Name -Depth 2 |
                Where-Object { $_ -ne '_template.md' } |
                ForEach-Object { "references/$sub/$_" -replace '\\','/' }
            $actualFiles += $files
        }
    }
    # 加上 references/ 根目录下的 .md 文件（troubleshooting.md 等）
    $rootFiles = Get-ChildItem -Path $refDir -File -Name -Depth 0 |
        Where-Object { $_ -match '\.md$' -and $_ -ne '_index.md' } |
        ForEach-Object { "references/$_" -replace '\\','/' }
    $actualFiles += $rootFiles

    foreach ($actual in $actualFiles) {
        $basename = [System.IO.Path]::GetFileNameWithoutExtension($actual)
        if ($indexContent -notmatch [regex]::Escape($basename)) {
            $warnings += "索引未包含: $actual"
        }
    }

    # 反向校验：_index.md 中引用的文件是否都存在
    $mdLinkPattern = '\]\(([^)]+\.md)\)'
    $indexLinks = [regex]::Matches($indexContent, $mdLinkPattern) |
        ForEach-Object { $_.Groups[1].Value } |
        Where-Object { $_ -notmatch '^https?://' } |
        ForEach-Object { $_ -replace '^\.?/','' }

    foreach ($link in $indexLinks) {
        # 跳过指向自身和外部链接
        if ($link -match '_index\.md|_template\.md') { continue }
        $linkedPath = Join-Path $SkillDir $link
        if (-not (Test-Path $linkedPath)) {
            $issues += "索引引用了不存在的文件: $link"
        }
    }
}

# ------------------------------------------------------------
# 5. Lessons 时效性
# ------------------------------------------------------------
Write-Host "--- 5. Lessons 时效性 ---" -ForegroundColor Yellow

$lessonsDir = Join-Path $SkillDir "references/lessons"
if (Test-Path $lessonsDir) {
    $lessonFiles = Get-ChildItem -Path $lessonsDir -Filter "*.md" |
        Where-Object { $_.Name -ne "_template.md" }

    foreach ($lesson in $lessonFiles) {
        $content = Get-Content $lesson.FullName -Raw
        if ($content -match '版本|Godot \d') {
            # 有版本标注，OK
        } else {
            $warnings += "Lesson 缺少版本标注: references/lessons/$($lesson.Name)"
        }
    }
}

# ------------------------------------------------------------
# 汇总报告
# ------------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Healthcheck Report" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "PASS: $($passes.Count)" -ForegroundColor Green
Write-Host "WARN: $($warnings.Count)" -ForegroundColor Yellow
Write-Host "FAIL: $($issues.Count)" -ForegroundColor Red

if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "⚠ Warnings:" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}

if ($issues.Count -gt 0) {
    Write-Host ""
    Write-Host "✖ Issues:" -ForegroundColor Red
    $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

Write-Host ""
Write-Host "All checks passed." -ForegroundColor Green
exit 0
