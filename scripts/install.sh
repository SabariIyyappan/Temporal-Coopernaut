#!/usr/bin/env bash
# =============================================================================
# Coopernaut — Environment Setup Script
# Run this script from inside the activated conda environment:
#   conda create -n autocast python=3.7 -y
#   conda activate autocast
#   bash scripts/install.sh
#
# Prerequisites (system-level, install manually before running):
#   - CUDA 11.8 at /usr/local/cuda-11.8
#   - gcc-11 / g++-11  (sudo apt install gcc-11 g++-11)
#   - mosquitto        (sudo apt install mosquitto libopenblas-dev)
#   - CARLA 0.9.11 already extracted to ./carla_0.9.11/
# =============================================================================


# -----------------------------------------------------------------------------
# 1. PyTorch (CUDA 11.0 build — matches the cu110 wheels below)
#    NOTE: conda pytorch channel is commented out; pip wheel is used instead
#    because it correctly resolves cu110 variants.
# -----------------------------------------------------------------------------
pip install torch==1.7.1+cu110 torchvision==0.8.2+cu110 torchaudio==0.7.2 \
    -f https://download.pytorch.org/whl/torch_stable.html


# -----------------------------------------------------------------------------
# 2. Core Python dependencies
#    - paho-mqtt / mosquitto: V2V communication simulation
#    - py-trees==0.8.3: scenario behaviour trees (pinned — API changed in 0.9)
#    - networkx==2.2: route graph (pinned — newer versions break CARLA srunner)
#    - ray: parallel evaluation workers
#    - open3d==0.13.0: point cloud visualisation utilities
# -----------------------------------------------------------------------------
pip install paho-mqtt scipy pygame py-trees==0.8.3 networkx==2.2 xmlschema \
    numpy shapely imageio ray tqdm numba pandas scikit-image scikit-learn \
    opencv-python h5py matplotlib

# numba installed via conda for better LLVM/OpenMP compatibility
conda install numba -y

pip install open3d==0.13.0

# openblas-devel needed by MinkowskiEngine BLAS backend (installed below)
conda install openblas-devel -c anaconda -y


# -----------------------------------------------------------------------------
# 3. Logging / experiment tracking
# -----------------------------------------------------------------------------
pip install wandb tensorboard torchsummary


# -----------------------------------------------------------------------------
# 4. PyTorch Geometric (sparse graph ops used by the cooperative fusion module)
#    Versions pinned to match torch==1.7.1+cu110.
# -----------------------------------------------------------------------------
pip install torch-scatter==2.0.5 -f https://data.pyg.org/whl/torch-1.7.1+cu110.html
pip install torch-sparse==0.6.9  -f https://data.pyg.org/whl/torch-1.7.1+cu110.html
pip install torch-geometric==1.7.2


# -----------------------------------------------------------------------------
# 5. MinkowskiEngine — sparse convolution library for LiDAR point encoding
#    Cloned one level above the project root (../MinkowskiEngine) to keep it
#    separate from the Coopernaut repo.
#    CPU-only install is commented out; GPU build is used.
# -----------------------------------------------------------------------------
DIR=$(pwd)
cd ..
git clone https://github.com/NVIDIA/MinkowskiEngine.git
cd ${DIR}


# -----------------------------------------------------------------------------
# 6. Conda environment variables
#    These persist across sessions once set. Require `conda activate autocast`
#    to take effect — re-activate after running this script.
# -----------------------------------------------------------------------------
# NOTE: CARLA must already be extracted to ./carla_0.9.11/ before this step.
#       To download manually:
#         wget https://carla-releases.s3.eu-west-3.amazonaws.com/Linux/CARLA_0.9.11.tar.gz
#         mkdir carla_0.9.11 && tar -xzf CARLA_0.9.11.tar.gz -C carla_0.9.11
conda env config vars set CARLA_ROOT=${DIR}/carla_0.9.11
conda env config vars set SCENARIO_RUNNER_ROOT=${DIR}/AutoCastSim/srunner
conda env config vars set PYTHONPATH=${DIR}/carla_0.9.11/PythonAPI:${DIR}/carla_0.9.11/PythonAPI/carla/dist/carla-0.9.11-py3.7-linux-x86_64.egg:${DIR}/carla_0.9.11/PythonAPI/carla:${DIR}/AutoCastSim


# -----------------------------------------------------------------------------
# 7. CUDA / compiler environment for MinkowskiEngine build
#    - CUDA_HOME: points to local CUDA 11.8 install
#    - gcc-11 / g++-11: required — newer gcc versions break nvcc compatibility
#    - TORCH_CUDA_ARCH_LIST="7.5": targets sm_75 (Turing, e.g. RTX 2060/2080)
#      Change to "8.6" for Ampere (RTX 30xx) or "8.9" for Ada (RTX 40xx).
# -----------------------------------------------------------------------------
export CUDA_HOME=/usr/local/cuda-11.8
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

export BLAS_INCLUDE_DIRS="${CONDA_PREFIX}/include"
export BLAS="openblas"

export CC=/usr/bin/gcc-11
export CXX=/usr/bin/g++-11
export CUDAHOSTCXX=/usr/bin/g++-11
export TORCH_CUDA_ARCH_LIST="7.5"


# -----------------------------------------------------------------------------
# 8. Build and install MinkowskiEngine (GPU build with OpenBLAS)
# -----------------------------------------------------------------------------
cd ../MinkowskiEngine
rm -rf build
python setup.py clean --all
python setup.py install --blas=openblas --blas_include_dirs=${CONDA_PREFIX}/include
