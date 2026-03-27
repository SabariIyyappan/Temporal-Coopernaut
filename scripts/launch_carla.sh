#!/bin/bash

gpu=$1

for (( i=1; i<=$2; i++ ))
do
    port=$((i*$3))
    CUDA_VISIBLE_DEVICES=$gpu DISPLAY=$DISPLAY $CARLA_ROOT/CarlaUE4.sh -world-port=$port -opengl -nosound -windowed&
done
wait
