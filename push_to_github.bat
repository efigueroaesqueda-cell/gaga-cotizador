@echo off
echo ========================================
echo  Push gaga-cotizador a GitHub Pages
echo ========================================
cd /d "%~dp0"

:: Buscar Git en ubicaciones comunes
set GIT=""
if exist "C:\Program Files\Git\bin\git.exe"     set GIT="C:\Program Files\Git\bin\git.exe"
if exist "C:\Program Files (x86)\Git\bin\git.exe" set GIT="C:\Program Files (x86)\Git\bin\git.exe"

if %GIT%=="" (
  echo ERROR: No se encontro git.exe. Intenta con Git Bash.
  pause
  exit /b 1
)

echo Usando Git: %GIT%
echo.

echo Borrando lock file si existe...
if exist ".git\index.lock" del /f ".git\index.lock"

echo.
echo Haciendo add y commit...
%GIT% add index.html
%GIT% commit -m "security: remove hardcoded prices/margins; fetch from Supabase precios_gaga view"

echo.
echo Haciendo push a GitHub...
%GIT% push origin main

echo.
echo ========================================
if %ERRORLEVEL%==0 (
  echo  LISTO - Ya esta en GitHub Pages!
  echo  https://efigueroaesqueda-cell.github.io/gaga-cotizador/
) else (
  echo  Hubo un error al hacer push.
)
echo ========================================
pause
