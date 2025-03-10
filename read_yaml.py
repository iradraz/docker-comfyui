import os
import yaml
import sys

# Get the TMP_DIR value from environment variables
tmp_dir = os.getenv('TMP_DIR')

if tmp_dir is None:
    print("Error: TMP_DIR environment variable is not set.")
    sys.exit(1)

# Construct the config file path
config_file_path = os.path.join(tmp_dir, 'config.yaml')  # This becomes '/tmp/config.yaml'

# Debug print to verify the path
print(f"Trying to open config file at: {config_file_path}")

# Load the YAML file
with open(config_file_path, "r") as file:
    config = yaml.safe_load(file)

# Get the desired model categories from command line arguments
desired_models_input = sys.argv[1] if len(sys.argv) > 1 else ""
desired_categories = set(desired_models_input.split(','))

models_found = False

# Loop through each category and each model within that category
for category, models in config.items():
    for model in models:
        model_category = model.get("model_categories")  # Access the model_categories field
        repo = model.get("repo")  # get repo name
        repo_path = model.get("repo_path")                     # Get file path
        local_dir = model.get("local_dir")                   # Get model dir
        local_name = model.get("local_name")                   # Get model name

        # Debugging output for the model dictionary
        #print(f"DEBUG: Model dict: {model}")

        # Check if the model's category is in the desired categories
        if model_category and model_category[0] in desired_categories:  
            models_found = True
            print(f"{category},{repo},{repo_path},{local_dir},{local_name}")
    

if not models_found:
    print("No matching models found in the specified categories.")
