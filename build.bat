@echo off
setlocal
REM Build XRT Windows dependencies the same way as CI (build-deps.yml).
REM Uses x64-windows-static on AMD64, arm64-windows-static on ARM64.
REM Output: vcpkg_installed\<triplet> (use as EXT_DIR or copy to install\).

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
cd /d "%ROOT%"

REM Match CI: choose triplet by architecture
if "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
  set "TRIPLET=arm64-windows-static"
  set "TRIPLET_DYNAMIC=arm64-windows"
) else (
  set "TRIPLET=x64-windows-static"
  set "TRIPLET_DYNAMIC=x64-windows"
)

echo Building dependencies: %TRIPLET%
echo.

REM Bootstrap vcpkg (same as CI)
if not exist "vcpkg\vcpkg.exe" (
  echo Bootstrapping vcpkg...
  call vcpkg\bootstrap-vcpkg.bat -disableMetrics
  if errorlevel 1 exit /b 1
  echo.
)

set "VCPKG_BINARY_SOURCES=clear"

REM Install all dependencies (static, release + debug) - manifest mode
echo Installing dependencies (static)...
vcpkg\vcpkg.exe install --x-manifest-root="%ROOT%" --triplet=%TRIPLET%
if errorlevel 1 exit /b 1
echo.

REM Install OpenCL ICD loader as dynamic (opencl.dll) - classic mode
echo Installing OpenCL (dynamic)...
vcpkg\vcpkg.exe install opencl --triplet=%TRIPLET_DYNAMIC% --classic
if errorlevel 1 exit /b 1
echo.

REM Copy OpenCL DLL and import lib into static tree (same as CI)
set "STATIC=%ROOT%\vcpkg_installed\%TRIPLET%"
set "DYNAMIC=%ROOT%\vcpkg\installed\%TRIPLET_DYNAMIC%"

echo Copying OpenCL into static tree...
if exist "%STATIC%\lib\OpenCL.lib" del /q "%STATIC%\lib\OpenCL.lib"
if exist "%STATIC%\debug\lib\OpenCL.lib" del /q "%STATIC%\debug\lib\OpenCL.lib"
if not exist "%STATIC%\bin" mkdir "%STATIC%\bin"
copy /y "%DYNAMIC%\bin\opencl.dll" "%STATIC%\bin\" >nul
copy /y "%DYNAMIC%\lib\OpenCL.lib" "%STATIC%\lib\" >nul
echo.

echo Done. Use as EXT_DIR:
echo   %STATIC%
echo.
endlocal
