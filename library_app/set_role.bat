@echo off
chcp 65001 >nul
cd /d "%~dp0"
set /p LOGIN=Логин пользователя: 
set /p ROLE=Роль (admin / manager / user): 
where py >nul 2>nul
if %errorlevel%==0 (
    py -3 library_app.py --set-role %LOGIN% %ROLE%
) else (
    python library_app.py --set-role %LOGIN% %ROLE%
)
pause
