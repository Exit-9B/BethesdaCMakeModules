# Bethesda CMake Modules

This repository contains CMake modules to assist with building and packaging
mods for Bethesda Games Studios games (e.g. Skyrim). The primary motivation for
this is so that mods that compile C++ DLL files can easily integrate additional
files and scripts into their build process. However, it is also possible to
create CMake projects without C++ in order to benefit from these modules.

The following modules are available:
- **BSArchive**: Creates BSA files (using
  [BSArch](https://www.nexusmods.com/newvegas/mods/64745)).
- **Papyrus**: Compiles Papyrus scripts (using Creation Kit, with optional
  anonymization using [AFKPexAnon](https://github.com/namralkeeg/AFKPexAnon)).

## Module Usage
### BSArchive
```
bethesda_archive(<target> OUTPUT <file>
                 FORMAT <TES3 | TES4 | FO3 | FNV | TES5 | SSE | FO4 | FO4DDS>
                 FILES <file> [...]
                 [PREFIX <prefix>]
                 [ARCHIVE_FLAGS <value>]
                 [FILE_FLAGS <value>]
                 [COMPRESS] [SHARE])
```

### Papyrus
```
add_papyrus(<target> GAME <game_path>
            IMPORTS <import> ...
            SOURCES <source> ...
            [OPTIMIZE] [ANONYMIZE])
```

## Examples
### Integrating Papyrus and BSA packing into a C++ project
```cmake
project(
    MySKSEPlugin
    VERSION 1.0.0
    LANGUAGES CXX
)

# Set up your C++ project as usual
# ...

include(BSArchive)
include(Papyrus)

file(GLOB Papyrus_SOURCES
    LIST_DIRECTORIES false
    CONFIGURE_DEPENDS
    "scripts/*.psc"
)

add_papyrus(
    "Papyrus"
    GAME ${Skyrim64Path}
    IMPORTS ${CMAKE_CURRENT_SOURCE_DIR}/scripts
    SOURCES ${Papyrus_SOURCES}
    OPTIMIZE ANONYMIZE
)

source_group("Scripts" FILES ${Papyrus_SOURCES})

bethesda_archive(
    "BSA"
    OUTPUT "MyMod.bsa"
    FORMAT SSE
    FILES ${Papyrus_OUTPUT}
)

install(
    FILES ${Papyrus_SOURCES}
    DESTINATION "Source/Scripts"
)

install(
    FILES
        "${CMAKE_CURRENT_SOURCE_DIR}/dist/MyMod.esp"
        "${CMAKE_CURRENT_BINARY_DIR}/MyMod.bsa"
    DESTINATION "."
)
```

### Compiling Papyrus without C++
```cmake
project(
    MyMod
    VERSION 1.0.0
    LANGUAGES NONE
)

include(BSArchive)
include(Papyrus)

get_filename_component(
    Skyrim64Path
    "[HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Bethesda Softworks\\Skyrim Special Edition;installed path]"
    ABSOLUTE CACHE
)

file(GLOB ${PROJECT_NAME}_SOURCES
    LIST_DIRECTORIES false
    CONFIGURE_DEPENDS
    "scripts/*.psc"
)

add_papyrus(
    "${PROJECT_NAME}"
    GAME ${Skyrim64Path}
    IMPORTS ${CMAKE_CURRENT_SOURCE_DIR}/scripts
    SOURCES ${${PROJECT_NAME}_SOURCES}
    OPTIMIZE ANONYMIZE
)

source_group("Scripts" FILES ${${PROJECT_NAME}_SOURCES})

bethesda_archive(
    "BSA"
    OUTPUT "MyMod.bsa"
    FORMAT SSE
    FILES ${${PROJECT_NAME}_OUTPUT}
)

install(
    FILES ${${PROJECT_NAME}_SOURCES}
    DESTINATION "Source/Scripts"
)

install(
    FILES
        "${CMAKE_CURRENT_SOURCE_DIR}/MyMod.esp"
        "${CMAKE_CURRENT_BINARY_DIR}/MyMod.bsa"
    DESTINATION "."
)
```

### Acquiring an external library
```cmake
# Project setup
# ...

# Download MCM Helper SDK
file(
    DOWNLOAD
    "https://github.com/Exit-9B/MCM-Helper/releases/download/v1.3.2/MCM.SDK.zip"
    "${CMAKE_CURRENT_BUILD_DIR}/download/MCM.SDK.zip"
)

file(
    ARCHIVE_EXTRACT
    INPUT "${CMAKE_CURRENT_BUILD_DIR}/download/MCM.SDK.zip"
    DESTINATION "${CMAKE_CURRENT_BUILD_DIR}/tools/MCM_SDK"
)

file(GLOB ${PROJECT_NAME}_SOURCES
    LIST_DIRECTORIES false
    CONFIGURE_DEPENDS
    "Source/Scripts/*.psc"
)

add_papyrus(
    "${PROJECT_NAME}"
    GAME "${Skyrim64Path}"
    IMPORTS
        "${CMAKE_CURRENT_BUILD_DIR}/tools/MCM_SDK/Source/Scripts"
        "${CMAKE_CURRENT_SOURCE_DIR}/Source/Scripts"
    SOURCES ${${PROJECT_NAME}_SOURCES}
    OPTIMIZE ANONYMIZE
)
```
