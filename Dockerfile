FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV SHELL=/bin/bash
# Update package list and install dependencies
RUN apt-get update -y && apt-get install --yes --no-install-recommends \
    software-properties-common libgl1 \
    build-essential \
    ffmpeg libsm6 libxext6 \
    nvidia-cuda-toolkit \
    wget git sudo curl vim bash 
#    rm -rf /var/lib/apt/lists/*
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt install python3.11 python3.11-distutils python3.11-venv python3.11-dev python3-pip -y --no-install-recommends
RUN python3 -m pip install --upgrade pip

# Set Python 3.10 as the default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1

RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

RUN git clone https://github.com/comfyanonymous/ComfyUI.git /tmp/ComfyUI
RUN pip install --no-cache-dir -r /tmp/ComfyUI/requirements.txt

RUN mkdir -p /tmp/ComfyUI/models/clip
RUN wget -O /tmp/ComfyUI/models/clip/t5xxl_fp8_e4m3fn.safetensors https://huggingface.co/mcmonkey/google_t5-v1_1-xxl_encoderonly/resolve/main/t5xxl_fp8_e4m3fn.safetensors
RUN wget -O /tmp/ComfyUI/models/clip/t5xxl_fp16.safetensors https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors
RUN wget -O /tmp/ComfyUI/models/clip/clip_l.safetensors https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors

RUN mkdir -p /tmp/ComfyUI/models/vae
RUN wget -O /tmp/ComfyUI/models/vae/ae.safetensors https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/ae.safetensors

RUN mkdir -p /tmp/ComfyUI/models/loras
RUN wget -O /tmp/ComfyUI/models/loras/Aesthetic_Amateur_Photo_V3.safetensors "https://civitai.com/api/download/models/805898?type=Model&format=SafeTensor"
RUN wget -O /tmp/ComfyUI/models/loras/flux_realism_lora.safetensors "https://huggingface.co/comfyanonymous/flux_RealismLora_converted_comfyui/resolve/main/flux_realism_lora.safetensors"

RUN mkdir -p /tmp/ComfyUI/models/controlnet
RUN wget -O /tmp/ComfyUI/models/controlnet/Flux.1-dev-Controlnet-Upscaler.safetensors "https://huggingface.co/jasperai/Flux.1-dev-Controlnet-Upscaler/resolve/main/diffusion_pytorch_model.safetensors"
RUN wget -O /tmp/ComfyUI/models/controlnet/control_v11p_sd15_canny.pth" https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_canny.pth"

COPY workflows /tmp/ComfyUI/user/default/workflows/
# Remove all files that don't have a .json extension and keep the directories

RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git /tmp/ComfyUI/custom_nodes/ComfyUI-Manager
RUN pip install --no-cache-dir -r /tmp/ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt
RUN pip install --no-cache-dir comfy_cli
RUN comfy --skip-prompt --no-enable-telemetry set-default /tmp/ComfyUI
RUN comfy --skip-prompt --no-enable-telemetry node install ComfyUI-Crystools
RUN comfy --skip-prompt --no-enable-telemetry node install ComfyUI-Custom-Scripts
RUN comfy --skip-prompt --no-enable-telemetry node install ComfyUI-GGUF
RUN comfy --skip-prompt --no-enable-telemetry node install ComfyUI_toyxyz_test_nodes
RUN comfy --skip-prompt --no-enable-telemetry node install cg-use-everywhere
RUN comfy --skip-prompt --no-enable-telemetry node install ComfyUI_IPAdapter_plus
RUN comfy --skip-prompt --no-enable-telemetry node install comfyui_controlnet_aux
RUN comfy --skip-prompt --no-enable-telemetry node install ComfyUI-Advanced-ControlNet
RUN comfy --skip-prompt --no-enable-telemetry node install ComfyUI-CogVideoXWrapper
RUN comfy --skip-prompt --no-enable-telemetry node install ComfyUI-VideoHelperSuite
RUN comfy --skip-prompt --no-enable-telemetry node install ComfyUI-MochiEdit
RUN comfy --skip-prompt --no-enable-telemetry node install ComfyUI-KJNodes
RUN comfy --skip-prompt --no-enable-telemetry node install ComfyUI_essentials
RUN comfy --skip-prompt --no-enable-telemetry node install ComfyUI-WD14-Tagger
RUN comfy --skip-prompt --no-enable-telemetry node install Image-Captioning-in-ComfyUI

# Clone ComfyUI repository and install requirements
WORKDIR /workspace

COPY setup.sh /tmp/setup.sh
RUN chmod +x /tmp/setup.sh
CMD bash -c "bash -x /tmp/setup.sh"
