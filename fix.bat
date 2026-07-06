@echo off
:: Ojo, setlocal le dices a Windows que todo pertenece solo a este script incluyendo las variables creadas
setlocal 

:: Definimos color de caracteres
color 0A

:: Generamos elevacion de privilegios de manera automatica
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Solicitando permisos de Administrador...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Menu de opciones para automatizar limpieza y monitoreo
:inicio
cls
echo    ********** MENU de Estados, Limpieza Y Monitoreo ***********
echo    -
echo    1) Reporte ESTADO de BATERIA
echo    2) Reporte de DURACION y EFICACIA de BATERIA
echo    3) Reporte TEMPERATURA de CPU
echo    4) MAC - IPs de Dispositivos en RED 
echo    5) LIMPIAR archivos TEMPORALES y LOGS
echo    6) Escanear y Reparar sistema
echo    7) Reporte informe de sistema en txt
echo    8) Web - verip.cl para IP Publica
echo    9) Web - fast.com para verificar Velocidad Banda Ancha
echo    0) Salir
echo    -
echo    ***************************
echo.

:: Limpiamos la variable opcion antes de preguntar por seguridad
set "opcion="
set /p opcion=OPCION=

if "%opcion%"=="1" (goto op1
) else if "%opcion%"=="2" (goto op2
) else if "%opcion%"=="3" (goto op3
) else if "%opcion%"=="4" (goto op4
) else if "%opcion%"=="5" (goto op5
) else if "%opcion%"=="6" (goto op6
) else if "%opcion%"=="7" (goto op7
) else if "%opcion%"=="8" (goto op8
) else if "%opcion%"=="9" (goto op9
) else if "%opcion%"=="0" (goto op0
) else (goto error)


:: Funcion Reporte Estado Bateria
:op1
cls
echo ===================================================
echo Generando reporte de bateria...
powercfg /batteryreport /output "%USERPROFILE%\Desktop\battery-report.html"
echo ===================================================
echo.
pause&cls
goto inicio


:: Funcion Reporte Eficiencia y Errores de Bateria
:op2
cls
echo =======================================================================
echo Generando reporte de eficiencia de bateria (esto tomara 60 segundos)...
powercfg /energy /output "%USERPROFILE%\Desktop\energy-report.html"
echo =======================================================================
echo.
pause&cls
goto inicio


:: Reporte Temperatura CPU
:op3
cls
echo ===================================================
echo Analizando temperatura del sistema...

:: 1. Extraer valor crudo con el comando original de CMD de forma segura
set "TEMP_RAW="
for /f "skip=1" %%a in ('wmic /namespace:\\root\wmi PATH MSAcpi_ThermalZoneTemperature get CurrentTemperature 2^>nul') do (
    if not defined TEMP_RAW set "TEMP_RAW=%%a"
)

:: Limpiar posibles espacios en blanco que deja wmic
set TEMP_RAW=%TEMP_RAW: =%

:: 2. Failsafe en caso de no soportar WMI thermal
if "%TEMP_RAW%"=="" (
    echo.
    color 0C
    echo ERROR: Tu placa base no soporta la lectura de este sensor termico nativo.
    pause&cls
    color 0A
    goto inicio
)

:: 3. Generar HTML delegando la matematica a JavaScript
(
echo ^<!DOCTYPE html^>
echo ^<html lang="en"^>
echo ^<head^>
echo     ^<meta charset="UTF-8"^>
echo     ^<meta name="viewport" content="width=device-width, initial-scale=1.0"^>
echo     ^<title^>Temperatura CPU^</title^>
echo ^</head^>
echo ^<body style="background-color: #000;"^>
echo     ^<h1 style="color: rgb(37, 164, 238); border-bottom: 1px solid rgb(37, 164, 238); font-size: 1.5rem; font-weight: bolder;"^>Resultado Temperatura CPU^</h1^>
echo     ^<br^>
echo     ^<div style="padding: 50px;"^>
echo         ^<ul^>
echo             ^<li style="color: rgba(255, 255, 0, 0.973);"^>Resultado crudo ^(Kelvin x 10^): %TEMP_RAW%^</li^>
echo             ^<li style="color: rgba(255, 153, 0, 0.973); font-size: 24px;"^>Temperatura calculada: ^<span id="celsiusVal"^>Calculando...^</span^> grados Celsius^</li^>
echo         ^</ul^>
echo     ^</div^>
echo     ^<div id="statusDiv" style="padding: 0px 50px; font-size: 1.3rem; font-weight: bold; font-family: sans-serif;"^>
echo         Estado: Evaluando...
echo     ^</div^>
echo     ^<script^>
echo         // Logica de calculo y color en JS incrustado
echo         var raw = parseInt^("%TEMP_RAW%", 10^);
echo         var celsius = ^(raw / 10^) - 273.15;
echo         celsius = celsius.toFixed^(2^);
echo         document.getElementById^('celsiusVal'^).innerText = celsius;
echo         var msg = "";
echo         var col = "";
echo         if ^(celsius ^>= 40 ^&^& celsius ^<= 65^) {
echo             msg = "Temperatura ideal";
echo             col = "rgb(0, 255, 100)";
echo         } else if ^(celsius ^> 65 ^&^& celsius ^<= 85^) {
echo             msg = "Normal";
echo             col = "rgb(255, 153, 0)";
echo         } else {
echo             msg = "Temperatura alta ^(atento por si necesita mantencion^)";
echo             col = "rgb(255, 50, 50)";
echo         }
echo         var div = document.getElementById^('statusDiv'^);
echo         div.innerText = "Estado: " + msg;
echo         div.style.color = col;
echo     ^</script^>
echo ^</body^>
echo ^</html^>
) > "%USERPROFILE%\Desktop\Temperatura_CPU.html"

echo.
echo EXITOSO: Archivo Temperatura_CPU.html creado en tu Escritorio.
pause&cls
goto inicio


:: MAC e IPs de la RED
:op4
cls
color 0E
echo ===================================================
echo     DETECCION DE RED (ARP y CONFIGURACION)
echo ===================================================
echo [!] Ejecutando 'arp -a' para listar dispositivos...
echo.
arp -a
echo.
echo ===================================================
echo [!] Resumen de este equipo (IPs y MACs)...
echo ===================================================
ipconfig | findstr /i "IPv4 IPv6 Puerta Gateway Físico Physical"
echo ===================================================
echo.
pause&cls
color 0A
goto inicio

:: Limpiar archivos temporales y logs
:op5
cls
color 0D
echo ===================================================
echo Limpiando archivos temporales...
echo ===================================================
:: Borra todos los archivos de la carpeta temp silenciosamente
del /q /f /s "%temp%\*" >nul 2>&1
:: Borra todas las subcarpetas de la carpeta temp silenciosamente
for /d %%x in ("%temp%\*") do rd /s /q "%%x" >nul 2>&1

:: Borra archivos en la carpeta windows/temp
del /q /f /s "%systemroot%\temp\*" >nul 2>&1
:: Borra subcarpetas en la carpeta windows/temp
for /d %%x in ("%systemroot%\temp\*") do rd /s /q "%%x" >nul 2>&1

echo.
echo ===================================================
echo Limpiando archivos logs del sistema...
echo ===================================================
:: Borra archivos en la carpeta Logs
del /q /f /s "%systemroot%\Logs\*" >nul 2>&1
:: Borra subcarpetas en la carpeta Logs
for /d %%x in ("%systemroot%\Logs\*") do rd /s /q "%%x" >nul 2>&1

echo.
echo ESTAMOS LISTOS!! Archivos basura eliminados con exito.
echo ===================================================
echo.
pause&cls
color 0A
goto inicio

:: Escaneando y Reparando con -> sfc /scannow
:op6
cls
color 0E
echo =======================================================================
echo Escaneando y reparando. Esto puede demorar varios minutos. PACIENCIA...
echo =======================================================================
sfc /scannow
echo.
echo ESTAMOS LISTOS!! 
echo ==========================
echo.
pause&cls
color 0A
goto inicio


:: Ejecutando systeminfo
:op7
cls
echo ===============================================
echo Obteniendo Reporte de informacion del sistema...
echo ===============================================
systeminfo > "%USERPROFILE%\desktop\Reporte_info_sistema.txt"
echo.
echo Reporte creado (Reporte_info_sistema.txt) y almacenado en el Escritorio!!
echo =======================================================================
echo.
pause&cls
goto inicio

:: Ver IP Publica desde la web verip.cl
:op8
cls
echo =============================================
echo Abriendo Web Para ver Ip Publica en Chrome...
echo =============================================
start chrome https://www.verip.cl/
pause&cls
goto inicio

:: Test de velocidad
:op9
cls
echo =======================================
echo Abriendo Test de velocidad en Chrome...
echo =======================================
start chrome https://fast.com
pause&cls
goto inicio


:: Cerrar programa
:op0
cls
exit


:: Mensaje de Error por Opcion Invalida
:error
cls
color 0C
echo INGRESE UN DATO VALIDO!
pause&cls
color 0A
goto inicio