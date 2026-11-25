#!/bin/bash
# Checks the environment left by scripts/env/setup.sh. Run from the repository root after setup.sh.
#
#   bash tests/check_venv.sh <expected major.minor, e.g. 3.12>

set -eu

expected="$1"
fail() {
    echo "FAIL $*"
    exit 1
}

version="$(.venv/bin/python -c 'import sys; print("%d.%d" % sys.version_info[:2])')"
[ "$version" = "$expected" ] || fail ".venv uses Python $version, expected $expected"
echo "ok   .venv uses Python $version"

for tool in cmake conan ninja clang-format pre-commit gcovr; do
    [ -x ".venv/bin/$tool" ] || fail "$tool not installed in .venv"
done
echo "ok   requirements installed"

count="$(grep -c CONAN_HOME .venv/bin/activate)"
[ "$count" -eq 1 ] || fail "CONAN_HOME is set $count times in .venv/bin/activate"
echo "ok   CONAN_HOME set once"

hooks="$(git rev-parse --git-path hooks)"
[ -x "$hooks/pre-commit" ] || fail "pre-commit hook not installed"
echo "ok   pre-commit hook installed"
