cmake_minimum_required(VERSION 3.13)

project(dbase)

set(CMAKE_CXX_STANDARD 14)
add_executable(dbase src/main.cpp src/sql_create.cpp src/sql_create.h src/CLI.cpp src/CLI.h src/utils.cpp src/utils.h src/Parser.cpp src/Parser.h)