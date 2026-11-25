#!/bin/bash
# Unit tests of scripts/env/find_python.sh: which interpreter setup.sh picks.
#
# Each case builds a directory of fake interpreters (shell scripts that answer like Python would to the
# probe in py_ok) and runs find_python with PATH set to that directory only. No real Python, no network.
#
#   bash tests/test_find_python.sh

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=SCRIPTDIR/../scripts/env/find_python.sh
source "$ROOT/scripts/env/find_python.sh"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASSED=0
FAILED=0

# fake <dir> <name> <version>: an interpreter reporting <version>; "novenv" makes the venv import fail.
fake() {
    local dir="$1" name="$2" version="$3"
    mkdir -p "$dir"
    # shellcheck disable=SC2016  # $1 belongs to the fake interpreter, not to this script
    if [ "$version" = novenv ]; then
        printf '#!/bin/sh\nexit 1\n' > "$dir/$name"
    else
        printf '#!/bin/sh\ncase "$1" in\n  --version) echo "Python %s.0" ;;\n  -c) echo "%s" ;;\nesac\n' \
            "$version" "$version" > "$dir/$name"
    fi
    chmod +x "$dir/$name"
}

# expect <case name> <dir> <expected interpreter or FAIL> [PYTHON value]
expect() {
    local name="$1" dir="$2" expected="$3" python="${4:-}" got rc
    got="$(PATH="$dir" PYTHON="$python" find_python 2>"$WORK/stderr")"
    rc=$?
    if [ "$expected" = FAIL ]; then
        if [ $rc -ne 0 ] && [ -z "$got" ] && [ -s "$WORK/stderr" ]; then
            PASSED=$((PASSED + 1))
            echo "ok   $name"
            return
        fi
        echo "FAIL $name: expected a failure with a message, got rc=$rc '$got'"
    else
        if [ $rc -eq 0 ] && [ "$got" = "$expected" ]; then
            PASSED=$((PASSED + 1))
            echo "ok   $name"
            return
        fi
        echo "FAIL $name: expected '$expected', got rc=$rc '$got' ($(cat "$WORK/stderr"))"
    fi
    FAILED=$((FAILED + 1))
}

d="$WORK/only-38"
fake "$d" python3 3.8
expect "python3 3.8 only: no interpreter" "$d" FAIL

d="$WORK/38-and-310"
fake "$d" python3 3.8
fake "$d" python3.10 3.10
expect "python3 3.8 and python3.10: python3.10 (3.10 compared as a number, not as text)" "$d" python3.10

d="$WORK/39-only"
fake "$d" python3 3.8
fake "$d" python3.9 3.9
expect "python3 3.8 and python3.9: no interpreter (3.9 is below the minimum)" "$d" FAIL

d="$WORK/python3-39"
fake "$d" python3 3.9
expect "python3 3.9: no interpreter" "$d" FAIL

d="$WORK/python3-310"
fake "$d" python3 3.10
expect "python3 3.10: python3 (exactly the minimum)" "$d" python3

d="$WORK/310-and-312"
fake "$d" python3 3.8
fake "$d" python3.10 3.10
fake "$d" python3.12 3.12
expect "python3.10 and python3.12: the newest" "$d" python3.12

d="$WORK/python3-312"
fake "$d" python3 3.12
expect "python3 already 3.12: python3" "$d" python3

d="$WORK/no-venv"
fake "$d" python3 3.8
fake "$d" python3.12 novenv
fake "$d" python3.10 3.10
expect "python3.12 without venv: skipped for python3.10" "$d" python3.10

d="$WORK/mislabelled"
fake "$d" python3.12 3.8
fake "$d" python3.11 3.11
expect "python3.12 that is really 3.8: skipped, the version is checked" "$d" python3.11

d="$WORK/python4"
fake "$d" python3 4.0
expect "major above 3: accepted" "$d" python3

d="$WORK/empty"
mkdir -p "$d"
expect "no python at all: no interpreter" "$d" FAIL

d="$WORK/env-ok"
fake "$d" python3.12 3.12
fake "$WORK/custom" python 3.11
expect "PYTHON set: used even when a newer python3.X exists" "$d" "$WORK/custom/python" "$WORK/custom/python"

d="$WORK/env-old"
fake "$d" python3.12 3.12
fake "$WORK/custom-old" python 3.9
expect "PYTHON too old: failure, no fallback" "$d" FAIL "$WORK/custom-old/python"

expect "PYTHON missing: failure" "$d" FAIL "$WORK/does-not-exist/python"

echo
echo "$PASSED passed, $FAILED failed"
[ "$FAILED" -eq 0 ]
