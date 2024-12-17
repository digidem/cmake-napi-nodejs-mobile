include_guard()

set(napi_module_dir "${CMAKE_CURRENT_LIST_DIR}")

function(download_node_headers result)
  set(one_value_keywords
    DESTINATION
    VERSION
    IMPORT_FILE
    NODE_BIN
  )

  cmake_parse_arguments(
    PARSE_ARGV 1 ARGV "" "${one_value_keywords}" ""
  )

  if(NOT ARGV_DESTINATION)
    set(ARGV_DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/_napi")
  endif()

  if(NOT ARGV_VERSION)
    set(ARGV_VERSION "18.20.4")
  endif()

  napi_target(target)

  set(version "v${ARGV_VERSION}")

  set(archive "${CMAKE_CURRENT_BINARY_DIR}/node-${version}.tar.gz")

  file(DOWNLOAD
    "https://github.com/nodejs-mobile/nodejs-mobile/releases/download/${version}/nodejs-mobile-${version}-android.zip"
    "${archive}"
  )

  file(ARCHIVE_EXTRACT
    INPUT "${archive}"
    DESTINATION "${ARGV_DESTINATION}"
  )

  set(import_file ${ARGV_IMPORT_FILE})

  if(import_file)
    if(target MATCHES "win32")
      napi_arch(arch)

      set(lib "${ARGV_DESTINATION}/node-${version}/lib/node.lib")

      file(DOWNLOAD
        "https://nodejs.org/download/release/${version}/win-${arch}/node.lib"
        "${lib}"
      )

      set(${import_file} "${lib}")
    else()
      set(${import_file} ${import_file}-NOTFOUND)
    endif()
  endif()

  set(${result} "${ARGV_DESTINATION}/include/node")

  set(node_bin_arg ${ARGV_NODE_BIN})

  if (node_bin_arg)
    node_arch(arch)
    set(${node_bin_arg} "${ARGV_DESTINATION}/bin/${arch}/libnode.so")
  endif()

  return(PROPAGATE ${result} ${node_bin_arg} ${import_file})
endfunction()

function(napi_platform result)
  set(platform ${CMAKE_SYSTEM_NAME})

  if(NOT platform)
    set(platform ${CMAKE_HOST_SYSTEM_NAME})
  endif()

  string(TOLOWER ${platform} platform)

  if(platform MATCHES "darwin|ios|linux|android")
    set(${result} ${platform})
  elseif(platform MATCHES "windows")
    set(${result} "win32")
  else()
    set(${result} "unknown")
  endif()

  return(PROPAGATE ${result})
endfunction()

function(napi_arch result)
  if(APPLE AND CMAKE_OSX_ARCHITECTURES)
    set(arch ${CMAKE_OSX_ARCHITECTURES})
  elseif(MSVC AND CMAKE_GENERATOR_PLATFORM)
    set(arch ${CMAKE_GENERATOR_PLATFORM})
  elseif(ANDROID AND CMAKE_ANDROID_ARCH_ABI)
    set(arch ${CMAKE_ANDROID_ARCH_ABI})
  else()
    set(arch ${CMAKE_SYSTEM_PROCESSOR})
  endif()

  if(NOT arch)
    set(arch ${CMAKE_HOST_SYSTEM_PROCESSOR})
  endif()

  string(TOLOWER ${arch} arch)

  if(arch MATCHES "arm64|aarch64")
    set(${result} "arm64")
  elseif(arch MATCHES "armv7-a|armeabi-v7a")
    set(${result} "arm")
  elseif(arch MATCHES "x64|x86_64|amd64")
    set(${result} "x64")
  elseif(arch MATCHES "x86|i386|i486|i586|i686")
    set(${result} "ia32")
  else()
    set(${result} "unknown")
  endif()

  return(PROPAGATE ${result})
endfunction()

function(node_arch result)
  napi_arch(arch)

  if(arch STREQUAL "arm")
    set(${result} "armeabi-v7a")
  elseif(arch STREQUAL "arm64")
    set(${result} "arm64-v8a")
  elseif(arch STREQUAL "ia32")
    set(${result} "x86")
  elseif(arch STREQUAL "x64")
    set(${result} "x86_64")
  else()
    set(${result} ${arch})
  endif()

  return(PROPAGATE ${result})
endfunction()

function(napi_target result)
  napi_platform(platform)
  napi_arch(arch)

  set(${result} ${platform}-${arch})

  return(PROPAGATE ${result})
endfunction()

function(napi_module_target directory result)
  set(one_value_keywords
    NAME
    VERSION
    HASH
  )

  cmake_parse_arguments(
    PARSE_ARGV 2 ARGV "" "${one_value_keywords}" ""
  )

  set(package_path package.json)

  cmake_path(ABSOLUTE_PATH directory NORMALIZE)

  cmake_path(ABSOLUTE_PATH package_path BASE_DIRECTORY "${directory}" NORMALIZE)

  file(READ "${package_path}" package)

  string(JSON name GET "${package}" "name")

  string(REGEX REPLACE "/" "+" name ${name})
  string(REGEX REPLACE "^@" "" name ${name})

  string(JSON version GET "${package}" "version")

  string(SHA256 hash "napi ${package_path}")

  string(SUBSTRING "${hash}" 0 8 hash)

  set(${result} "${name}-${version}-${hash}")

  if(ARGV_NAME)
    set(${ARGV_NAME} ${name} PARENT_SCOPE)
  endif()

  if(ARGV_VERSION)
    set(${ARGV_VERSION} ${version} PARENT_SCOPE)
  endif()

  if(ARGV_HASH)
    set(${ARGV_HASH} ${hash} PARENT_SCOPE)
  endif()

  return(PROPAGATE ${result})
endfunction()

function(add_napi_module result)
  download_node_headers(node_headers IMPORT_FILE node_lib NODE_BIN node_bin)

  napi_module_target("." target NAME name VERSION version)

  string(REGEX MATCH "^[0-9]+" major "${version}")

  add_library(${target} OBJECT)

  set_target_properties(
    ${target}
    PROPERTIES
    C_STANDARD 11
    CXX_STANDARD 20
    POSITION_INDEPENDENT_CODE ON
  )

  target_include_directories(
    ${target}
    PRIVATE
      ${node_headers}
  )

  set(${result} ${target})

  napi_target(host)

  if(host MATCHES "ios")
    return(PROPAGATE ${result})
  endif()

  add_library(${target}_module SHARED)

  set_target_properties(
    ${target}_module
    PROPERTIES

    OUTPUT_NAME ${name}
    PREFIX ""
    SUFFIX ".node"
    IMPORT_PREFIX ""
    IMPORT_SUFFIX ".node.lib"

    # Don't set a shared library name to allow loading the resulting library as
    # a plugin.
    NO_SONAME ON

    # Set the Mach-O compatibility versions for macOS and iOS. This is mostly
    # for debugging purposes.
    MACHO_CURRENT_VERSION ${version}
    MACHO_COMPATIBILITY_VERSION ${major}

    # Automatically export all available symbols on Windows. Without this,
    # module authors would have to explicitly export public symbols.
    WINDOWS_EXPORT_ALL_SYMBOLS ON
  )

  target_link_libraries(
    ${target}_module
    PRIVATE
      ${target}
  )

  if(host MATCHES "android")
    target_link_libraries(
      ${target}_module
      PRIVATE
        ${node_bin}
    )
  endif()

  if(host MATCHES "win32")
    add_executable(${target}_import_library IMPORTED)

    set_target_properties(
      ${target}_import_library
      PROPERTIES
      ENABLE_EXPORTS ON
      IMPORTED_IMPLIB "${node_lib}"
    )

    if(NOT TARGET napi_delay_load)
      add_library(napi_delay_load STATIC)

      target_sources(
        napi_delay_load
        PRIVATE
          "${napi_module_dir}/win32/delay-load.c"
      )

      target_include_directories(
        napi_delay_load
        PRIVATE
          ${napi_headers}
      )

      target_link_libraries(
        napi_delay_load
        INTERFACE
          delayimp
      )

      target_link_options(
        napi_delay_load
        INTERFACE
          /DELAYLOAD:node.exe
      )
    endif()

    target_link_libraries(
      ${target}_module
      PRIVATE
        ${target}_import_library
      PUBLIC
        napi_delay_load
    )
  else()
    target_link_options(
      ${target}_module
      PRIVATE
        -Wl,-undefined,dynamic_lookup
    )
  endif()

  install(
    FILES $<TARGET_FILE:${target}_module>
    DESTINATION ${host}
    RENAME ${name}.node
  )

  return(PROPAGATE ${result})
endfunction()
