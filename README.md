# venvpp2
Welcome to venvpp2!

This project is an evolution of my previous [venvpp](https://github.com/TeiaCare/venvpp).

The main enhancements with respect to its predecessor are:
[Conan v2](https://conan.io/) and [CMake v4](https://cmake.org/) with the usage of *CMakePresets* as first class citizens replacing the older custom Python scripts to addressing Configure, Build, Install, Test and Package the project.

---

## Getting started
In order to spin up a fresh C++ development environment in your local repository just run the following command.

The setup scripts resolve their requirements file relative to the script itself, so they can be invoked from any working directory.

### Setup Virtual Environment

```bash
# MacOS/Linux
scripts/env/setup.sh
source .venv/bin/activate

# Windows
scripts/env/setup.bat
.venv\Scripts\activate.bat
```

The virtual environment installs the toolchain pinned in `scripts/requirements.txt`:
`cmake`, `conan`, `ninja`, `clang-format`, `pre-commit` and `gcovr` (used by the coverage tool).

It needs Python 3.10 or newer (`pre-commit` 4.5). On Linux/macOS `setup.sh` picks the newest `python3.X` on the
`PATH` that meets it, so it works where `python3` is older (Ubuntu 20.04 ships 3.8). Set `PYTHON=<path to python>` to
choose the interpreter. An existing `.venv` built with an older Python is recreated. When there is no suitable
Python, `setup.sh` stops before creating `.venv` and says so.

On Ubuntu 20.04 neither the Ubuntu archive (3.9 at most) nor the deadsnakes PPA (no longer built for 20.04) provides
Python 3.10 or newer: install it another way (e.g. `uv python install 3.12`) and pass it with `PYTHON`.

### Tests
`tests/test_find_python.sh` checks which interpreter `setup.sh` picks, with fake interpreters (no network).
After `scripts/env/setup.sh`, `bash tests/check_venv.sh <major.minor>` checks the environment it left: Python
version, installed tools, `CONAN_HOME` set once, pre-commit hook.

## Install Conan packages
```bash
# Install packages and create CMakePresets.json + CMake toolchain file
conan install . -b=missing -pr:a=profiles/linux-clang -s build_type=Debug
```

Profiles for the supported toolchains live under `profiles/` (`linux-clang`, `linux-gcc`, `macos-arm64`, `macos-x64`, `windows-msvc`).

## Configure, Build and Install
```bash
# CMake configure
cmake --preset conan-debug

# CMake build
cmake --build build/Debug

# CMake install
cmake --install build/Debug

# Run
install/venvpp2_example
```

## Lockfile
```bash
# Create lockfile
conan lock create .

# Install using lockfile
conan install . --lockfile=conan.lock --output-folder=build/Release
```

---

## Build & QA tools

The `tools/` directory ships a set of shared Python helpers that wrap the most common
build, test and analysis commands. They share a thin `command.py` runner and are designed
to be reused both locally and in CI.

| Script | Purpose |
| --- | --- |
| `run_unit_tests.py` | Run unit tests via `ctest` (default) or directly via the GoogleTest binary, emitting a JUnit XML report. |
| `run_coverage.py` | Generate Cobertura XML and HTML coverage reports with `gcovr` (supports `gcc` and `clang`/`apple-clang`). |
| `run_sanitizer.py` | Run a binary under AddressSanitizer (`--address_sanitizer`) or ThreadSanitizer (`--thread_sanitizer`). |
| `run_valgrind.py` | Run a binary under Valgrind `memcheck` or `callgrind`. |
| `install_valgrind.sh` | Build & cache Valgrind from source (used by CI). |
| `run_benchmarks.py` | Execute a Google Benchmark binary and dump JSON results. |
| `run_examples.py` | Discover and execute every executable found in an examples directory. |
| `run_clang_format.py` | Format C/C++ sources in parallel using `clang-format -style=file`. |
| `run_clang_tidy.py` | Run `clang-tidy` checks on C/C++ sources in parallel. |
| `run_cppcheck.py` | Run `cppcheck` against the project's `compile_commands.json`. |
| `run_doxygen.py` | Generate Doxygen documentation from a given `Doxyfile`. |

Each script exposes `--help` for the full list of arguments and defaults.
