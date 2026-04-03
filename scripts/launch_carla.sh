#!/bin/bash

gpu=$1

for (( i=1; i<=$2; i++ ))
do
    port=$((i*$3))
    CUDA_VISIBLE_DEVICES=$gpu DISPLAY=$DISPLAY __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia $CARLA_ROOT/CarlaUE4.sh -world-port=$port -opengl -nosound -windowed&
done
wait
