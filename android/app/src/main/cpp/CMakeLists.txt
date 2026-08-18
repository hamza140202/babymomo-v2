cmake_minimum_required(VERSION 3.22)
project(momoimagegen)

# stable-diffusion.cpp source root (cloned alongside android project)
set(SD_CPP_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../sd_native/stable-diffusion.cpp")

# ── Build stable-diffusion.cpp as a static lib (embedded into our .so) ──
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(SD_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(SD_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(GGML_OPENMP OFF CACHE BOOL "" FORCE)
set(GGML_VULKAN OFF CACHE BOOL "" FORCE)   # Disable Vulkan for now (simpler build)
set(GGML_METAL OFF CACHE BOOL "" FORCE)
set(GGML_CUDA OFF CACHE BOOL "" FORCE)
set(GGML_OPENCL OFF CACHE BOOL "" FORCE)
set(SD_CUBLAS OFF CACHE BOOL "" FORCE)

add_subdirectory(${SD_CPP_DIR} ${CMAKE_BINARY_DIR}/sd_build EXCLUDE_FROM_ALL)

# ── Our JNI bridge ──
add_library(
    momoimagegen
    SHARED
    sd_jni_bridge.cpp
)

# Include stable-diffusion.cpp headers
target_include_directories(momoimagegen PRIVATE
    ${SD_CPP_DIR}/include
    ${SD_CPP_DIR}/thirdparty
    ${SD_CPP_DIR}/thirdparty/stb
)

# Link our JNI .so against stable-diffusion static lib + android log + C++ STL
target_link_libraries(momoimagegen
    stable-diffusion   # static, gets embedded
    log                # Android logging
    c++_shared         # C++ standard library (shared)
)

# Strip debug symbols for smaller output
set_target_properties(momoimagegen PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
)

target_compile_options(momoimagegen PRIVATE
    -O3
    -DNDEBUG
    -fvisibility=hidden
    -ffunction-sections
    -fdata-sections
)

target_link_options(momoimagegen PRIVATE
    -Wl,--gc-sections
)
