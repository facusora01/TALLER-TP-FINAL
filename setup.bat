@echo off
rem Instala las dependencias del backend (Elixir) y del frontend (React) de una vez.

cd /d "%~dp0"

echo === Backend (Elixir) ===
cd backend
call mix deps.get
if errorlevel 1 (
    echo [ERROR] Fallo "mix deps.get". Verifica que Elixir este instalado.
    exit /b 1
)
cd ..

echo.
echo === Frontend (React) ===
cd frontend
call npm install
if errorlevel 1 (
    echo [ERROR] Fallo "npm install". Verifica que Node.js este instalado.
    exit /b 1
)
cd ..

echo.
echo Dependencias instaladas. Levanta el sistema con start.bat o "docker compose up".
