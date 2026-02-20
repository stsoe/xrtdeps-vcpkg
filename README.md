# XRT Windows dependencies

This repository builds the third-party dependencies required to build [XRT](https://github.com/Xilinx/XRT) on Windows (Boost, OpenCL, GTest, etc.) using [vcpkg](https://github.com/microsoft/vcpkg). The result is installed into an **install/** directory with a normal layout: **include/**, **lib/**, **bin/**, **share/**.

You then point the XRT build at this install directory using the **-ext** option (same as the original `EXT_DIR` flow).

## Prerequisites

- Windows with Visual Studio 2022 (or 2019) and C++ desktop workload
- Git (for cloning and submodules)

## Setup

1. **Clone this repo** (or add it as a sibling to your XRT checkout):

   ```bat
   git clone <this-repo-url> xrt-windows-deps
   cd xrt-windows-deps
   ```

   **If you created this repo from scratch** (no `vcpkg` folder yet), add vcpkg as a submodule once, then commit:

   ```bat
   git submodule add https://github.com/microsoft/vcpkg.git vcpkg
   ```

2. **Initialize the vcpkg submodule** (if you just cloned and vcpkg is not yet checked out):

   ```bat
   git submodule update --init --recursive
   ```

3. **Build the dependencies** (first run can take a long time; vcpkg builds from source):

   ```bat
   build.bat
   ```

   When finished, dependencies are in **install/** with:
   - `install/include/`
   - `install/lib/`
   - `install/bin/` (e.g. OpenCL.dll)
   - `install/share/`

## Building XRT

Use the install directory as the external-deps path when building XRT:

```bat
cd path\to\XRT
build\build22.bat -ext path\to\xrt-windows-deps\install
```

Or set `EXT_DIR` and run without **-ext**:

```bat
set EXT_DIR=C:\path\to\xrt-windows-deps\install
build\build22.bat
```

XRT’s CMake uses `EXT_DIR` for `KHRONOS` and `BOOST_ROOT`, so a single path to this install directory is enough.

## Updating dependencies

- Update **vcpkg.json** if you need different or additional packages (keep it in sync with XRT’s `src/vcpkg.json` if you use that for CI).
- Update the vcpkg submodule to a newer commit if you want a newer vcpkg/port set:

  ```bat
  cd vcpkg
  git fetch origin
  git checkout <commit-or-branch>
  cd ..
  ```

- Re-run **build.bat** to rebuild and refresh **install/**.

## Adding this repo as a submodule to XRT (optional)

If you want XRT to reference this deps repo as a submodule (e.g. under `ext` or `deps`):

```bat
cd path\to\XRT
git submodule add <this-repo-url> xrt-windows-deps
git submodule update --init --recursive xrt-windows-deps
cd xrt-windows-deps
build.bat
cd ..
build\build22.bat -ext %CD%\xrt-windows-deps\install
```

Then document in XRT’s README or build docs that Windows builds can use `-ext <path-to-xrt-windows-deps>/install`.
