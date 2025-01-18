
## Key Files

- **config.yaml**: Configuration file containing model information.
- **Dockerfile**: Dockerfile for setting up the environment.
- **extract.sh**: Shell script for extracting data from png files.
- **read_yaml.py**: Python script for reading and processing the `config.yaml` file.
- **setup.sh**: Shell script for setting up the environment and downloading models.
- **workflows/**: Directory containing various workflow JSON files.

## Setup Instructions

### Environment Variables

- `DESIRED_MODELS`: Comma-separated list of desired model categories.

### Running the Setup

1. **Build the Docker Image**:
    ```sh
    docker build -t comfyui .
    ```

2. **Run the Docker Container**:
    ```sh
    docker run -e TMP_DIR=/tmp -e DESIRED_MODELS="all,hunyuan,hunyuan_low,mmaudio" comfyui
    ```

### Scripts

- **setup.sh**: This script sets up the environment, checks for required environment variables, and downloads the specified models.
    - It uses the [read_yaml.py] script to parse the [config.yaml] file and extract model information.
    - Downloads are managed with parallel processing to optimize speed.

- **read_yaml.py**: This script reads the [config.yaml] file and filters models based on the specified categories.
    - It outputs the model information in a format that [setup.sh] can process.

## Debugging

- Debugging output is available in both [setup.sh] and [read_yaml.py] to help trace issues during setup and model downloading.

## Workflows

The [workflows] directory contains various JSON files that define different workflows for ComfyUI. These workflows can be used to automate tasks and processes within the UI.

## License

This project is licensed under the MIT License.
