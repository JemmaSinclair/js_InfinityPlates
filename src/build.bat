@echo off
setlocal enabledelayedexpansion

echo [1/3] Initializing MSVC x64 environment...
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"

cd /d "%~dp0"

echo [2/3] Compiling resource script...
rc /fo CustomPlates.res CustomPlates.rc
if %ERRORLEVEL% neq 0 (
    echo Resource compilation failed!
    exit /b %ERRORLEVEL%
)

echo [3/3] Compiling and linking CustomPlates.asi...
cl.exe /O2 /LD /MT /EHsc /Fe:CustomPlates.asi CustomPlatesLoader.cpp CustomPlates.res /link /DLL /RELEASE /DYNAMICBASE:NO
if %ERRORLEVEL% neq 0 (
    echo Compilation failed!
    exit /b %ERRORLEVEL%
)

echo CustomPlates.asi successfully built!

