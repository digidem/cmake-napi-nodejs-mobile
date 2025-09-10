# cmake-napi

Node-API utilities for CMake.

```
npm i cmake-napi
```

```cmake
find_package(cmake-napi REQUIRED PATHS node_modules/cmake-napi)
```

## API

#### `napi_platform(<result>)`

#### `napi_arch(<result>)`

#### `napi_environment(<result>)`

#### `napi_target(<result>)`

#### `napi_module_target(<directory> <result> [NAME <var>] [VERSION <var>] [HASH <var>])`

#### `add_napi_module(<result>)`

## License

Apache-2.0
