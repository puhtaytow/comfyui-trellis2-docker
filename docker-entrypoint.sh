#!/usr/bin/env bash
set -euo pipefail

mkdir -p \
    "${COMFYUI_HOME}/input" \
    "${COMFYUI_HOME}/output" \
    "${COMFYUI_HOME}/user" \
    "${COMFYUI_HOME}/models"

echo "================================================="
echo "ComfyUI TRELLIS2 container"
echo "================================================="
if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader || true
else
    echo "nvidia-smi not available; continuing without GPU summary."
fi
echo "Listening on port ${COMFYUI_PORT:-8188}"
echo "================================================="

cd "${COMFYUI_HOME}"

if [[ "$#" -eq 0 ]]; then
    exec python3 main.py --listen 0.0.0.0 --port "${COMFYUI_PORT:-8188}"
fi

exec "$@"
