@echo off
chcp 65001 >nul
title CrackVision Mobile - Dev Server

echo.
echo ==========================================
echo      CrackVision Mobile Dev Start
echo ==========================================
echo.

:: Kiem tra Python
for /f "tokens=2 delims= " %%v in ('python --version 2^>^&1') do set PYVER=%%v
for /f "tokens=1,2 delims=." %%a in ("%PYVER%") do (
    set PYMAJ=%%a
    set PYMIN=%%b
)
if "%PYMAJ%"=="3" (
    if %PYMIN% LSS 9 (
        echo [ERROR] Python %PYVER% qua cu! Can Python 3.9 - 3.12.
        pause & exit /b 1
    )
    echo [OK]    Python %PYVER% hop le.
    echo.
) else (
    echo [ERROR] Khong tim thay Python. Hay cai Python 3.11 truoc.
    pause & exit /b 1
)

:: Kiem tra .env
if not exist "backend\.env" (
    echo [WARN]  backend\.env chua ton tai - dang copy tu .env.example...
    copy "backend\.env.example" "backend\.env" >nul
    echo [OK]    Tao backend\.env thanh cong.
    echo.
)

:: Canh bao JWT_SECRET_KEY mac dinh
findstr /C:"your-super-secret-key-change-this-in-production" "backend\.env" >nul 2>&1
if %errorlevel%==0 (
    echo [WARN]  JWT_SECRET_KEY dang dung gia tri mac dinh!
    echo         Nen doi gia tri nay trong file backend\.env truoc khi deploy.
    echo.
)

:: Canh bao PostgreSQL (chi kiem tra dong khong phai comment)
findstr /R "^DATABASE_URL=postgresql" "backend\.env" >nul 2>&1
if %errorlevel%==0 (
    echo [WARN]  DATABASE_URL dang dung PostgreSQL.
    echo         Neu chua co Postgres, doi sang SQLite trong backend\.env:
    echo         DATABASE_URL=sqlite:///./crackvision_dev.db
    echo.
    set /p DBCHOICE=Tiep tuc voi PostgreSQL? [Y/N]:
    if /i "!DBCHOICE!"=="N" (
        start notepad "backend\.env"
        pause & exit /b 0
    )
)

:: Tao venv neu chua co
if not exist "backend\.venv\Scripts\activate.bat" (
    echo [INFO]  Chua co virtual env - dang tao...
    python -m venv "backend\.venv"
    echo [OK]    Virtual env da tao xong.
    echo.
)

:: Cai dependencies neu chua co
if not exist "backend\.venv\Lib\site-packages\fastapi" (
    echo [INFO]  Dang cai dependencies (lan dau co the mat vai phut)...
    call "backend\.venv\Scripts\activate.bat"
    pip install -r "backend\requirements.txt" --quiet
    echo [OK]    Dependencies da cai xong.
    echo.
) else (
    call "backend\.venv\Scripts\activate.bat"
    echo [OK]    Dependencies san sang.
    echo.
)

:: Chon device Flutter
echo ==========================================
echo   Chon device chay Flutter:
echo.
echo   1 - Android Emulator (IpPhone)
echo   2 - Windows Desktop
echo   3 - Chrome (Web)
echo   4 - Android that qua USB
echo   5 - Chi chay Backend (bo qua Flutter)
echo ==========================================
echo.
set /p DEVICE_CHOICE=Lua chon [1-5]:

if "%DEVICE_CHOICE%"=="1" (
    echo.
    echo [INFO]  Dang khoi dong Android Emulator...
    start "" flutter emulators --launch IpPhone
    echo [INFO]  Cho emulator khoi dong (30 giay)...
    timeout /t 30 /nobreak >nul
    set FLUTTER_CMD=flutter run
    set FLUTTER_LABEL=Android Emulator
)
if "%DEVICE_CHOICE%"=="2" (
    set FLUTTER_CMD=flutter run -d windows
    set FLUTTER_LABEL=Windows Desktop
)
if "%DEVICE_CHOICE%"=="3" (
    set FLUTTER_CMD=flutter run -d chrome
    set FLUTTER_LABEL=Chrome Web
)
if "%DEVICE_CHOICE%"=="4" (
    echo.
    flutter devices
    echo.
    set /p DEV_ID=Nhap device-id:
    set FLUTTER_CMD=flutter run -d %DEV_ID%
    set FLUTTER_LABEL=Android Device
)
if "%DEVICE_CHOICE%"=="5" (
    set FLUTTER_CMD=SKIP
    set FLUTTER_LABEL=Bo qua
)

echo.
echo ==========================================
echo   Backend : http://localhost:8000
echo   Swagger : http://localhost:8000/docs
echo   Flutter : %FLUTTER_LABEL%
echo ==========================================
echo.

:: Khoi dong Backend
echo [START] Backend FastAPI...
start "CrackVision Backend" cmd /k "cd /d %~dp0backend && call .venv\Scripts\activate.bat && python run.py"

timeout /t 4 /nobreak >nul

:: Khoi dong Flutter
if not "%FLUTTER_CMD%"=="SKIP" (
    echo [START] Flutter tren %FLUTTER_LABEL%...
    start "CrackVision Flutter" cmd /k "cd /d %~dp0mobile && %FLUTTER_CMD%"
)

echo.
echo [INFO]  Cac cua so terminal da mo.
echo [INFO]  Nhan Ctrl+C trong terminal tuong ung de dung service.
echo.
pause
