@echo off
pushd "%~dp0"
powershell -exec bypass -file patch.ps1 -gameDir "%~1"