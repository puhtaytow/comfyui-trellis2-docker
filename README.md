# ComfyUI TRELLIS2 Docker

This is a ready-to-run Docker setup for `ComfyUI` configured for `TRELLIS2`.

The image installs:

- `ComfyUI`
- `ComfyUI-Manager`
- `ComfyUI-TRELLIS2`
- `rgthree-comfy`
- `ComfyUI-VideoHelperSuite`

The stack is intended to run on an NVIDIA GPU and exposes the ComfyUI web interface on port `8188`.

## What It Is

This directory is a Docker wrapper around ComfyUI with the custom nodes needed for TRELLIS2. Instead of manually installing Python, system packages, dependencies, and custom nodes, you build one image and run a ready-made container.

It is useful if you want to:

- get ComfyUI with TRELLIS2 running quickly,
- keep models, input, and output outside the container,
- move the setup between machines more easily,
- avoid manual dependency installation.

## Requirements

Before starting, you need:

- Docker
- `docker compose`
- an NVIDIA GPU
- `NVIDIA Container Toolkit`

## Quick Start

Go to the project directory:

```bash
cd comfyui-trellis2-docker
```

Build the image and start the container:

```bash
docker compose up --build -d
```

Then open:

```text
http://localhost:8188
```

Stop the container:

```bash
docker compose down
```

View logs:

```bash
docker compose logs -f
```

## What Happens During Build

During the image build, Docker:

- downloads `ComfyUI`,
- installs Python dependencies,
- clones the required `custom_nodes`,
- runs the install step for `ComfyUI-TRELLIS2`,
- prepares directories for models, inputs, and outputs.

On first use, TRELLIS2 may still download some models into the Hugging Face cache.

## Where Data Is Stored

By default, `docker-compose.yml` maps `./data` into the container:

- `./data/models` -> `/opt/comfyui/models`
- `./data/input` -> `/opt/comfyui/input`
- `./data/output` -> `/opt/comfyui/output`
- `./data/user` -> `/opt/comfyui/user`
- `./data/huggingface` -> `/root/.cache/huggingface`

This keeps your data persistent even if the container is removed.

## Configuration

The main variables used by `docker-compose.yml` are:

- `COMFYUI_PORT` - host port, default `8188`
- `CONTAINER_NAME` - container name, default `comfyui-trellis2`
- `IMAGE_NAME` - image name, default `comfyui-trellis2:latest`
- `COMFYUI_DATA_DIR` - persistent data directory, default `./data`
- `BASE_IMAGE` - base PyTorch/CUDA image
- `NVIDIA_VISIBLE_DEVICES` - which GPUs are visible inside the container

Example `.env` file:

```env
COMFYUI_PORT=8188
COMFYUI_DATA_DIR=./data
CONTAINER_NAME=comfyui-trellis2
IMAGE_NAME=comfyui-trellis2:latest
NVIDIA_VISIBLE_DEVICES=all
```

After changing configuration, rebuild and start the service again:

```bash
docker compose up --build -d
```

## Useful Commands

Open a shell inside the running container:

```bash
docker exec -it comfyui-trellis2 bash
```

Check service status:

```bash
docker compose ps
```

Stop and remove the container:

```bash
docker compose down
```