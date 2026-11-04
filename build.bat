@echo off
cd /d "%~dp0src"
call build.bat
copy /y CustomPlates.asi "..\bin\CustomPlates.asi"
echo Done! CustomPlates.asi updated in bin\
pause

