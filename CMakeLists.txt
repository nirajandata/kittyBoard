cmake_minimum_required(VERSION 3.16)

project(Kittyboard VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.10)

qt_add_executable(appKittyboard
    src/main.cpp
    src/KeyboardSimulator.cpp
    src/SuggestionEngine.h
    src/SuggestionEngine.cpp
    src/KeyboardSimulator.h
    src/ThemeManager.cpp
)

file(GLOB_RECURSE THEME_FILES
    RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
    CONFIGURE_DEPENDS
    "themes/*.json"
    "themes/*.jpg"
    "themes/*.jpeg"
    "themes/*.png"
)

qt_add_qml_module(appKittyboard
    URI Kittyboard
    QML_FILES
        qml/Main.qml
        qml/KeyButton.qml
    RESOURCES
        ${THEME_FILES}
        assets/english_10k.txt
    SOURCES
        src/ThemeManager.h
        QML_FILES qml/ThemeEditor.qml
)

set_target_properties(appKittyboard PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appKittyboard
    PRIVATE Qt6::Quick
)

find_package(LayerShellQt REQUIRED)
target_link_libraries(appKittyboard PRIVATE LayerShellQt::Interface)

install(TARGETS appKittyboard
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_LIBDIR}
)