#!/bin/bash

usage() {
    echo "Usage: $0 -d <docker_start> -e <conda_env_name>"
    echo "  -d, --docker    Start Docker with the specified configuration"
    echo "  -e, --env       Specify the Conda environment name"
    exit 1
}

# Variables
SCRIPT_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
BASE_DIR="${SCRIPT_DIR}/../marllib"
NOW=$(date +"%Y-%m-%d_%H:%M:%S")
START_DOCKER=true
CONDA_ENV_NAME="marllib"

# Parse command-line arguments
while getopts ":d:e:h:" opt; do
    case $opt in
    d)
        START_DOCKER=$OPTARG
        ;;
    e)
        CONDA_ENV_NAME=$OPTARG
        ;;
    h)
        usage
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        usage
        ;;
    :)
        echo "Option -$OPTARG requires an argument." >&2
        usage
        ;;
    esac
done

# Start docker containers if required
if [ "$START_DOCKER" == "true" ]; then
    docker start pylot
    docker start redis
    echo "Docker containers started"
fi

# Activate conda environment
eval "$(conda shell.bash hook)"
conda activate $CONDA_ENV_NAME
echo "Conda environment $CONDA_ENV_NAME activated"

# Define a function to run a command in a new screen
# Only if a screen with the given name does not already exist
run_in_new_screen() {
    if screen -list | grep -q "\.$1\s"; then
        echo "A screen session named '$1' already exists."
    else
        screen -dmS "$1" bash -c "$2"
    fi
}

# Run the Python scripts in separate screens
run_in_new_screen "carla_manager" "python ${BASE_DIR}/envs/base_env/cmad/carla_manager.py"
run_in_new_screen "pylot_manager" "python ${BASE_DIR}/envs/base_env/cmad/pylot_manager.py"
run_in_new_screen "main" "python ${BASE_DIR}/main.py> ~/${NOW}_train.log 2>&1"
