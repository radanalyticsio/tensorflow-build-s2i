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
# Print node info, including info related to the machine
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

if command_exists ldd; then
  GLIBC_VER=$(ldd --version | head -1)
fi

if command_exists hostname; then
  HOSTNAME=$(hostname)
  HOST_IP=$(hostname --ip-address)
fi


if file_exists /etc/redhat-release; then
  OS_VER=$(cat /etc/redhat-release)
fi

if command_exists gcc; then
  GCC_VER=$(gcc --version | head -1)
fi

if command_exists g++; then
  GPP_VER=$(g++ --version | head -1)
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


if command_exists gcc; then
  A=$(gcc -march=native -Q --help=target|grep march)
  ARCH=$(echo "${A##* }" | tr -s [:space:] | sed -e 's/^\s*//' -e '/^$/d')
  GCC_FLAGSS=$(gcc -### -E - -march=native 2>&1 | sed -r '/cc1/!d;s/(")|(^.* - )|( -mno-[^\ ]+)//g')
fi

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
TF_NODE_INFO="{
\"OS_VER\": \""${OS_VER}"\", 
\"GLIBC_VER\": \""${GLIBC_VER}"\", 
\"GCC_VER\": \""${GCC_VER}"\", 
\"OS\": \""${OS}"\", 
\"LOGICAL_CPUS\": \""${LOGICAL_CPUS}"\", 
\"CORES_PER_PCPU\": \""${CORES_PER_PCPU}"\", 
\"PHYSICAL_CPUS\": \""${PHYSICAL_CPUS}"\", 
\"kernel\": \""${KERNEL}"\", 
\"HOSTNAME\": \""${HOSTNAME}"\", 
\"HOST_IP\": \""${HOST_IP}"\", 
\"architecture\": \""${ARCH}"\", 
\"processor\": \""${PROCESSOR}"\", 
\"gpp_version\": \""${GPP_VER}"\", 
\"processor_count\": \""${PROCESSOR_COUNT}"\",
\"NVIDIA_driver_version\": \""${NVIDIA_DRIVER_VER}"\",
\"CUDA_device_count\": \""${CUDA_DEVICE_COUNT}"\",
\"CUDA_device_names\": \""${CUDA_DEVICE_NAMES}"\",
\"CUDA_toolkit_version\": \""${CUDA_TOOLKIT_VER}"\",
\"GCC_FLAGS\": \""${GCC_FLAGSS}"\",
\"CPUINFO_FLAGS\": \""${CPUINFO_FLAGS}"\",
\"CPUINFO_FLAGS_TENSORFLOW\": \""${CPUINFO_FLAGS_TENSORFLOW}"\",
\"CPU_FAMILY\": \""${CPU_FAMILY}"\",
\"CPU_MODEL\": \""${CPU_MODEL}"\",
\"march\": \""${ARCH}"\"
}"

#echo -e $TF_NODE_INFO
echo
rm -fr node_info_${HOST_IP}.yaml
rm -fr node_info_${HOST_IP}.json
if command_exists pip; then
      pip install pyyaml --user
      echo -e  $TF_NODE_INFO | python -c 'import yaml,json,sys;obj=json.load(sys.stdin);yy=yaml.safe_dump(obj, default_flow_style=False); print(yy)' >> node_info_${HOST_IP}.yaml
      echo "----------------------"
      cat node_info_${HOST_IP}.yaml
      echo "----------------------"
 fi
echo -e  $TF_NODE_INFO >> node_info_${HOST_IP}.json
cat node_info_${HOST_IP}.json






