# shellcheck shell=bash
# Sourced by setup.sh (and by tests/test_find_python.sh). Picks the interpreter for the virtual environment.
#
# The requirements need Python >= 3.10 (pre-commit 4.5). Where plain python3 is older (Ubuntu 20.04 ships 3.8),
# find_python looks for a newer python3.X on the PATH. Only shell builtins are used besides the interpreters
# themselves, so the tests can run it with a PATH that holds nothing but fake interpreters.

VENVPP2_MIN_MAJOR=3
VENVPP2_MIN_MINOR=10

# Interpreters tried in order when PYTHON is not set: newest first, plain python3 last.
VENVPP2_PYTHON_CANDIDATES="python3.14 python3.13 python3.12 python3.11 python3.10 python3"

# True when $1 runs, has the venv module and is at least VENVPP2_MIN_MAJOR.VENVPP2_MIN_MINOR.
py_ok() {
    local version major minor
    version="$("$1" -c 'import sys, venv; print("%d.%d" % sys.version_info[:2])' 2>/dev/null)" || return 1
    major="${version%%.*}"
    minor="${version#*.}"
    case "$major$minor" in
        '' | *[!0-9]*) return 1 ;;
    esac
    [ "$major" -gt "$VENVPP2_MIN_MAJOR" ] ||
        { [ "$major" -eq "$VENVPP2_MIN_MAJOR" ] && [ "$minor" -ge "$VENVPP2_MIN_MINOR" ]; }
}

# Prints the interpreter to use: $PYTHON when set, otherwise the first candidate on the PATH that passes py_ok.
# Prints the reason on stderr and returns 1 when there is none.
find_python() {
    local candidate
    if [ -n "${PYTHON:-}" ]; then
        if py_ok "$PYTHON"; then
            echo "$PYTHON"
            return 0
        fi
        echo "PYTHON=$PYTHON is not a Python >= $VENVPP2_MIN_MAJOR.$VENVPP2_MIN_MINOR with the venv module." >&2
        return 1
    fi
    for candidate in $VENVPP2_PYTHON_CANDIDATES; do
        if command -v "$candidate" >/dev/null 2>&1 && py_ok "$candidate"; then
            echo "$candidate"
            return 0
        fi
    done
    echo "No Python >= $VENVPP2_MIN_MAJOR.$VENVPP2_MIN_MINOR with the venv module found." >&2
    echo "Install one (e.g. python3.12 and python3.12-venv) or set PYTHON=<path to python>." >&2
    return 1
}
