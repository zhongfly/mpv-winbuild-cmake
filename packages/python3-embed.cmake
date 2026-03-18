set(py_minor "14")
set(py_patch "3")
set(py_version "3.${py_minor}.${py_patch}")
set(py_embed_lib "python3${py_minor}")

if(TARGET_CPU STREQUAL "x86_64")
    set(py_embed_url "https://www.python.org/ftp/python/${py_version}/python-${py_version}-embed-amd64.zip")
    set(py_embed_hash "ad4961a479dedbeb7c7d113253f8db1b1935586b73c27488712beec4f2c894e6")
elseif(TARGET_CPU STREQUAL "i686")
    set(py_embed_url "https://www.python.org/ftp/python/${py_version}/python-${py_version}-embed-win32.zip")
    set(py_embed_hash "b249a32c4c186fef19b86a3ca8e7a9cdcacb3dc341228e44916e7defddb6119d")
    set(dlltool_opts "-U")
elseif(TARGET_CPU STREQUAL "aarch64")
    set(py_embed_url "https://www.python.org/ftp/python/${py_version}/python-${py_version}-embed-arm64.zip")
    set(py_embed_hash "3826ea24fb771a0e15aff90ab9bedcbb914d41a5df280b44ae3a43cd61cb9b02")
endif()

set(py_header_url "https://www.python.org/ftp/python/${py_version}/Python-${py_version}.tar.xz")
set(py_header_hash "a97d5549e9ad81fe17159ed02c68774ad5d266c72f8d9a0b5a9c371fe85d902b")

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
