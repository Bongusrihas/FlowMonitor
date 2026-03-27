@echo off
set BASE_DIR=%~dp0..

cd /d "%BASE_DIR%"

set PYTHON=%BASE_DIR%\python_service\venv\Scripts\python.exe

"%PYTHON%" "%BASE_DIR%\python_service\FlowDomain.py" %*