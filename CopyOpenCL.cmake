# Copy OpenCL DLL and import lib from dynamic install into static tree (same as CI).
# Invoked at build time: cmake -DSTATIC_DIR=... -DDYNAMIC_DIR=... -P CopyOpenCL.cmake

if(NOT DEFINED STATIC_DIR OR NOT DEFINED DYNAMIC_DIR)
  message(FATAL_ERROR "CopyOpenCL.cmake requires -DSTATIC_DIR= and -DDYNAMIC_DIR=")
endif()

if(EXISTS "${STATIC_DIR}/lib/OpenCL.lib")
  file(REMOVE "${STATIC_DIR}/lib/OpenCL.lib")
endif()
if(EXISTS "${STATIC_DIR}/debug/lib/OpenCL.lib")
  file(REMOVE "${STATIC_DIR}/debug/lib/OpenCL.lib")
endif()

file(MAKE_DIRECTORY "${STATIC_DIR}/bin")
file(MAKE_DIRECTORY "${STATIC_DIR}/include")

file(COPY "${DYNAMIC_DIR}/bin/opencl.dll" DESTINATION "${STATIC_DIR}/bin")
file(COPY "${DYNAMIC_DIR}/lib/OpenCL.lib" DESTINATION "${STATIC_DIR}/lib")
file(COPY "${DYNAMIC_DIR}/include/CL" DESTINATION "${STATIC_DIR}/include")

message(STATUS "OpenCL DLL and import lib copied into ${STATIC_DIR}")
