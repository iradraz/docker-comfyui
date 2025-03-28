#!/bin/bash

# Define base final directory
BASE_DIR="/workspace/ComfyUI"
MODEL_DIR="$BASE_DIR/models"
MAX_PARALLEL_DOWNLOADS=5
DOWNLOAD_FLAG="$BASE_DIR/.download_done"
VENV_DIR=/workspace/venv
PATH="$VENV_DIR/bin:$PATH"

# Default values for flags
skip_verification=false
skip_downloads=false
use_cpu=false
while [ "$1" != "" ]; do
  case $1 in
    --sv)
      skip_verification=true
      ;;
    --sd)
      skip_downloads=true
      ;;
    --cpu)
      use_cpu=true
      ;;
    *)
      echo "Usage: $0 [-sv] [-sd] [-cpu] to skip verification and/or download and/or use cpu"
      exit 1
      ;;
  esac
  shift
done

download_models() {
    local running_downloads=0
    # Check if DESIRED_MODELS is set
    if [ -z "$DESIRED_MODELS" ]; then
        echo "Error: DESIRED_MODELS environment variable is not set."
        exit 1
    fi

    # Pass the DESIRED_MODELS variable to the Python script and process output lines'
    cd "$MODEL_DIR"
    #             print(f"{category},{repo},{repo_path},{local_dir},{local_name}")
    python3 $TMP_DIR/read_yaml.py "$DESIRED_MODELS" | while IFS=',' read -r CATEGORY REPO REPO_PATH LOCAL_DIR LOCAL_NAME; do
        echo "DEBUG: CATEGORY='$CATEGORY', MODEL_URL='$MODEL_URL', NAME='$NAME', CATEGORIES='$CATEGORIES'"  # Debug output

        # Check if NAME or MODEL_URL is empty
        if [ -z "$REPO" ] || [ -z "$REPO_PATH" ]; then
            echo "Warning: Name or REPO_PATH is missing. Skipping..."
            echo ""
            continue
        fi

        # Extract the directory path from the NAME field
        local DEST_DIR="$MODEL_DIR/$CATEGORY/$LOCAL_DIR"
        echo "Downloading $LOCAL_NAME to $DEST_DIR"
        echo ""

        # Create the directory if it doesn't exist
        mkdir -p "$DEST_DIR"
        cd "$DEST_DIR"

        #huggingface-cli login --token $HUGGINGFACE_APIKEY
        # Increment the counter for running downloads

        tmpdir=$(mktemp -d -p "$DEST_DIR")
        (
          huggingface-cli download "$REPO" "$REPO_PATH" --local-dir "$tmpdir" --token "$HUGGINGFACE_APIKEY" 2>&1
          # Wait until no .incomplete files remain in $tmpdir recursively
          while find "$tmpdir" -type f -name '*incomplete' | grep -q .; do
            sleep 1
          done
          sleep 5  # Wait for 5 seconds to ensure the file is fully downloaded
          # Look for the downloaded file with gguf, safetensors, or onnx extension
          downloaded_file=$(find "$tmpdir" -type f \( -iname "*.gguf" -o -iname "*.safetensors" -o -iname "*.onnx" \) | head -n 1)
          echo "Downloaded file: $downloaded_file"
          if [ -n "$downloaded_file" ] && [ -f "$downloaded_file" ]; then
            mv "$downloaded_file" "$DEST_DIR/$LOCAL_NAME"
          else
            echo "Download failed for $LOCAL_NAME"
          fi
          rm -rf "$tmpdir"
        ) &
        
        # Wait until the number of running "huggingface-cli" processes is below MAX_PARALLEL_DOWNLOADS
        while [ "$(pgrep -fc 'huggingface-cli')" -ge "$MAX_PARALLEL_DOWNLOADS" ]; do
          sleep 1
        done
    done

    # Create a flag file indicating completion
    touch $DOWNLOAD_FLAG
}

INSTALL_FLAG="$BASE_DIR/.installed"

BASHRC_CONTENT="
# Automatically activate virtual environment
if [ -d \"/workspace/venv\" ]; then
    source /workspace/venv/bin/activate
    alias python='/workspace/venv/bin/python'
    alias pip='/workspace/venv/bin/pip'
fi
"
echo "$BASHRC_CONTENT" >> ~/.bashrc

if [ ! -f "$INSTALL_FLAG" ]; then
    echo "Starting ComfyUI installation..."

    source ~/.bashrc
	rsync -av /tmp/venv/ $VENV_DIR
	sed -i 's|VIRTUAL_ENV=.*|VIRTUAL_ENV=/workspace/venv|' $VENV_DIR/bin/activate
	sed -i 's|/usr/bin|/workspace/venv|g' $VENV_DIR/pyvenv.cfg
	find /workspace/venv/bin -type f -exec sed -i '1s|^#!/tmp/venv/bin/python|#!/workspace/venv/bin/python|' {} \;
	rm -rf /tmp/venv/
    source $VENV_DIR/bin/activate
	
	# Check if nvidia-smi is installed and works
    nvidia_output=$(nvidia-smi 2>&1)
	# Check if the error message for Driver/library version mismatch is present
    if echo "$nvidia_output" | grep -q "Failed to initialize NVML: Driver/library version mismatch"; then
        echo "Error: Failed to initialize NVML - Driver/library version mismatch."
        exit 1
    fi

	# If nvidia-smi runs successfully, you can proceed with the rest of the script
    echo "$nvidia_output"
    echo "passes nvidia-smi initialized successfully."
    sleep 2
	

	# Loop until /workspace is mounted
    if [ "$skip_verification" = false ]; then
        while ! findmnt -rno TARGET /workspace > /dev/null; do
            echo "/workspace is not mounted. Waiting..."
            sleep 2  # Wait for 2 seconds before checking again
        done
        echo "/workspace is now mounted!"
    else
      echo "Skipping /workspace verification as requested."
    fi

	comfy --workspace=$BASE_DIR --skip-prompt --no-enable-telemetry install --nvidia --restore
	comfy --install-completion
    (
        comfy --skip-prompt --no-enable-telemetry node install comfy-image-saver &
        comfy --skip-prompt --no-enable-telemetry node install ComfyUI-HunyuanVideoSamplerSave &
        comfy --skip-prompt --no-enable-telemetry node install ComfyUI-OpenPose-Editor &
        comfy --skip-prompt --no-enable-telemetry node install x-flux-comfyui &
        comfy --skip-prompt --no-enable-telemetry node install ComfyUI_AdvancedRefluxControl &
        comfy --skip-prompt --no-enable-telemetry node registry-install comfyui-videohelpersuite &
        comfy --skip-prompt --no-enable-telemetry node registry-install comfyui-wd14-tagger &
        comfy --skip-prompt --no-enable-telemetry node registry-install comfyui-custom-scripts &
        comfy --skip-prompt --no-enable-telemetry node registry-install comfyui_essentials &
        comfy --skip-prompt --no-enable-telemetry node registry-install comfyui-webcam-node &
        comfy --skip-prompt --no-enable-telemetry node registry-install gguf &
        comfy --skip-prompt --no-enable-telemetry node registry-install comfyui_controlnet_aux &
        comfy --skip-prompt --no-enable-telemetry node registry-install comfyui_ipadapter_plus &
        comfy --skip-prompt --no-enable-telemetry node registry-install comfyui-hunyuanvideowrapper &
        comfy --skip-prompt --no-enable-telemetry node registry-install comfyui-advanced-controlnet &
        comfy --skip-prompt --no-enable-telemetry node registry-install rgthree-comfy &
        comfy --skip-prompt --no-enable-telemetry node registry-install comfyui_ultimatesdupscale &
        comfy --skip-prompt --no-enable-telemetry node registry-install comfyui-kjnodes &
        comfy --skip-prompt --no-enable-telemetry node registry-install cg-use-everywhere &
        comfy --skip-prompt --no-enable-telemetry node registry-install wavespeed &
        comfy --skip-prompt --no-enable-telemetry node registry-install comfyui-openpose-editor &
        comfy --skip-prompt --no-enable-telemetry node registry-install comfyui-crystools &
        comfy --skip-prompt --no-enable-telemetry node registry-install ComfyUI-WanVideoWrapper &
        comfy --skip-prompt --no-enable-telemetry node registry-install ComfyUI-LTXVideo &
        comfy --skip-prompt --no-enable-telemetry node registry-install was-node-suite-comfyui &
        comfy --skip-prompt --no-enable-telemetry node registry-install ComfyUI-Image-Filters &
        comfy --skip-prompt --no-enable-telemetry node registry-install comfyui-mmaudio &
        cd $BASE_DIR/custom_nodes && git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale --recursive &
        comfy --skip-prompt --no-enable-telemetry node registry-install comfyui_fill-nodes &
        comfy --skip-prompt --no-enable-telemetry node registry-install pulid_comfyui &
        comfy --skip-prompt --no-enable-telemetry node registry-install comfyui_pulid_flux_ll &

        wait
    ) &
    pid_comfy_nodes=$!
    wait $pid_comfy_nodes

	# comfy --skip-prompt --no-enable-telemetry node update all

	# Define the path to the settings file
	mkdir -p $BASE_DIR/user/default/
	SETTINGS_FILE="$BASE_DIR/user/default/comfy.settings.json"

	# Create the JSON content with just the desired setting
    cat <<EOF > $SETTINGS_FILE
{
    "Comfy.UseNewMenu": "Top",
    "Crystools.ShowRam": true,
    "Crystools.ShowCpu": true,
    "Crystools.ShowHdd": true,
    "Crystools.RefreshRate": 2,
    "Comfy.Workflow.ShowMissingModelsWarning": false,
    "Comfy.Keybinding.NewBindings": [
        {
            "commandId": "Comfy.ExportWorkflow",
            "combo": {
                "key": "s",
                "ctrl": true,
                "alt": false,
                "shift": false
            }
        }
    ],
    "Comfy.Keybinding.UnsetBindings": [
        {
            "commandId": "Comfy.SaveWorkflow",
            "combo": {
                "key": "s",
                "ctrl": true,
                "alt": false,
                "shift": false
            }
        }
    ]
}
EOF

	echo "Configuration file updated: $CONFIG_FILE"

	# Output a message to confirm the file was created
    echo "Settings file created at: $SETTINGS_FILE"
	# Proceed with the copy
    rsync -av --remove-source-files /tmp/ComfyUI/* $BASE_DIR
    if [ $? -ne 0 ]; then
        echo "Error during file transfer. Exiting."
        exit 1
    else
	echo "Files copied to $BASE_DIR"
	sleep 1
    fi
    sleep 1
    # Create the installation flag file

    jupyter lab --allow-root --no-browser --port=8888 --ip=* --ServerApp.terminado_settings="{\"shell_command\":[\"/bin/bash\"]}" --ServerApp.token=$SECRET --ServerApp.allow_origin=* --ServerApp.root_dir="/" &
    # Start ComfyUI
    if [ "$use_cpu" = false ]; then
        python $BASE_DIR/main.py --listen --port 8188 &
    else
	python $BASE_DIR/main.py --listen --port 8188 --cpu &
    fi

    if [ "$skip_downloads" = false ]; then
        # Download models in the background

        if [ ! -f "$DOWNLOAD_FLAG" ]; then
            echo "Downloading models..."
            download_models
        else
			echo "Models already downloaded. Skipping download_models."
        fi
    else
        echo "Skipping download process as requested."
    fi   

    touch "$INSTALL_FLAG"
    # Schedule stop after 2 hours
    (sleep 2h; runpodctl stop pod $RUNPOD_POD_ID)
else
    echo "ComfyUI is already installed. Running server installation."

	source ~/.bashrc
	rm -rf /tmp/venv/
    source $VENV_DIR/bin/activate
    jupyter lab --allow-root --no-browser --port=8888 --ip=* --ServerApp.terminado_settings="{\"shell_command\":[\"/bin/bash\"]}" --ServerApp.token=$SECRET --ServerApp.allow_origin=* --ServerApp.root_dir="/" &
    comfy --install-completion
    comfy --workspace=/workspace/ComfyUI/ --skip-prompt --no-enable-telemetry install --nvidia --restore

    if [ "$use_cpu" = false ]; then
        python $BASE_DIR/main.py --listen --port 8188 &
    else
        python $BASE_DIR/main.py --listen --port 8188 --cpu &
    fi

    if [ "$skip_downloads" = false ]; then
        # Download models in the background
        if [ ! -f "$DOWNLOAD_FLAG" ]; then
            echo "Downloading models..."
            download_models
        else
            echo "Models already downloaded. Skipping download_models."
        fi
    else
        echo "Skipping download process as requested."
    fi

    (sleep 2h; runpodctl stop pod $RUNPOD_POD_ID)
fi

sleep infinity
