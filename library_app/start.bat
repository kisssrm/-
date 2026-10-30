@echo off
chcp 65001 >nul
cd /d "%~dp0"
where py >nul 2>nul
if %errorlevel%==0 (
    py -3 library_app.py
    goto end
)
where python >nul 2>nul
if %errorlevel%==0 (
    python library_app.py
    goto end
)
echo Python не найден. Установите Python 3.10 или новее с python.org
echo (при установке отметьте галочку "Add Python to PATH").
pause
:end
if %errorlevel% neq 0 pause
