# XRT Windows dependencies

This repository builds the third-party dependencies required to build
[XRT](https://github.com/Xilinx/XRT) on Windows (Boost, OpenCL, GTest,
etc.) using [vcpkg](https://github.com/microsoft/vcpkg). Dependencies
are listed in **CMakeLists.txt** (no vcpkg.json). The result is
installed into **vcpkg_installed/\<triplet\>/** with **include/**,
**lib/**, **bin/**, **share/**.

You then point the XRT build at this install directory using the
**-ext** option (same as the original `EXT_DIR` flow).

## Prerequisites

- Windows with Visual Studio 2022 (or 2019) and C++ desktop workload
- Git (for cloning and submodules)

## Setup

1. **Clone this repo** (or add it as a sibling to your XRT checkout):

   ```
   git clone <this-repo-url> xrt-windows-deps
   cd xrt-windows-deps
   ```

2. **Initialize the vcpkg submodule** (if you just cloned and vcpkg is not yet checked out):

   ```
   git submodule update --init --recursive
   ```

3. **Build the dependencies** (first run can take a long time; vcpkg
builds from source). Use the CMake flow.

   ```
   cmake -B build -G "Visual Studio 17 2022" -A x64
   cmake --build build --config Release --target deps
   ```

   This bootstraps vcpkg if needed, installs all deps with
   `x64-windows-static` (or `arm64-windows-static` on ARM64), install
   OpenCL as a DLL, and copy the OpenCL DLL/import lib into the static
   tree. When finished, dependencies are under
   **vcpkg_installed/x64-windows-static/** (or arm64). Use that path
   as `EXT_DIR`. When using the CMake flow, buildtrees, packages,
   downloads, and the OpenCL install are written to
   **build/.vcpkg_build/** so the **vcpkg/** directory is not modified
   (only bootstrap may create `vcpkg.exe` once).

## Building XRT

Use the dependency directory as the external-deps path
(e.g. **vcpkg_installed/x64-windows-static/**):

```bat
cd path\to\XRT
build\build22.bat -ext path\to\xrt-windows-deps\vcpkg_installed\x64-windows-static
```

**Important:** These dependencies are built with the **static C/C++
runtime** (/MT). XRT must use the same runtime for the configuration
that links them (e.g. Release). If XRT is built with the dynamic
runtime (/MD), you will get linker errors (see **Troubleshooting**
below).

## Updating dependencies

- Edit the dependency list in **CMakeLists.txt** (`XRT_DEPS_STATIC`). If you use **build.bat**, keep its package list in sync.
- Update the vcpkg submodule to a newer commit if you want a newer vcpkg/port set:

  ```bat
  cd vcpkg
  git fetch origin
  git checkout <commit-or-branch>
  cd ..
  ```

- Re-run **cmake --build build --target deps** to rebuild and refresh the dependency tree.

