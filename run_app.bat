@echo off
echo ========================================================
echo        Starting JalKawach Full-Stack Application
echo ========================================================
echo.

cd /d "%~dp0"

echo [1/2] Launching FastAPI Backend Server...
start "JalKawach Backend" cmd /c "cd backend && .\venv\Scripts\activate && uvicorn main:app --host 127.0.0.1 --port 8000 --reload"

timeout /t 2 /nobreak >nul

echo [2/2] Launching Flutter Frontend in Google Chrome...
cd frontend
flutter run -d chrome

pause
