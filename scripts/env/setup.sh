#!/bin/bash
set -e

echo "=========================================="
echo "Setting up virtual environment..."
echo "=========================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Interpreter: $PYTHON if set, otherwise the newest python3.X on the PATH that is >= 3.10 (see find_python.sh)
# shellcheck source=SCRIPTDIR/find_python.sh
source "$SCRIPT_DIR/find_python.sh"
PY="$(find_python)" || exit 1
echo "Using $PY ($("$PY" --version 2>&1))"

# Recreate .venv when it was built with an older Python
if [ -x .venv/bin/python ] && ! py_ok .venv/bin/python; then
    echo "Existing .venv uses $(.venv/bin/python --version 2>&1): recreating it"
    rm -rf .venv
fi

# Create a virtual environment
"$PY" -m venv .venv

# Set CONAN_HOME environment variable in the activate script (once, also on reruns)
grep -q CONAN_HOME .venv/bin/activate || echo "export CONAN_HOME=\$PWD/.conan2" >> .venv/bin/activate

# Activate the virtual environment
# shellcheck disable=SC1091
source .venv/bin/activate

# Upgrade pip
python3 -m pip install --upgrade pip

# Install the required packages (resolved relative to this script's location)
pip install -r "$SCRIPT_DIR/../requirements.txt"

# Install pre-commit hooks
pre-commit install

echo "=========================================="
echo "Virtual environment '.venv' is now active."
echo "=========================================="

# Open a shell with the environment active, only when run from a terminal (not in CI or tests)
if [ -t 0 ] && [ -t 1 ]; then
    exec "$SHELL"
fi

# chmod +x scripts/env/setup.sh
# scripts/env/setup.sh
