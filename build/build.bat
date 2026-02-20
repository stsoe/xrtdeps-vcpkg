@ECHO OFF
REM Build XRT Windows dependencies using vcpkg. Requires vcpkg as a submodule (git submodule update --init).
REM Output is installed to install/ with layout: include/, lib/, bin/, share/.
REM Use that path as EXT_DIR (and KHRONOS) when building XRT with build\build22.bat -ext <path-to-install>.

setlocal
set SCRIPTDIR=%~dp0
set SCRIPTDIR=%SCRIPTDIR:~0,-1%
cd /d "%SCRIPTDIR%"

set VCPKG_DIR=%SCRIPTDIR%\vcpkg
set TRIPLET=x64-windows
set INSTALL_DIR=%SCRIPTDIR%\install

if not exist "%VCPKG_DIR%" (
  echo ERROR: vcpkg not found. Initialize the submodule:
  echo   git submodule update --init
  exit /B 1
)

if not exist "%VCPKG_DIR%\vcpkg.exe" (
  echo Bootstrapping vcpkg...
  call "%VCPKG_DIR%\bootstrap-vcpkg.bat" -disableMetrics
  if errorlevel 1 (echo ERROR: vcpkg bootstrap failed. & exit /B 1)
)

REM Avoid NuGet binary cache issues
if not defined VCPKG_BINARY_SOURCES set VCPKG_BINARY_SOURCES=clear

echo Installing packages from vcpkg.json (triplet %TRIPLET%)...
"%VCPKG_DIR%\vcpkg.exe" install --x-manifest-root="%SCRIPTDIR%" --triplet=%TRIPLET%
if errorlevel 1 (echo ERROR: vcpkg install failed. & exit /B 1)

if not exist "%SCRIPTDIR%\vcpkg_installed\%TRIPLET%" (
  echo ERROR: vcpkg_installed\%TRIPLET% not found after install.
  exit /B 1
)

echo Copying vcpkg_installed\%TRIPLET% to install\ (include, lib, bin, share)...
if exist "%INSTALL_DIR%" rmdir /S /Q "%INSTALL_DIR%"
xcopy "%SCRIPTDIR%\vcpkg_installed\%TRIPLET%" "%INSTALL_DIR%\" /E /I /Q /Y
if errorlevel 1 (echo ERROR: copy failed. & exit /B 1)

echo.
echo Done. Install directory: %INSTALL_DIR%
echo Build XRT with:  build\build22.bat -ext %INSTALL_DIR%
echo Or set EXT_DIR to %INSTALL_DIR% and run build22.bat.
endlocal
