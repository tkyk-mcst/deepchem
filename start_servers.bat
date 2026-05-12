@echo off
echo Starting MolPredict servers...

:: Kill any stale processes on our ports
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8282 "') do taskkill /PID %%a /F 2>nul
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":3000 "') do taskkill /PID %%a /F 2>nul
timeout /t 1 /nobreak >nul

:: Start mock backend on port 8282
echo [1] Starting mock backend on port 8282...
start "MockBackend" /min C:\Users\takay\AppData\Local\Programs\Python\Python39\python.exe mock_backend.py

timeout /t 3 /nobreak >nul

:: Start Flutter web server on port 3000
echo [2] Starting Flutter web server on port 3000...
start "FlutterWeb" /min C:\Users\takay\AppData\Local\Programs\Python\Python39\python.exe -m http.server 3000 --directory mol_app\build\web

timeout /t 2 /nobreak >nul

echo.
echo Servers started!
echo   Flutter app : http://localhost:3000
echo   Backend API : http://localhost:8282
echo   API docs    : http://localhost:8282/docs
echo.
echo Press any key to stop both servers...
pause >nul

taskkill /FI "WindowTitle eq MockBackend" /F 2>nul
taskkill /FI "WindowTitle eq FlutterWeb" /F 2>nul
echo Servers stopped.
