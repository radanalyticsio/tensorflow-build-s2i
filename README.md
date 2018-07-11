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
To create tf build image
```
oc new-app --template=tf-s2i-build  --param=APPLICATION_NAME=tf-rhel75-builder-image-36 --param=S2I_IMAGE=registry.access.redhat.com/rhscl/s2i-core-rhel7   --param=DOCKER_FILE_PATH=Dockerfile.rhel75 --param=NB_PYTHON_VER=3.6 --param=VERSION=2

 oc new-app --template=tf-s2i-build  --param=APPLICATION_NAME=tf-fedora28-builder-image-36 --param=S2I_IMAGE=registry.fedoraproject.org/f28/s2i-core   --param=DOCKER_FILE_PATH=Dockerfile.fedora28 --param=NB_PYTHON_VER=3.6 --param=VERSION=1

oc new-app --template=tf-s2i-build  --param=APPLICATION_NAME=tf-fedora27-builder-image-36 --param=S2I_IMAGE=registry.fedoraproject.org/f27/s2i-core   --param=DOCKER_FILE_PATH=Dockerfile.fedora27 --param=NB_PYTHON_VER=3.6 --param=VERSION=1

```
OR
Import the template into your namespace from Openshift UI.


To create with tf wheel for CPU :
```
oc new-app --template=tensorflow-build-job  --param=APPLICATION_NAME=tf-build-rh75-361 --param=BUILDER_IMAGESTREAM=docker-registry.default.svc:5000/dh-prod-analytics-factory/tf-rhel75-builder-image-36:2  --param=NB_PYTHON_VER=3.6  --param=GIT_TOKEN=


oc new-app --template=tensorflow-build-job  --param=APPLICATION_NAME=tf-build-fc28-36 --param=BUILDER_IMAGESTREAM=docker-registry.default.svc:5000/dh-prod-analytics-factory/tf-fedora28-builder-image-36:1  --param=NB_PYTHON_VER=3.6  --param=GIT_TOKEN=


oc new-app --template=tensorflow-build-job  --param=APPLICATION_NAME=tf-build-fc27-36 --param=BUILDER_IMAGESTREAM=docker-registry.default.svc:5000/dh-prod-analytics-factory/tf-fedora27-builder-image-36:1  --param=NB_PYTHON_VER=3.6  --param=GIT_TOKEN=
```
OR
Create the Application from the template.
The tensorflow wheel file will be available by clicking on the route.It is located in the bin folder.


Note : GPU is not yet supported.
