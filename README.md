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

3. **Build the dependencies** (first run can take a long time; vcpkg builds from source). Run the script that mirrors the CI workflow (same triplets, static deps + dynamic OpenCL):

   ```bat
   build.bat
   ```

   This bootstraps vcpkg, installs all deps with `x64-windows-static` (or `arm64-windows-static` on ARM64), installs OpenCL as a DLL, and copies the OpenCL DLL/import lib into the static tree. When finished, dependencies are under **vcpkg_installed/x64-windows-static/** (or arm64). Use that path as `EXT_DIR`.

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

XRT’s CMake uses `EXT_DIR` for `KHRONOS` and `BOOST_ROOT`, so a single path is enough.

**Important:** These dependencies are built with the **static C/C++ runtime** (/MT). XRT must use the same runtime for the configuration that links them (e.g. Release). If XRT is built with the dynamic runtime (/MD), you will get linker errors (see **Troubleshooting** below).

## Troubleshooting

### LNK2001: unresolved external symbol `__std_find_first_of_trivial_pos_2`, `__std_search_1`, etc.

These symbols are from the Microsoft C++ Standard Library. The error occurs when the **dependencies were built with the static CRT** (/MT, as with the `x64-windows-static` triplet) but **XRT is built with the dynamic CRT** (/MD). The linker then cannot resolve STL symbols referenced by the Boost (and other) static libs.

**Fix:** Build XRT with the **static runtime** (/MT) for the configuration that uses these deps (e.g. Release). In Visual Studio: Project → Properties → C/C++ → Code Generation → Runtime Library → **Multi-threaded (/MT)** (or **Multi-threaded Debug (/MTd)** for Debug). In CMake, set `CMAKE_MSVC_RUNTIME_LIBRARY` to `MultiThreaded` (or `MultiThreadedDebug` for Debug) for that config.

### Boost library names: `-s` in name vs CI (e.g. `libboost_*-mt-s-x64-1_86.lib` vs `boost_*-mt-x64-1_90.lib`)

- The **`-s`** and **`lib`** prefix can appear when Boost is built with different options or an older Boost/vcpkg; the **1_86** vs **1_90** is the Boost version (1.86 vs 1.90).
- To match CI, build dependencies with the **same triplet as CI**: `x64-windows-static`, and use the same vcpkg (and baseline) as the CI workflow so Boost and other port versions align.
- Always use **`--triplet=x64-windows-static`** when running `vcpkg install` for this repo.

## Updating dependencies

- Update **vcpkg.json** if you need different or additional packages (keep it in sync with XRT’s `src/vcpkg.json` if you use that for CI).
- Update the vcpkg submodule to a newer commit if you want a newer vcpkg/port set:

  ```bat
  cd vcpkg
  git fetch origin
  git checkout <commit-or-branch>
  cd ..
  ```

- Re-run the install command with `--triplet=x64-windows-static` to rebuild and refresh the dependency tree.

## Adding this repo as a submodule to XRT (optional)

If you want XRT to reference this deps repo as a submodule (e.g. under `ext` or `deps`):

```bat
cd path\to\XRT
git submodule add <this-repo-url> xrt-windows-deps
git submodule update --init --recursive xrt-windows-deps
cd xrt-windows-deps
build.bat
cd ..
build\build22.bat -ext %CD%\xrt-windows-deps\vcpkg_installed\x64-windows-static
```

Then document in XRT’s README or build docs that Windows builds can use `-ext <path-to-xrt-windows-deps>/install`.
