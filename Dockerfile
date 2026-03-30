ARG BASE_IMAGE=k1llahkeezy/pytorch-blackwell:0.2.0
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG COMFYUI_REPO=https://github.com/comfyanonymous/ComfyUI.git
ARG COMFYUI_REF=master
ARG MANAGER_REPO=https://github.com/ltdrdata/ComfyUI-Manager.git
ARG MANAGER_REF=main
ARG TRELLIS_REPO=https://github.com/PozzettiAndrea/ComfyUI-TRELLIS2.git
ARG TRELLIS_REF=main
ARG RGTHREE_REPO=https://github.com/rgthree/rgthree-comfy.git
ARG RGTHREE_REF=main
ARG VHS_REPO=https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git
ARG VHS_REF=main

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    COMFYUI_HOME=/opt/comfyui \
    HF_HOME=/root/.cache/huggingface \
    PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True \
    CUDA_LAUNCH_BLOCKING=0

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    ffmpeg \
    git \
    git-lfs \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    ninja-build \
    python3-dev \
    && git lfs install --system \
    && rm -rf /var/lib/apt/lists/*

RUN clone_repo() { \
        local repo="$1"; \
        local ref="$2"; \
        local dest="$3"; \
        git clone --filter=blob:none "$repo" "$dest"; \
        git -C "$dest" checkout "$ref"; \
    }; \
    clone_repo "$COMFYUI_REPO" "$COMFYUI_REF" "$COMFYUI_HOME" && \
    python3 -m pip install --upgrade pip setuptools wheel && \
    python3 -m pip install -r "${COMFYUI_HOME}/requirements.txt"

RUN clone_repo() { \
        local repo="$1"; \
        local ref="$2"; \
        local dest="$3"; \
        git clone --filter=blob:none "$repo" "$dest"; \
        git -C "$dest" checkout "$ref"; \
    }; \
    mkdir -p "${COMFYUI_HOME}/custom_nodes" && \
    clone_repo "$MANAGER_REPO" "$MANAGER_REF" "${COMFYUI_HOME}/custom_nodes/ComfyUI-Manager" && \
    if [[ -f "${COMFYUI_HOME}/custom_nodes/ComfyUI-Manager/requirements.txt" ]]; then \
        python3 -m pip install -r "${COMFYUI_HOME}/custom_nodes/ComfyUI-Manager/requirements.txt"; \
    fi && \
    clone_repo "$TRELLIS_REPO" "$TRELLIS_REF" "${COMFYUI_HOME}/custom_nodes/ComfyUI-TRELLIS2" && \
    if [[ -f "${COMFYUI_HOME}/custom_nodes/ComfyUI-TRELLIS2/requirements.txt" ]]; then \
        awk '!/^(torch|torchvision|torchaudio)([<>=!~].*)?$/' \
            "${COMFYUI_HOME}/custom_nodes/ComfyUI-TRELLIS2/requirements.txt" \
            > "${COMFYUI_HOME}/custom_nodes/ComfyUI-TRELLIS2/requirements.filtered.txt" && \
        mv "${COMFYUI_HOME}/custom_nodes/ComfyUI-TRELLIS2/requirements.filtered.txt" \
            "${COMFYUI_HOME}/custom_nodes/ComfyUI-TRELLIS2/requirements.txt" && \
        python3 -m pip install -r "${COMFYUI_HOME}/custom_nodes/ComfyUI-TRELLIS2/requirements.txt"; \
    fi && \
    python3 -m pip install plyfile zstandard && \
    mkdir -p "${HF_HOME}/hub/trellis2_config" && \
    if curl -fsSL \
        "https://huggingface.co/microsoft/TRELLIS.2-4B/raw/main/pipeline.json" \
        -o /tmp/pipeline.json; then \
        sed -i 's|\"ckpts/|\"microsoft/TRELLIS.2-4B/ckpts/|g' /tmp/pipeline.json && \
        cp /tmp/pipeline.json "${HF_HOME}/hub/trellis2_config/pipeline.json"; \
    else \
        echo "Skipping cached TRELLIS pipeline bootstrap."; \
    fi && \
    if [[ -f "${COMFYUI_HOME}/custom_nodes/ComfyUI-TRELLIS2/install.py" ]]; then \
        (cd "${COMFYUI_HOME}/custom_nodes/ComfyUI-TRELLIS2" && python3 install.py); \
    fi && \
    clone_repo "$RGTHREE_REPO" "$RGTHREE_REF" "${COMFYUI_HOME}/custom_nodes/rgthree-comfy" && \
    if [[ -f "${COMFYUI_HOME}/custom_nodes/rgthree-comfy/requirements.txt" ]]; then \
        python3 -m pip install -r "${COMFYUI_HOME}/custom_nodes/rgthree-comfy/requirements.txt"; \
    fi && \
    clone_repo "$VHS_REPO" "$VHS_REF" "${COMFYUI_HOME}/custom_nodes/ComfyUI-VideoHelperSuite" && \
    if [[ -f "${COMFYUI_HOME}/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt" ]]; then \
        python3 -m pip install -r "${COMFYUI_HOME}/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt"; \
    fi

RUN mkdir -p \
    "${COMFYUI_HOME}/input" \
    "${COMFYUI_HOME}/output" \
    "${COMFYUI_HOME}/user" \
    "${COMFYUI_HOME}/models/trellis2" \
    "${COMFYUI_HOME}/models/dinov3" \
    "${COMFYUI_HOME}/models/birefnet"

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

WORKDIR ${COMFYUI_HOME}

EXPOSE 8188

VOLUME ["/opt/comfyui/models", "/opt/comfyui/input", "/opt/comfyui/output", "/opt/comfyui/user"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
    CMD curl -fsS "http://127.0.0.1:${COMFYUI_PORT:-8188}/" || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
