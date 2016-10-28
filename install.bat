::==============================================================================
:: author 			:Tapan Chandra
:: contact 			:tapan.nallan@jda.com
:: title			:Hawtio Standalone Installer
:: description		:This script will execute release related actions
:: date				:20161025
:: version			:0.1
:: dependencies		:NSSM - https://nssm.cc/
::					 curl - https://curl.haxx.se/
::					 hawtio - http://hawt.io/
::					 sleep.exe - http://www.sleepcmd.com/
::==============================================================================
@echo off

echo *****************************************
echo Hawtio Standalone Installer, Version 0.1
echo Hawtio version 1.4.66
echo NSSM version 2.24
echo *****************************************


if not defined JAVA_HOME (
	echo.
	echo JAVA_HOME Environment variable has not been defined. Hawtio requires atleast version 7.
	echo Exiting...
	exit 1
)

if not exist install.properties (
	echo.
	echo Could not find install.properties file.
	echo Exiting...
	exit 1
)


::Read from properties file
SET INSTALLER_HOME=%~dp0

FOR /F "tokens=1,2 delims==" %%G IN (install.properties) DO (set %%G=%%H)

If "%1" == "ExecuteCodeWithElevatedPrivileges" goto :ExecuteCodeWithElevatedPrivileges

::Create Install directory
mkdir %install_location%
mkdir %install_location%\bin
mkdir %install_location%\lib
mkdir %install_location%\data

::Copy artifacts
echo f | xcopy /f /Y install.properties %install_location%\data\installed.properties
echo f | xcopy /f /Y lib\hawtio-app-1.4.66.jar %install_location%\lib\hawtio-app-1.4.66.jar
echo f | xcopy /f /Y lib\nssm.exe %install_location%\lib\nssm.exe
echo f | xcopy /f /Y lib\elevator.bat %install_location%\bin\elevator.bat

::Create start/stop/ bat files
cd /D %install_location%\bin

::Creating start.bat
echo ^@echo off > start.bat
echo. >> start.bat
echo If "%%1" == "elevated" goto :elevated >> start.bat
echo. >> start.bat
echo elevator.bat %%~dp0 %%0 elevated  >> start.bat
echo. >> start.bat
echo :elevated >> start.bat
echo net start %service_name% >> start.bat
echo exit >> start.bat

::Creating stop.bat
echo ^@echo off > stop.bat
echo. >> stop.bat
echo If "%%1" == "elevated" goto :elevated >> stop.bat
echo. >> stop.bat
echo elevator.bat %%~dp0 %%0 elevated  >> stop.bat
echo. >> stop.bat
echo :elevated >> stop.bat
echo net stop %service_name% >> stop.bat
echo exit >> stop.bat

::Creating open.bat
echo ^@echo off > open.bat
echo. >> open.bat
echo start http://localhost:%port%/hawtio >> open.bat
echo. >> stop.bat

::Creating Uninstaller
cd /D %install_location%
echo ^@echo off > uninstall.bat
echo. >> uninstall.bat
echo If "%%1" == "elevated" goto :elevated >> uninstall.bat
echo. >> uninstall.bat
echo cd bin >> uninstall.bat
echo elevator.bat %%~dp0 %%0 elevated >> uninstall.bat
echo. >> uninstall.bat
echo. >> uninstall.bat
echo :elevated >> uninstall.bat
echo ^:^:Stopping the service >>uninstall.bat
echo net stop %service_name% >> uninstall.bat
echo. >> uninstall.bat
echo ^:^:Uninstall service >>uninstall.bat 
echo cd %install_location%\lib >> uninstall.bat
echo nssm.exe remove %service_name% confirm >> uninstall.bat
echo. >> uninstall.bat
echo echo Uninstall Complete, You can delete the %install_location% now to finish uninstallation >> uninstall.bat
echo Pause >> uninstall.bat
echo Exit >> uninstall.bat


cd %INSTALLER_HOME%lib

::  Create Service

::Ask for Elevated permissions
elevator.bat %~dp0 %0 ExecuteCodeWithElevatedPrivileges

:ExecuteCodeWithElevatedPrivileges
cd %INSTALLER_HOME%lib
nssm.exe install %service_name% "%JAVA_HOME%\bin\java.exe" -jar "%install_location%\lib\hawtio-app-1.4.66.jar" --port %port%
nssm.exe set %service_name% AppDirectory %install_location%
nssm.exe set %service_name% Start SERVICE_AUTO_START
nssm.exe set %service_name% DisplayName %service_display_name%
nssm.exe start %service_name%

echo Installation Completed Successfully. 
echo See %install_location%\bin for service helpers.
Pause

cd /D %install_location%\bin
CALL open.bat