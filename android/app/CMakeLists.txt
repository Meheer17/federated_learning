cmake_minimum_required(VERSION 3.10.2)

project(lora_trainer CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(
    lora_trainer
    SHARED
    ../../native/lora_trainer.cpp
)

find_library(
    log-lib
    log
)

target_link_libraries(
    lora_trainer
    ${log-lib}
)
