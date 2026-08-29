cmake_minimum_required(VERSION 3.16)
project(WfRecorder VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

# Install to ~/.local/lib/qt6/qml by default (no root needed)
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX
        "$ENV{HOME}/.local/lib/qt6/qml"
        CACHE PATH "QML plugin install prefix" FORCE)
endif()

find_package(Qt6 6.2 REQUIRED COMPONENTS Core Qml Quick)
qt_standard_project_setup()

qt_add_qml_module(wfrecorderplugin
    URI         WfRecorder
    VERSION     1.0
    PLUGIN_TARGET wfrecorderplugin
    SOURCES
        wfrecorder.h
        wfrecorder.cpp
    OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/WfRecorder
)

target_link_libraries(wfrecorderplugin PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::Quick
)

install(
    DIRECTORY   "${CMAKE_CURRENT_BINARY_DIR}/WfRecorder/"
    DESTINATION "WfRecorder"
)
