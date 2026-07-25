# Godot 一键编译+测试
$Godot = "D:\Software\Godot\Godot_v4.4.1-stable_mono_win64.exe"
$Project = "D:\Projects\新建游戏项目"

Write-Host "=== Compiling... ==="
Start-Process -FilePath $Godot -ArgumentList "--headless","--path",$Project,"--editor" -Wait -WindowStyle Hidden

Write-Host "=== Testing... ==="
& $Godot --headless --path $Project res://scenes/start.tscn 2>&1 | Select-String "TEST|SUMMARY|Error|error"
