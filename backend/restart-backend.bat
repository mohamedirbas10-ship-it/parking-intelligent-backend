@echo off
echo ========================================
echo 🔄 Restarting Backend Server
echo ========================================
echo.

REM Kill any existing process on port 3000
echo 🔍 Checking for existing server on port 3000...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000 ^| findstr LISTENING') do (
    echo 🛑 Stopping existing server (PID: %%a)...
    taskkill //F //PID %%a >nul 2>&1
)

echo ⏳ Waiting for port to be released...
timeout /t 2 /nobreak >nul

echo.
echo ========================================
echo 🚀 Starting Backend Server
echo ========================================
echo.
echo 📡 Server will start on http://localhost:3000
echo 💾 Press Ctrl+C to stop the server
echo.
echo ========================================
echo.

REM Start the server
node server.js

pause
