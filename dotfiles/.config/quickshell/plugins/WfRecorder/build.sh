#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "==> Building WfRecorder QML plugin..."
mkdir -p build && cd build

# Resolve the real C++ compiler — bypass ccache wrappers in PATH
_CXX=$(command -v g++ 2>/dev/null || command -v clang++ 2>/dev/null || true)
if [[ -z "$_CXX" ]]; then
  echo "ERROR: no C++ compiler found (g++ or clang++)" >&2; exit 1
fi

cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER="$_CXX"
make -j"$(nproc)"

echo "==> Installing to ~/.local/lib/qt6/qml/WfRecorder/ ..."
mkdir -p "$HOME/.local/lib/qt6/qml"
cmake --install .

echo "==> Done. Restart Quickshell to pick up the plugin."
