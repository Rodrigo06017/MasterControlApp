@echo off
cd /d "%~dp0build\windows\x64\runner\Release"
start "" "master_control_app.exe"
exit
