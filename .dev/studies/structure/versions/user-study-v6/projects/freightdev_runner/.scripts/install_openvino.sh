#!/usr/bin/env bash
set -e

ENGINE_DIR="libs/engine/openvino"

if [ ! -d "$ENGINE_DIR" ]; then
    mkdir -p "$ENGINE_DIR"
    echo "Downloading OpenVINO..."
    git clone https://github.com/openvinotoolkit/openvino.git "$ENGINE_DIR"
else
    echo "OpenVINO already exists at $ENGINE_DIR"
fi

# Optional: build OpenVINO (you can skip if you just need runtime)
cd "$ENGINE_DIR"
mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
cmake --build . --parallel

echo "✅ OpenVINO installed in $ENGINE_DIR"
