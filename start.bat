@echo off
rem Levanta el sistema completo (backend Elixir + frontend React) con Docker.
rem Backend:  ws://localhost:4000/ws
rem Frontend: http://localhost:5173

where docker >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Docker no esta instalado o no esta en el PATH.
    echo Instala Docker Desktop: https://www.docker.com/products/docker-desktop/
    exit /b 1
)

docker info >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Docker no esta corriendo. Abri Docker Desktop y proba de nuevo.
    exit /b 1
)

cd /d "%~dp0"

echo Levantando backend y frontend...
docker compose up --build
