cmake_minimum_required(VERSION 3.29)
project(Fractal C ASM)

# Set C standard
set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED True)

# Create executables in executables directory
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/executables)

# Enable NASM
enable_language(ASM_NASM)

# Fetch SDL
include(FetchContent)
FetchContent_Declare(
  SDL
  GIT_REPOSITORY https://github.com/libsdl-org/SDL.git
  GIT_TAG release-2.0.14 # Specify the version you want
)
FetchContent_MakeAvailable(SDL)

# Add SDL headers to the project
include_directories(${sdl_SOURCE_DIR}/include)

# Add executable and link it with source files
add_executable(Fractal main.c Julia.h Julia.asm)  

# Link executable with SDL
target_link_libraries(Fractal SDL2main SDL2)
