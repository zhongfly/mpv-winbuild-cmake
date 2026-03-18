set(py_minor "12")
set(py_patch "10")
set(py_version "3.${py_minor}.${py_patch}")
set(py_embed_lib "python3${py_minor}")

if(TARGET_CPU STREQUAL "x86_64")
    set(py_embed_url "https://www.python.org/ftp/python/${py_version}/python-${py_version}-embed-amd64.zip")
    set(py_embed_hash "4acbed6dd1c744b0376e3b1cf57ce906f9dc9e95e68824584c8099a63025a3c3")
elseif(TARGET_CPU STREQUAL "i686")
    set(py_embed_url "https://www.python.org/ftp/python/${py_version}/python-${py_version}-embed-win32.zip")
    set(py_embed_hash "084b9eb24cb848605c895d05b738fbc2572efc8b4c18c415a824065864a2b853")
    set(dlltool_opts "-U")
elseif(TARGET_CPU STREQUAL "aarch64")
    set(py_embed_url "https://www.python.org/ftp/python/${py_version}/python-${py_version}-embed-arm64.zip")
    set(py_embed_hash "3065efc3d382d1cda66757ac71ade11904fa6e350f5a97eb74811acd71ba5532")
endif()

set(py_header_url "https://www.python.org/ftp/python/${py_version}/Python-${py_version}.tar.xz")
set(py_header_hash "07ab697474595e06f06647417d3c7fa97ded07afc1a7e4454c5639919b46eaea")

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/python3-embed.pc.in ${CMAKE_CURRENT_BINARY_DIR}/python3-embed.pc @ONLY)

set(GENERATE_DEF ${CMAKE_CURRENT_BINARY_DIR}/python3-embed-prefix/src/generate_def.sh)
file(WRITE ${GENERATE_DEF}
"#!/bin/bash
gendef $1.dll")

ExternalProject_Add(python3-header
    URL ${py_header_url}
    URL_HASH SHA256=${py_header_hash}
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
    URL ${py_embed_url}
    URL_HASH SHA256=${py_embed_hash}
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
    COMMAND ${EXEC} ${GENERATE_DEF} ${py_embed_lib}
    LOG 1
)

ExternalProject_Add_Step(python3-embed generate-lib
    DEPENDEES generate-def
    WORKING_DIRECTORY <SOURCE_DIR>
    COMMAND ${EXEC} ${TARGET_ARCH}-dlltool -m ${dlltool_image} ${dlltool_opts} -d ${py_embed_lib}.def -l ${py_embed_lib}.lib
    LOG 1
)

ExternalProject_Add_Step(python3-embed manual-install
    DEPENDEES generate-lib
    WORKING_DIRECTORY <SOURCE_DIR>
    COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/${py_embed_lib}.lib ${MINGW_INSTALL_PREFIX}/lib/${py_embed_lib}.lib
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/python3-embed.pc ${MINGW_INSTALL_PREFIX}/lib/pkgconfig/python3-embed.pc
)

cleanup(python3-embed manual-install)
