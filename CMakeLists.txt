# XRT Windows dependencies - same flow as CI (build-deps.yml).
# Configure: cmake -B <builddir> [-G "Visual Studio 17 2022" -A x64]
# Build:     cmake --build <builddir> [--config Release]
# Output:   <source>/vcpkg_installed/<triplet> (use as EXT_DIR).
# Dependencies are defined here (no vcpkg.json); OpenCL is installed separately as dynamic.
# All vcpkg output (buildtrees, packages, downloads, opencl install) goes under the build dir
# so the vcpkg/ directory is not modified (except bootstrap creates vcpkg.exe once).

cmake_minimum_required(VERSION 3.18)
project(xrt-windows-deps NONE)

# ---------------------------------------------------------------------------
# Dependency list (single source of truth; keep build.bat in sync if editing)
# ---------------------------------------------------------------------------
set(XRT_DEPS_STATIC
  boost-asio
  boost-filesystem
  boost-format
  boost-interprocess
  boost-process
  boost-program-options
  boost-property-tree
  boost-regex
  boost-uuid
  gtest
)

set(XRT_DEPS_DYNAMIC
  opencl
)

# Triplet by host architecture (match CI matrix)
if(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "ARM64")
  set(TRIPLET "arm64-windows-static")
  set(TRIPLET_DYNAMIC "arm64-windows")
else()
  set(TRIPLET "x64-windows-static")
  set(TRIPLET_DYNAMIC "x64-windows")
endif()

set(VCPKG_EXE "${CMAKE_SOURCE_DIR}/vcpkg/vcpkg.exe")
set(VCPKG_ROOT "${CMAKE_SOURCE_DIR}/vcpkg")
set(INSTALL_ROOT "${CMAKE_SOURCE_DIR}/vcpkg_installed")
set(STATIC_DIR "${INSTALL_ROOT}/${TRIPLET}")

# Work dir in build tree so vcpkg/ is not modified (buildtrees,
# packages, downloads, opencl install)
set(VCPKG_WORK_DIR "${CMAKE_BINARY_DIR}/.vcpkg_build")
set(VCPKG_BUILDTREES_ROOT "${VCPKG_WORK_DIR}/buildtrees")
set(VCPKG_PACKAGES_ROOT "${VCPKG_WORK_DIR}/packages")
set(VCPKG_DOWNLOADS_ROOT "${VCPKG_WORK_DIR}/downloads")
set(OPENCL_INSTALL_ROOT "${VCPKG_WORK_DIR}/opencl_installed")
set(DYNAMIC_DIR "${OPENCL_INSTALL_ROOT}/${TRIPLET_DYNAMIC}")

# Bootstrap vcpkg at configure time if needed
if(NOT EXISTS "${VCPKG_EXE}")
  message(STATUS "Bootstrapping vcpkg...")
  execute_process(
    COMMAND "${CMAKE_SOURCE_DIR}/vcpkg/bootstrap-vcpkg.bat" -disableMetrics
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    RESULT_VARIABLE BOOT_RESULT
  )
  if(BOOT_RESULT)
    message(FATAL_ERROR "vcpkg bootstrap failed with ${BOOT_RESULT}")
  endif()
  message(STATUS "vcpkg bootstrapped.")
endif()

message(STATUS "Dependencies triplet: ${TRIPLET}")

# Build target: run vcpkg install (static) + install opencl (dynamic) + copy OpenCL into static tree.
# All vcpkg output redirected so vcpkg/ is not modified.
add_custom_target(deps
  COMMAND ${CMAKE_COMMAND} -E env
    "VCPKG_BINARY_SOURCES=clear"
    "VCPKG_DOWNLOADS=${VCPKG_DOWNLOADS_ROOT}"
    "${VCPKG_EXE}" install ${XRT_DEPS_STATIC}
    --triplet=${TRIPLET}
    --x-install-root="${INSTALL_ROOT}"
    --x-buildtrees-root="${VCPKG_BUILDTREES_ROOT}"
    --x-packages-root="${VCPKG_PACKAGES_ROOT}"
    --downloads-root="${VCPKG_DOWNLOADS_ROOT}"
    --vcpkg-root="${VCPKG_ROOT}"
    --classic
  COMMAND ${CMAKE_COMMAND} -E env
    "VCPKG_BINARY_SOURCES=clear"
    "VCPKG_DOWNLOADS=${VCPKG_DOWNLOADS_ROOT}"
    "${VCPKG_EXE}" install ${XRT_DEPS_DYNAMIC}
    --triplet=${TRIPLET_DYNAMIC}
    --x-install-root="${OPENCL_INSTALL_ROOT}"
    --x-buildtrees-root="${VCPKG_BUILDTREES_ROOT}"
    --x-packages-root="${VCPKG_PACKAGES_ROOT}"
    --downloads-root="${VCPKG_DOWNLOADS_ROOT}"
    --vcpkg-root="${VCPKG_ROOT}"
    --classic
  COMMAND ${CMAKE_COMMAND}
    -DSTATIC_DIR="${STATIC_DIR}"
    -DDYNAMIC_DIR="${DYNAMIC_DIR}"
    -P "${CMAKE_CURRENT_SOURCE_DIR}/CopyOpenCL.cmake"
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
  COMMENT "Installing vcpkg dependencies (static + OpenCL dynamic) and copying OpenCL into static tree"
)

message(STATUS "Build with: cmake --build ${CMAKE_BINARY_DIR} [--config Release] --target deps")
message(STATUS "Then use as EXT_DIR: ${STATIC_DIR}")
