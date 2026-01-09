# Define the minimum CMake version
cmake_minimum_required(VERSION 3.20.0)

set(DTC_OVERLAY_FILE "${CMAKE_CURRENT_SOURCE_DIR}/boards/esp32s3_devkitm.overlay")

# Localize the Zephyr's package
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})

# Define the project's name
project(SMID_Gateway)

# Add the source files
target_sources(app PRIVATE src/main.c)
