@echo off
echo ===================================================
echo Starting Parking QR Scanner Test Tool
echo ===================================================
echo.
echo 1. Starting local web server...
echo 2. Opening browser to http://localhost:8000/qr-scanner-test.html
echo.
echo NOTE: Keep this window open while testing!
echo.

start http://localhost:8000/qr-scanner-test.html

cd backend
python -m http.server 8000
