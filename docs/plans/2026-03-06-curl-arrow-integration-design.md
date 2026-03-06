# Design: Integrate curl into Arrow's dependency chain

## Problem

jpfeuffer's review on PR #173 asks that the dependency chain
curl -> aws-sdk -> arrow/parquet uses the same curl built by contrib.

Currently:
- CURL is built after Arrow (wrong order)
- Arrow has no S3/curl options enabled
- Arrow does not bundle curl — it requires it via `find_package(CURL)`

## Approach

Build CURL before ARROW and configure Arrow to use it via the existing
`CMAKE_PREFIX_PATH` mechanism (same pattern used for boost, zlib, bzip2).

## Changes

### 1. CMakeLists.txt — Reorder build

Move the CURL build block before ARROW. New order:
... -> BOOST -> CURL -> ARROW -> ...

### 2. libraries.cmake/arrow.cmake — Enable S3 with bundled AWS SDK

Add to both Windows and Linux/macOS cmake invocations:
- `-DARROW_S3=ON` — enables S3 filesystem, triggers AWS SDK + curl
- `-DAWSSDK_SOURCE=BUNDLED` — Arrow builds AWS SDK from source, using our curl

Curl is found automatically via `CMAKE_PREFIX_PATH=${PROJECT_BINARY_DIR}`
which is already set in arrow.cmake. No extra flags needed.

### 3. No other changes needed

- curl.cmake already installs to `${PROJECT_BINARY_DIR}`
- Dockerfiles already have `libcurl-dev`
- No new dependency resolution mechanism required

## Key facts

- Arrow 23.0.0 does NOT support `CURL_SOURCE=BUNDLED` — curl must be a system/pre-built dependency
- Arrow finds curl via standard `find_package(CURL REQUIRED)` in its `find_curl()` macro
- AWS SDK can be BUNDLED by Arrow, but still requires external curl
