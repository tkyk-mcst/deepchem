@echo off
REM DeepChem MolAI local startup script (Windows)
REM Usage: double-click or run from cmd

echo === DeepChem MolAI: Starting backend on port 8282 ===
start "DeepChem Backend" cmd /k "cd /d %~dp0 && uvicorn mock_backend:app --host 0.0.0.0 --port 8282"

timeout /t 2 /nobreak >nul

echo === DeepChem MolAI: Starting frontend on port 3000 ===
start "DeepChem Frontend" cmd /k "cd /d %~dp0mol_app\build\web && python -m http.server 3000"

timeout /t 2 /nobreak >nul

echo.
echo   App:   http://localhost:3000
echo   API:   http://localhost:8282/docs
echo.
start http://localhost:3000
