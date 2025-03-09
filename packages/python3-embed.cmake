set(minver "12")
set(relver "9")
set(verson 3.${minver}.${relver})
if(${TARGET_CPU} MATCHES "x86_64")
    set(link "https://www.python.org/ftp/python/${verson}/python-${verson}-embed-amd64.zip")
    set(hash "f34996cc1f44c98729ef6ce92d05e41c")
elseif(TARGET_CPU STREQUAL "i686")
    set(link "https://www.python.org/ftp/python/${verson}/python-${verson}-embed-win32.zip")
    set(hash "a8015f8d166ea9a1fa9a3cf3b26c958d")
    set(dlltool_opts "-U")
elseif(TARGET_CPU STREQUAL "aarch64")
    set(link "https://www.python.org/ftp/python/${verson}/python-${verson}-embed-arm64.zip")
    set(hash "b5c1583bb0dc258799570a57a31a269d")
endif()
set(header_hash "ce613c72fa9b32fb4f109762d61b249b")

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/python3-embed.pc.in ${CMAKE_CURRENT_BINARY_DIR}/python3-embed.pc @ONLY)
set(GENERATE_DEF ${CMAKE_CURRENT_BINARY_DIR}/python3-embed-prefix/src/generate_def.sh)
file(WRITE ${GENERATE_DEF}
"#!/bin/bash
gendef $1.dll")


ExternalProject_Add(python3-header
    URL https://www.python.org/ftp/python/${verson}/Python-${verson}.tgz
    URL_HASH MD5=${header_hash}
    DOWNLOAD_DIR ${SOURCE_LOCATION}
    UPDATE_COMMAND ""
    PATCH_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/Include ${MINGW_INSTALL_PREFIX}/include/python3
            COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/PC/pyconfig.h ${MINGW_INSTALL_PREFIX}/include/python3/pyconfig.h
    LOG_DOWNLOAD 1
)

ExternalProject_Add(python3-embed
    DEPENDS
        python3-header
    URL ${link}
    URL_HASH MD5=${hash}
    DOWNLOAD_DIR ${SOURCE_LOCATION}
    UPDATE_COMMAND ""
    PATCH_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1
)

ExternalProject_Add_Step(python3-embed generate-def
    DEPENDEES install
    WORKING_DIRECTORY <SOURCE_DIR>
    COMMAND chmod 755 ${GENERATE_DEF}
    COMMAND ${EXEC} ${GENERATE_DEF} python3${minver}
    LOG 1
)

ExternalProject_Add_Step(python3-embed generate-lib
    DEPENDEES generate-def
    WORKING_DIRECTORY <SOURCE_DIR>
    COMMAND ${EXEC} ${TARGET_ARCH}-dlltool -m ${dlltool_image} -d python3${minver}.def -l python3${minver}.lib
    LOG 1
)

ExternalProject_Add_Step(python3-embed manual-install
    DEPENDEES generate-lib
    WORKING_DIRECTORY <SOURCE_DIR>
    # Copying libs
    COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/python3${minver}.lib ${MINGW_INSTALL_PREFIX}/lib/python3${minver}.lib
    # Copying .pc files
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/python3-embed.pc ${MINGW_INSTALL_PREFIX}/lib/pkgconfig/python3-embed.pc
)

cleanup(python3-embed manual-install)
