FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV SHELL=/bin/bash
ENV VENV_DIR=/workspace/venv
ENV TMP_DIR=/tmp
ENV BASE_DIR=/workspace/ComfyU
# Update package list and install dependencies
RUN apt-get update -y -qq && apt-get install -qq --yes --no-install-recommends \
    software-properties-common libgl1 \
    build-essential rsync aria2 \
    ffmpeg libsm6 libxext6 \
    # nvidia-cuda-toolkit \
    wget git sudo curl vim bash \
    btop glances
 
#    rm -rf /var/lib/apt/lists/*
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt install -qq  python3.10 python3.10-distutils python3.10-venv python3.10-dev python3-pip -y --no-install-recommends

# Set Python 3.10 as the default
RUN python3 -m venv $TMP_DIR/venv
#RUN update-alternatives --install /usr/bin/python3 python3 $TMP_DIR/venv/bin/python3.10 1
RUN $TMP_DIR/venv/bin/python3 -m pip install --upgrade pip

RUN $TMP_DIR/venv/bin/pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

RUN $TMP_DIR/venv/bin/pip install -U --no-cache-dir jupyterlab jupyterlab_widgets ipykernel ipywidgets anyio comfy_cli

# Clone ComfyUI repository and install requirements
VOLUME ["/workspace"]
WORKDIR /workspace

COPY workflows /tmp/ComfyUI/user/default/workflows/
COPY config.yaml read_yaml.py setup.sh /tmp/
RUN chmod +x /tmp/setup.sh
CMD ["bash","-c","source /tmp/setup.sh"]
