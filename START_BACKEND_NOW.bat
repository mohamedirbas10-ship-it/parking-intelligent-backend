@echo off
echo ========================================
echo  Starting Local Backend Server
echo ========================================
echo.

cd backend

echo Checking Node.js installation...
node -v
if %errorlevel% neq 0 (
    echo ERROR: Node.js is not installed!
    echo Please install Node.js from https://nodejs.org
    pause
    exit /b 1
)

echo.
echo Starting backend server...
echo Server will run on: http://192.168.1.19:3000
echo.
echo ========================================
echo  Backend is running!
echo  Keep this window open.
echo  Press Ctrl+C to stop the server.
echo ========================================
echo.

npm start

pause
