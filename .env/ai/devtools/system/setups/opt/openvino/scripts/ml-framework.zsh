#############################
# ML-Framework Configurations
#############################

# OpenVINO exports
export OPENVINO_DEVICE=GPU
export OPENVINO_ROOT=/usr/local/runtime
export LD_LIBRARY_PATH=$OPENVINO_ROOT/lib/intel64:$LD_LIBRARY_PATH
export CPATH=$OPENVINO_ROOT/include:$CPATH
export LIBRARY_PATH=$OPENVINO_ROOT/lib/intel64:$LIBRARY_PATH
export PATH=$OPENVINO_ROOT/bin:$PATH
