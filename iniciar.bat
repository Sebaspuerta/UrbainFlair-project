@echo off
REM ==================================================================
REM  iniciar.bat  -  MODO RAPIDO (release). Usalo para usar o presentar
REM  la app: compila optimizado y abre Chrome en http://localhost:5000
REM  No tiene hot reload. Para programar usa iniciar_dev.bat
REM ==================================================================
cd /d %~dp0

REM Entrena el modelo solo si todavia no existe
if not exist backend\modelo_guardado (
  echo Entrenando modelo...
  cd backend
  call .venv\Scripts\activate
  python modelo.py
  cd ..
)

REM Backend en una ventana aparte (sin --reload: arranca mas rapido)
start "Backend" cmd /k "cd backend && .venv\Scripts\activate && uvicorn api:app --port 8000"

REM Espera a que la API responda en /salud (maximo ~60 segundos:
REM 20 intentos de ~3 s; Windows tarda ~2 s en rechazar un puerto cerrado)
echo Esperando a que el backend responda...
set /a intentos=0
:esperar_backend
curl.exe -sf -m 2 -o nul http://127.0.0.1:8000/salud && goto backend_listo
set /a intentos+=1
if %intentos% geq 20 goto backend_tarde
REM pausa de 1 segundo
ping -n 2 127.0.0.1 >nul
goto esperar_backend

:backend_tarde
echo AVISO: el backend no respondio en 60 s. La app abre igual; la
echo pantalla de Prediccion funcionara cuando el backend termine de cargar.
goto flutter

:backend_listo
echo Backend listo.

:flutter
REM Flutter en modo release
flutter run -d chrome --release --web-port=5000
