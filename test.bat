@echo off
:: Godot compile + run test script
start "" "D:\Software\Godot\Godot_v4.4.1-stable_mono_win64.exe" --path "D:\Projects\新建游戏项目" --editor
timeout /t 8 /nobreak >nul
taskkill /f /im Godot_v4.4.1-stable_mono_win64.exe >nul 2>&1
timeout /t 1 /nobreak >nul
"D:\Software\Godot\Godot_v4.4.1-stable_mono_win64.exe" --path "D:\Projects\新建游戏项目" res://scenes/start.tscn
