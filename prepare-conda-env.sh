#!/bin/bash

_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
TF_VERSION="1.15"


# ========== Prepare Conda Environment

function get_conda_path() {
        local conda_exe=$(which conda)
        if [[ -z ${conda_exe} ]]; then
                echo "Fail to detect conda! Have you installed Anaconda/Miniconda?" 1>&2
                exit 1
        fi

        echo "$(dirname ${conda_exe})/../etc/profile.d/conda.sh"
}

function get_cuda_version() {
        local nvidia_smi_exe=$(which nvidia-smi)
        if [[ -z ${nvidia_smi_exe} ]]; then
                echo "cpu"
        else
                local cuda_version_number="$(nvcc -V | grep "release" | sed -E "s/.*release ([^,]+),.*/\1/")"
                case $cuda_version_number in
                10.1*)
                        echo "cu101";;
                10.2*)
                        echo "cu102";;
                11.1*)
                        echo "cu111";;
                *)
                        echo "ERROR: Only cuda 10.1, 10.2, 11.1 are supported, but you have $cuda_version_number" 1>&2
                        echo "HINT: Use 'source switch-cuda.sh [version]' if you have multiple versions installed" 1>&2
                        exit 1
                esac
        fi
}

function prepare_conda_env() {
        ### Preparing the base environment "atlas"
        local env_name=${1:-atlas}; shift
        local conda_path=$1; shift
        local cuda_version=$1; shift

        set -e
        if [[ -z ${conda_path} ]]; then
                conda_path=$(get_conda_path)
        fi
        if [[ -z ${cuda_version} ]]; then
                cuda_version=$(get_cuda_version)
        fi
        echo ">>> Preparing conda environment \"${env_name}\", for cuda version: ${cuda_version}; conda at ${conda_path}"
        
        # Preparation
        source ${conda_path}
        conda env remove --name $env_name
        conda create --name $env_name python=3.6 pip -y
        conda activate $env_name

        # Tensorflow
        local mllib="";
        case $cuda_version in
        cpu)
                mllib="tensorflow==${TF_VERSION}";;
        cu*)
                mllib="tensorflow-gpu==${TF_VERSION}";;
        *)
                echo "ERROR: Only cuda 10.1, 10.2, 11.1 are supported, but you have $cuda_version" 1>&2
                echo "HINT: Use 'source switch-cuda.sh [version]' if you have multiple versions installed" 1>&2
                exit 1
        esac
        
        conda install -y ${mllib} -c conda-forge

        # Other libraries
        pip install -r requirements.txt
}


prepare_conda_env "$@"
