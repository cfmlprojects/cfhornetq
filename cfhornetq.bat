@echo off
set CFDISTRO_HOME=%userprofile%\cfdistro
set FILE_URL="http://cfmlprojects.org/artifacts/cfdistro/latest/cfdistro.zip"
set FILE_DEST="%CFDISTRO_HOME%\cfdistro.zip"
set buildfile=build/build.xml
set ANT_HOME=%CFDISTRO_HOME%\ant
if not exist "%CFDISTRO_HOME%" (
  mkdir "%CFDISTRO_HOME%"
)
if not exist "%FILE_DEST%" (
  echo Downloading with powershell: %FILE_URL% to %FILE_DEST%
  powershell.exe -command "$webclient = New-Object System.Net.WebClient; $url = \"%FILE_URL%\"; $file = \"%FILE_DEST%\"; $webclient.DownloadFile($url,$file);"
  echo Expanding with powershell to: %CFDISTRO_HOME%
  powershell -command "$shell_app=new-object -com shell.application; $zip_file = $shell_app.namespace(\"%FILE_DEST%\"); $destination = $shell_app.namespace(\"%CFDISTRO_HOME%\"); $destination.Copyhere($zip_file.items())"
) else (
  echo "cfdistro.zip already downloaded, delete to re-download"
)
if "%1" == "" goto MENU
set args=%1
SHIFT
:Loop
IF "%1" == "" GOTO Continue
SET args=%args% -D%1%
SHIFT
IF "%1" == "" GOTO Continue
SET args=%args%=%1%
SHIFT
GOTO Loop
:Continue
if not exist %buildfile% (
	set buildfile="%CFDISTRO_HOME%\build.xml"
)
call "%ANT_HOME%\bin\ant.bat" -nouserlib -f %buildfile% %args%
goto end
:MENU
cls
echo.
echo       cfhornetq menu
REM echo       usage: cfhornetq.bat [start|stop|{target}]
echo.
echo       1. Start server and open browser
echo       2. Stop server
echo       3. List available targets
echo       4. Update project
echo       5. Run Target
echo       6. Quit
echo.
set choice=
set /p choice=      Enter option 1, 2, 3, 4, 5 or 6 :
echo.
if not '%choice%'=='' set choice=%choice:~0,1%
if '%choice%'=='1' goto startServer
if '%choice%'=='2' goto stopServer
if '%choice%'=='3' goto listTargets
if '%choice%'=='4' goto updateProject
if '%choice%'=='5' goto runTarget
if '%choice%'=='6' goto end
::
echo.
echo.
echo "%choice%" is not a valid option - try again
echo.
pause
goto MENU
::
:startServer
cls
call build\cfdistro\ant\bin\ant.bat -f build/build.xml build.start.launch
echo to stop the server, run this again or run: cfhornetq.bat stop
goto end
::
:stopServer
call build\cfdistro\ant\bin\ant.bat -f build/build.xml server.stop
goto end
::
:listTargets
call build\cfdistro\ant\bin\ant.bat -f build/build.xml help
echo       press any key ...
pause > nul
goto MENU
::
:updateProject
call build\cfdistro\ant\bin\ant.bat -f build/build.xml project.update
echo       press any key ...
pause > nul
goto MENU
::
:runTarget
set target=
set /p target=      Enter target name:
if not '%target%'=='' call build\cfdistro\ant\bin\ant.bat -f build/build.xml %target%
echo       press any key ...
pause > nul
goto MENU
::
:end
set choice=
echo       press any key ...
pause
REM EXIT
	
			
