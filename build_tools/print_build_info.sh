#!/usr/bin/env bash
# Copyright 2016 The TensorFlow Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# =============================================================================

# Print build info, including info related to the machine, OS, build tools
# and TensorFlow source code. This can be used by build tools such as Jenkins.
# All info is printed on a single line, in JSON format, to workaround the
# limitation of Jenkins Description Setter Plugin that multi-line regex is
# not supported.
#
# Usage:
#   should be run within tensorflow workspace
#	should run only after tensorflow wheel file is created

# Information about the command
COMMAND=("$@")

# Information about machine and OS
OS=$(uname)
KERNEL=$(uname -r)

ARCH=$(uname -p)
PROCESSOR=$(grep "model name" /proc/cpuinfo | head -1 | awk '{print substr($0, index($0, $4))}')
PROCESSOR_COUNT=$(grep "model name" /proc/cpuinfo | wc -l)

MEM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2, $3}')
SWAP_TOTAL=$(grep SwapTotal /proc/meminfo | awk '{print $2, $3}')

command_exists () { type "$1" &> /dev/null ; }
file_exists () { test -f $1 ; }
folder_exists () { test -d $1 ; }

# Information about build tools
if command_exists bazel; then
  BAZEL_VER=$(bazel version | head -1)
fi

if command_exists ldd; then
  GLIBC_VER=$(ldd --version | head -1)
fi

if file_exists /etc/redhat-release; then
  OS_VER=$(cat /etc/redhat-release)
fi

if command_exists pip; then
  PIP_VER=$(pip -V | head -1)
fi

if command_exists protoc; then
  PROTOC_VER=$(protoc --version | head -1)
fi

if command_exists gcc; then
  GCC_VER=$(gcc --version | head -1)
fi

if command_exists javac; then
  JAVA_VER=$(javac -version 2>&1 | awk '{print $2}')
fi

if command_exists python; then
  PYTHON_VER=$(python -V 2>&1 | awk '{print $2}')
fi

if command_exists g++; then
  GPP_VER=$(g++ --version | head -1)
fi

if command_exists swig; then
  SWIG_VER=$(swig -version > /dev/null | grep -m 1 . | awk '{print $3}')
fi

# Information about TensorFlow source

if folder_exists .git ; then
	TF_FETCH_URL=$(git config --get remote.origin.url)
	TF_HEAD=$(git rev-parse HEAD)
fi

# NVIDIA & CUDA info
NVIDIA_DRIVER_VER=""
if [[ -f /proc/driver/nvidia/version ]]; then
  NVIDIA_DRIVER_VER=$(head -1 /proc/driver/nvidia/version | awk '{print $(NF-6)}')
fi

CUDA_DEVICE_COUNT="0"
CUDA_DEVICE_NAMES=""
if command_exists nvidia-debugdump; then
  CUDA_DEVICE_COUNT=$(nvidia-debugdump -l | grep "^Found [0-9]*.*device.*" | awk '{print $2}')
  CUDA_DEVICE_NAMES=$(nvidia-debugdump -l | grep "Device name:.*" | awk '{print substr($0, index($0,\
 $3)) ","}')
fi

CUDA_TOOLKIT_VER=""
if command_exists nvcc; then
  CUDA_TOOLKIT_VER=$(nvcc -V | grep release | awk '{print $(NF)}')
fi

cat <<EOF > /tmp/check_tf.py
from __future__ import print_function
import imp
import sys
try:
	imp.find_module('tensorflow')
	import tensorflow as tf;
	print("tf.VERSION = %s" % tf.VERSION)
	print("tf.GIT_VERSION = %s" % tf.GIT_VERSION)
	print("tf.COMPILER_VERSION = %s" % tf.GIT_VERSION)
except ImportError:
	print("tf.VERSION = ")
	print("tf.GIT_VERSION = ")
	print("tf.COMPILER_VERSION = ")
	
EOF
check_tf="$(python /tmp/check_tf.py >&1)"
check_tf="${check_tf// = /=}"

CHECK_TF=""
for word in $check_tf
do
	IFS='='        # space is set as delimiter
	read -ra ADDR <<< "$word"    # str is read into an array as tokens separated by IFS
	CHECK_TF+="\"${ADDR[0]}\": \"${ADDR[1]}\","
done



BUILD_ENVs+="\"GCC_HOST_COMPILER_PATH\": \"${GCC_HOST_COMPILER_PATH}\","
BUILD_ENVs+="\"CUDA_TOOLKIT_PATH\": \"${CUDA_TOOLKIT_PATH}\","
BUILD_ENVs+="\"CUDNN_INSTALL_PATH\": \"${CUDNN_INSTALL_PATH}\","
BUILD_ENVs+="\"JAVA_HOME\": \"${JAVA_HOME}\","
BUILD_ENVs+="\"PYTHON_LIB_PATH\": \"${PYTHON_LIB_PATH}\","
BUILD_ENVs+="\"LD_LIBRARY_PATH\": \"${LD_LIBRARY_PATH}\","
BUILD_ENVs+="\"PYTHON_BIN_PATH\": \"${PYTHON_BIN_PATH}\","
BUILD_ENVs+="\"PATH\": \"${PATH}\","
BUILD_ENVs+="\"PORT\": \"${PORT}\","
BUILD_ENVs+="\"BUILD_OPTS\": \"${BUILD_OPTS}\","
BUILD_ENVs+="\"NB_PYTHON_VER\": \"${NB_PYTHON_VER}\","
BUILD_ENVs+="\"HOST_ON_HTTP_SERVER\": \"${HOST_ON_HTTP_SERVER}\","
BUILD_ENVs+="\"TEST_WHEEL_FILE\": \"${TEST_WHEEL_FILE}\"," 
BUILD_ENVs+="\"GIT_RELEASE_REPO\": \"${GIT_RELEASE_REPO}\","
BUILD_ENVs+="\"CUSTOM_BUILD\": \"${CUSTOM_BUILD}\","


unset IFS
TF_ENVs=""
TF_ENVs=$(env -0  | while IFS='=' read -r -d '' n v; do
	if [[ $n == TF* ]]; then
    	echo -e "\"$n\": \"$v\","
	fi;
done)

A=$(gcc -march=native -Q --help=target|grep march)
ARCH=$(echo "${A##* }" | tr -s [:space:] | sed -e 's/^\s*//' -e '/^$/d')

GCC_FLAGSS=$(gcc -### -E - -march=native 2>&1 | sed -r '/cc1/!d;s/(")|(^.* - )|( -mno-[^\ ]+)//g')

CPUINFO_FLAGS=$(grep flags -m1 /proc/cpuinfo | cut -d ":" -f 2 | tr '[:upper:]' '[:lower:]')

#TODO get specific info
#https://github.com/tensorflow/tensorflow/blob/master/tensorflow/core/platform/cpu_feature_guard.cc#L59
CPU_PATTERN="[\&\/a-zA-Z0-9\-]*sse[\&\/a-zA-Z0-9\-\_]*|[\&\/a-zA-Z0-9\-]*fma[\&\/a-zA-Z0-9\-\_]*|[\&\/a-zA-Z0-9\-]*avx[\&\/a-zA-Z0-9\-\_]*"
CPUINFO_FLAGS_TENSORFLOW=$(grep flags -m1 /proc/cpuinfo | cut -d ":" -f 2 | tr '[:upper:]' '[:lower:]' | grep -oE $CPU_PATTERN | tr '\n' ' ')

CPU_FAMILY=$(lscpu |grep "CPU family" | awk '{ print $3 }')
CPU_MODEL=$(lscpu |grep "Model:" | awk '{ print $2 }')
#https://access.redhat.com/solutions/224883
LOGICAL_CPUS=$(grep processor /proc/cpuinfo | wc -l)
CORES_PER_PCPU=$(grep cpu.cores /proc/cpuinfo | sort -u | cut -d ":" -f 2 | tr '[:upper:]' '[:lower:]')
PHYSICAL_CPUS=$(grep physical.id /proc/cpuinfo | sort -u | wc -l)

# Print info
TF_BUILD_INFO="{
\"source_HEAD\": \""${TF_HEAD}"\", 
\"source_remote_origin\": \""${TF_FETCH_URL}"\", 
\"OS_VER\": \""${OS_VER}"\", 
\"GLIBC_VER\": \""${GLIBC_VER}"\", 
\"PIP_VER\": \""${PIP_VER}"\", 
\"PROTOC_VER\": \""${PROTOC_VER}"\",
\"LOGICAL_CPUS\": \""${LOGICAL_CPUS}"\", 
\"CORES_PER_PCPU\": \""${CORES_PER_PCPU}"\", 
\"PHYSICAL_CPUS\": \""${PHYSICAL_CPUS}"\", 
\"GCC_VER\": \""${GCC_VER}"\", 
\"OS\": \""${OS}"\", 
\"kernel\": \""${KERNEL}"\", 
\"architecture\": \""${ARCH}"\", 
\"processor\": \""${PROCESSOR}"\", 
\"Bazel_version\": \""${BAZEL_VER}"\", 
\"Java_version\": \""${JAVA_VER}"\", 
\"Python_version\": \""${PYTHON_VER}"\",
\"gpp_version\": \""${GPP_VER}"\", 
\"swig_version\": \""${SWIG_VER}"\", 
\"NVIDIA_driver_version\": \""${NVIDIA_DRIVER_VER}"\",
\"CUDA_device_count\": \""${CUDA_DEVICE_COUNT}"\",
\"CUDA_device_names\": \""${CUDA_DEVICE_NAMES}"\",
\"CUDA_toolkit_version\": \""${CUDA_TOOLKIT_VER}"\",
\"GCC_FLAGS\": \""${GCC_FLAGSS}"\",
\"CPUINFO_FLAGS\": \""${CPUINFO_FLAGS}"\",
\"CPUINFO_FLAGS_TENSORFLOW\": \""${CPUINFO_FLAGS_TENSORFLOW}"\",
\"CPU_FAMILY\": \""${CPU_FAMILY}"\",
\"CPU_MODEL\": \""${CPU_MODEL}"\",
"${BUILD_ENVs}"
"${TF_ENVs}"
\"march\": \""${ARCH}"\"
}"

echo -e $TF_BUILD_INFO
echo
#\"processor_count\": \""${PROCESSOR_COUNT}"\", 
#\"memory_total\": \""${MEM_TOTAL}"\", 
#\"swap_total\": \""${SWAP_TOTAL}"\", 
#pip install pyyaml  
rm -fr build_info.yaml
echo -e  $TF_BUILD_INFO | python -c 'import yaml,json,sys;obj=json.load(sys.stdin);yy=yaml.safe_dump(obj, default_flow_style=False)
print(yy)' >> build_info.yaml
