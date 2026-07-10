cmake_minimum_required(VERSION 3.20)

set(CUDA_TEMPLATE_PROJECT_NAME "01-copy" CACHE STRING "CMake project name")
set(CUDA_TEMPLATE_BINARY_NAME "01-copy" CACHE STRING "Name of the built binary")

project(${CUDA_TEMPLATE_PROJECT_NAME} LANGUAGES CUDA CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

option(CUDA_TEMPLATE_ENABLE_WARNINGS "Enable extra compiler warnings" ON)

add_executable(${CUDA_TEMPLATE_BINARY_NAME}
    src/main.cu
)

target_include_directories(${CUDA_TEMPLATE_BINARY_NAME}
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)

if(CUDA_TEMPLATE_ENABLE_WARNINGS)
    target_compile_options(${CUDA_TEMPLATE_BINARY_NAME}
        PRIVATE
            $<$<COMPILE_LANGUAGE:CUDA>:-Xcompiler=-Wall,-Wextra>
            $<$<COMPILE_LANGUAGE:CXX>:-Wall -Wextra -Wpedantic>
    )
endif()

target_link_libraries(${CUDA_TEMPLATE_BINARY_NAME}
    PRIVATE
        stdc++
)

set_target_properties(${CUDA_TEMPLATE_BINARY_NAME}
    PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON
)
