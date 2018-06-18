# Tensorflow BUILD S2I

## About

This S2I image is meant for building tensorflow binaries

Building Tensorflow from source on Linux can give better performance:
For example:
`--copt=-mavx --copt=-mavx2 --copt=-mfma --copt=-mfpmath=both --copt=-msse4.2 `
 will build the package with optimizations for FMA, AVX and SSE

## Bazel build options
* `TF_NEED_JEMALLOC`: = 1
* `TF_NEED_GCP`: = 0
* `TF_NEED_VERBS`: = 0
* `TF_NEED_HDFS`: = 0
* `TF_ENABLE_XLA`: = 0
* `TF_NEED_OPENCL`: = 0
* `TF_NEED_CUDA`: = 1
* `TF_NEED_MPI`: = 0
* `TF_NEED_GDR`: = 0
* `TF_NEED_S3`: = 0
* `TF_CUDA_VERSION`: = 9.0
* `TF_CUDA_COMPUTE_CAPABILITIES`: = 3.0,3.5,5.2,6.0,6.1
* `TF_CUDNN_VERSION`: = 7
* `TF_NEED_OPENCL_SYCL`:= 0
* `TF_CUDA_CLANG`:= 0
* `GCC_HOST_COMPILER_PATH`:= /usr/bin/gcc
* `CUDA_TOOLKIT_PATH`:= /usr/lib/cuda
* `CUDNN_INSTALL_PATH`:= /usr/lib/cuda
* `TF_NEED_KAFKA`:=0
* `TF_NEED_OPENCL_SYCL`:=0
* `TF_DOWNLOAD_CLANG`:=0
* `TF_SET_ANDROID_WORKSPACE`:=0

Here is an default build command used to build tensorflow. 
* `CUSTOM_BUILD`:=bazel build -c opt --cxxopt='-D_GLIBCXX_USE_CXX11_ABI=0' --local_resources 2048,2.0,1.0 --verbose_failures //tensorflow/tools/pip_package:build_pip_package

Following should be left blank.
* `TEST_LOOP`:=
* `BUILD_OPTS`:=



## Usage
```
oc create -f template.json
```
OR
Import the template into your namespace from Openshift UI.


To create with tf binary for CPU :
```
oc new-app --template tf-build"
```
OR
Create the Application from the template.
The tensorflow wheel file will be available by clicking on the route.It is located in the bin folder.


Note : GPU is not yet supported.
