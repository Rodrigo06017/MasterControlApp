@echo off
cd /d "%~dp0"
start /min cmd /c "node server/smartglass_bridge.js"
timeout /t 1 /nobreak >nul
cd /d "%~dp0build\windows\x64\runner\Release"
start "" "master_control_app.exe"
exit
