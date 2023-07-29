set(minver "11")
set(relver "4")
set(verson 3.${minver}.${relver})
if(${TARGET_CPU} MATCHES "x86_64")
    set(link "https://www.python.org/ftp/python/${verson}/python-${verson}-embed-amd64.zip")
    set(hash "d0e85bf50d2adea597c40ee28e774081")
else()
    set(link "https://www.python.org/ftp/python/${verson}/python-${verson}-embed-win32.zip")
    set(hash "81b0acfcdd31a73d1577d6e977acbdc6")
    set(dlltool_opts "-U")
endif()
set(header_hash "bf6ec50f2f3bfa6ffbdb385286f2c628")

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
    COMMAND ${EXEC} ${TARGET_ARCH}-dlltool -d python3${minver}.def -y libpython3.${minver}.a ${dlltool_opts}
    LOG 1
)

ExternalProject_Add_Step(python3-embed manual-install
    DEPENDEES generate-lib
    WORKING_DIRECTORY <SOURCE_DIR>
    # Copying libs
    COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/libpython3.${minver}.a ${MINGW_INSTALL_PREFIX}/lib/libpython3.${minver}.a
    # Copying .pc files
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/python3-embed.pc ${MINGW_INSTALL_PREFIX}/lib/pkgconfig/python3-embed.pc
)

cleanup(python3-embed manual-install)
