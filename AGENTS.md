# OpenMS contrib — Agent Notes

Context for AI agents (and humans) working on the OpenMS **contrib** tree — the
vendored third-party dependencies that get compiled and installed into
`<contrib>/build/` and then linked into OpenMS. Follows the
[AGENTS.md](https://agents.md) standard. See the repo-root `AGENTS.md` for
general OpenMS conventions.

Each library has a build macro in `libraries.cmake/<lib>.cmake` (e.g.
`curl.cmake`, `zlib.cmake`, `xercesc.cmake`). A macro typically: extracts the
archive, configures the upstream build, then `--build ... --target INSTALL`
into the shared contrib prefix.

## The #1 rule: on MSVC, build BOTH Debug and Release

**Every library that is *compiled* and *linked* into OpenMS must be built and
installed in both `--config Debug` AND `--config Release` on MSVC.**

MSVC cannot mix C runtimes in one link. A Debug OpenMS target uses the debug CRT
(`/MDd` → `MSVCRTD`); a Release target uses `/MD` → `MSVCRT`. If a contrib
library ships **only** a Release `.lib`, then linking a Debug OpenMS pulls that
release lib in, its embedded `/DEFAULTLIB:"MSVCRT"` directive collides with
`MSVCRTD`, and you get:

```
LINK : warning LNK4098: defaultlib 'MSVCRT' conflicts with use of other libs;
       use /NODEFAULTLIB:library
```

Worse than the warning: mixing debug/release CRTs across a DLL boundary can
cause heap corruption and crashes when non-C-ABI objects (STL types, allocated
memory) cross that boundary. `/NODEFAULTLIB:MSVCRT` only *silences the symptom*
— fix it at the source by producing the Debug variant.

### Symptoms that the Debug variant is missing
- `<contrib>/build/lib/` has `foo.lib` but no `food.lib` (debug libs use a
  trailing `d`, e.g. `zlibd.lib`, `libbz2d.lib`, `xerces-c_3D.lib`).
- A CMake package under `<contrib>/build/lib/cmake/<Pkg>/` has
  `<Pkg>Targets-release.cmake` but no `<Pkg>Targets-debug.cmake`
  (so the imported target has only `IMPORTED_LOCATION_RELEASE`, and Debug
  consumers silently fall back to the release lib).

### The correct pattern (mirror `zlib.cmake` / `xercesc.cmake`)
Build Debug first, then Release, both installing into the shared prefix. Guard
with `if(MSVC)` so single-config Unix/macOS builds keep doing a single build:

```cmake
if(MSVC)
  message(STATUS "Building <lib> (Debug) .. ")
  execute_process(COMMAND ${CMAKE_COMMAND} --build ${_BUILD_DIR} --target INSTALL --config Debug
                  WORKING_DIRECTORY ${_BUILD_DIR} RESULT_VARIABLE _ok ...)
  # check _ok, log, FATAL_ERROR on failure
endif()

message(STATUS "Building <lib> (Release) .. ")
execute_process(COMMAND ${CMAKE_COMMAND} --build ${_BUILD_DIR} --target INSTALL --config Release
                WORKING_DIRECTORY ${_BUILD_DIR} RESULT_VARIABLE _ok ...)
```

Note: pinning `-D CMAKE_BUILD_TYPE=Release` at the *configure* step is harmless
on the VS **multi-config** generator (it is ignored there) — the per-config
`--build --config Debug/Release` is what actually selects the CRT. Do not rely
on `CMAKE_BUILD_TYPE` to produce the debug lib on MSVC.

### Header-only / no-CRT exceptions
Libraries that emit no code with a CRT directive don't trigger this and may stay
Release-only: e.g. `eigen` (header-only) and `kissfft`. If in doubt, check the
produced `.lib` for a release CRT directive:

```bash
# from Git Bash: disable MSYS path mangling of the /flags, or use PowerShell
MSYS_NO_PATHCONV=1 grep -aoE 'DEFAULTLIB:"?(MSVCRT|LIBCMT)' <contrib>/build/lib/foo.lib
# a hit without a trailing 'D' (MSVCRT, not MSVCRTD) == release CRT baked in
```

## Consistency baseline (who builds both configs)

As of this writing these compiled+linked libs build Debug **and** Release on
MSVC — keep it that way when editing their macros: `arrow`, `bzip2`, `hdf5`,
`libsvm`, `libzip`, `xercesc`, `zlib`, `curl`. If you add a new compiled
dependency, follow the same pattern.

## Other contrib conventions

- All contrib libs and OpenMS must be built with the **same compiler/toolset**
  and link the **dynamic** CRT (`/MD`, `/MDd`) — never static (`/MT`, `/MTd`) —
  or you get multiply-defined-symbol errors. See the header comment in
  `CMakeLists.txt`.
- Prefer editing the per-library macro under `libraries.cmake/`; the top-level
  `CMakeLists.txt` drives which macros run.
- Log build output to `${LOGFILE}` and fail loudly (`FATAL_ERROR`) with the log
  path, matching the existing macros — silent partial installs are how the
  missing-debug-lib class of bug slips through.
- `contrib` is a **git submodule** of OpenMS. Changes here are committed in the
  contrib repo, and the submodule pointer is bumped in the main repo. Changes
  take effect only after the affected library is **rebuilt** (delete its stale
  output in `<contrib>/build/` or its per-lib build dir to force a fresh build).

## Debugging CRT / link issues on Windows

```bash
# Which linked lib pulls in the release CRT? (run per lib in the Debug link)
MSYS_NO_PATHCONV=1 grep -aoE 'DEFAULTLIB:"?(MSVCRT|LIBCMT|MSVCPRT)' foo.lib | sort -u
# Inspect an object's directives precisely (note: MSYS mangles /flags -> paths;
# set MSYS_NO_PATHCONV=1 or run dumpbin from PowerShell):
MSYS_NO_PATHCONV=1 dumpbin /nologo /directives foo.obj | grep -i defaultlib
```
