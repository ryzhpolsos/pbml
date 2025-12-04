@echo off
cd /d "%~dp0"

where python > nul 2> nul
if not %ERRORLEVEL%==0 (
    echo Error: Python executable not found. Make sure you have Python installed
    if "%~1"=="" pause> nul
)

python pbml.py %*