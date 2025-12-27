# Define the minimum CMake version
cmake_minimum_required(VERSION 3.20.0)

# Localize the Zephyr's package
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})

# Define the project's name
project(SMID_Gateway)

# Add the source files
target_sources(app PRIVATE src/main.c)
