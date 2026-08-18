# cmake-napi

Node-API utilities for CMake.

```
npm i cmake-napi
```

```cmake
find_package(cmake-napi REQUIRED PATHS node_modules/cmake-napi)
```

## nodejs-mobile fork

This is [digidem](https://github.com/digidem)'s fork of
[holepunchto/cmake-napi](https://github.com/holepunchto/cmake-napi). It links
`.node` addons against [digidem/nodejs-mobile](https://github.com/digidem/nodejs-mobile)
releases for Android and iOS instead of downloading Node.js headers from
nodejs.org, and it builds iOS targets (upstream skips iOS).

Configure with CMake cache variables:

- `NAPI_NODE_VERSION` (default `24.19.0-0`): nodejs-mobile release to build
  against, without the leading `v`.
- `NAPI_NODE_MOBILE_REPO` (default `digidem/nodejs-mobile`): GitHub repository
  hosting the releases.

Only the nodejs-mobile v24 release line is supported. The last revision that
worked with legacy nodejs-mobile v18 is tagged
[`legacy-nodejs-mobile-v18`](https://github.com/digidem/cmake-napi-nodejs-mobile/releases/tag/legacy-nodejs-mobile-v18).

## API

#### `napi_platform(<result>)`

#### `napi_arch(<result>)`

#### `napi_environment(<result>)`

#### `napi_target(<result>)`

#### `napi_module_target(<directory> <result> [NAME <var>] [VERSION <var>] [HASH <var>])`

#### `add_napi_module(<result>)`

## License

Apache-2.0
