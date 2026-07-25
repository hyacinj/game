# Godot 一键编译+测试（v2.0 — 从 config/project.toml 读取配置）
param(
    [switch]$SkipCompile,        # 跳过编译阶段
    [switch]$SkipTest,           # 跳过测试阶段
    [string]$Filter = ""         # 额外日志过滤（叠加默认过滤器）
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillDir = Resolve-Path "$ScriptDir\.."
$ConfigFile = "$SkillDir\config\project.toml"

# ------------------------------------------------------------
# 1. 读取配置
# ------------------------------------------------------------
if (-not (Test-Path $ConfigFile)) {
    Write-Error "[FATAL] 配置文件不存在: $ConfigFile"
    exit 1
}

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
                $val = $Matches[2].Trim('"').Trim("'").Trim()
                return $val
            }
        }
    }
    return $null
}

$GodotExe     = Parse-TomlValue $ConfigFile "godot" "exe"
$ProjectPath  = Parse-TomlValue $ConfigFile "project" "path"
$EntryScene   = Parse-TomlValue $ConfigFile "project" "entry_scene"
$CompileArgs  = Parse-TomlValue $ConfigFile "editor" "compile_args"
$TestArgs     = Parse-TomlValue $ConfigFile "project" "test_args"
$LogFilter    = Parse-TomlValue $ConfigFile "test" "log_filter"
$Timeout      = Parse-TomlValue $ConfigFile "test" "timeout"
$GodotVersion = Parse-TomlValue $ConfigFile "godot" "version"

# ------------------------------------------------------------
# 2. 环境校验
# ------------------------------------------------------------
if (-not (Test-Path $GodotExe)) {
    Write-Error "[FATAL] Godot 可执行文件不存在: $GodotExe"
    Write-Error "请修改 config/project.toml 中的 godot.exe 路径"
    exit 1
}

if (-not (Test-Path $ProjectPath)) {
    Write-Error "[FATAL] 项目路径不存在: $ProjectPath"
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Godot Game Dev — Test Runner v2.0" -ForegroundColor Cyan
Write-Host " Godot: $GodotVersion | Project: $ProjectPath" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# 3. 编译
# ------------------------------------------------------------
if (-not $SkipCompile) {
    Write-Host ">>> Compiling..." -ForegroundColor Yellow
    $compileProc = Start-Process -FilePath $GodotExe `
        -ArgumentList ($CompileArgs -split ' ') + @("--path", $ProjectPath) `
        -Wait -WindowStyle Hidden -PassThru

    if ($compileProc.ExitCode -ne 0) {
        Write-Host "[FAIL] 编译失败 (exit code: $($compileProc.ExitCode))" -ForegroundColor Red
        exit $compileProc.ExitCode
    }
    Write-Host "[PASS] 编译成功" -ForegroundColor Green
} else {
    Write-Host "[SKIP] 跳过编译" -ForegroundColor DarkGray
}

# ------------------------------------------------------------
# 4. 测试
# ------------------------------------------------------------
if (-not $SkipTest) {
    Write-Host ""
    Write-Host ">>> Testing..." -ForegroundColor Yellow

    $testArgs = @($TestArgs -split ' ') + @("--path", $ProjectPath, $EntryScene)
    $testResult = & $GodotExe $testArgs 2>&1

    # 合并过滤器
    $effectiveFilter = $LogFilter
    if ($Filter) { $effectiveFilter = "($LogFilter)|($Filter)" }

    $filtered = $testResult | Select-String -Pattern $effectiveFilter -AllMatches

    if ($filtered) {
        Write-Host ""
        Write-Host "--- Test Output ---" -ForegroundColor Cyan
        $filtered | ForEach-Object { Write-Host $_.Line }
        Write-Host "-------------------" -ForegroundColor Cyan
    } else {
        Write-Host "[WARN] 未匹配到测试日志 (filter: $effectiveFilter)" -ForegroundColor DarkYellow
        Write-Host "[INFO] 最后 10 行输出:" -ForegroundColor DarkGray
        $testResult | Select-Object -Last 10 | ForEach-Object { Write-Host $_ }
    }

    # 统计结果
    $passCount = ($filtered | Select-String "PASS" -AllMatches).Matches.Count
    $failCount = ($filtered | Select-String "FAIL" -AllMatches).Matches.Count

    Write-Host ""
    if ($failCount -gt 0) {
        Write-Host "[RESULT] $passCount PASS / $failCount FAIL" -ForegroundColor Red
        exit 1
    } elseif ($passCount -gt 0) {
        Write-Host "[RESULT] $passCount PASS / 0 FAIL" -ForegroundColor Green
    } else {
        Write-Host "[RESULT] 未检测到测试断言" -ForegroundColor DarkYellow
    }
} else {
    Write-Host "[SKIP] 跳过测试" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Done." -ForegroundColor Cyan
