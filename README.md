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
###To create tf build image
```
oc new-app --template=tf-s2i-build  
--param=APPLICATION_NAME=tf-rhel75-builder-image-36 --param=VERSION=2 \
--param=S2I_IMAGE=registry.access.redhat.com/rhscl/s2i-core-rhel7  \
--param=DOCKER_FILE_PATH=Dockerfile.rhel75  \
--param=NB_PYTHON_VER=3.6 

```
The above command creates a builder image `APPLICATION_NAME:VERSION` for specific OS.

The values for `S2I_IMAGE` are :
- Fedora26- `registry.fedoraproject.org/f26/s2i-core`
- Fedora27- `registry.fedoraproject.org/f27/s2i-core`
- Fedora27- `registry.fedoraproject.org/f28/s2i-core`
- RHEL7.5- `registry.access.redhat.com/rhscl/s2i-core-rhel7`
- Centos7- `openshift/base-centos7`

The values for `DOCKER_FILE_PATH` are :
- Fedora26- `Dockerfile.fedora27,`
- Fedora27- `Dockerfile.fedora27,`
- Fedora27- `Dockerfile.fedora27,`
- RHEL7.5- `Dockerfile.rhel75`
- Centos7- `Dockerfile.centos7`


OR
Import the template into your namespace from Openshift UI.


###To create with tf wheel for CPU :
```
oc new-app --template=tensorflow-build-job  
--param=APPLICATION_NAME=tf-build-rh75-36 \
--param=BUILDER_IMAGESTREAM=docker-registry.default.svc:5000/dh-prod-analytics-factory/tf-rhel75-builder-image-36:2  \
--param=NB_PYTHON_VER=3.6  \
--param=GIT_DEST_REPO=https://github.com/AICoE/wheels.git  \
--param=GIT_TOKEN=

```
`NOTE BUILDER_IMAGESTREAM = APPLICATION_NAME:VERSION from first command` 

OR
Create the Application from the template.
The tensorflow wheel file will be available by clicking on the route.It is located in the bin folder.

###To create dev environment for creating tf wheel for CPU :
```
oc new-app --template=tensorflow-build-dc  
--param=APPLICATION_NAME=tf-build-rh75-36 \
--param=BUILDER_IMAGESTREAM=docker-registry.default.svc:5000/dh-prod-analytics-factory/tf-rhel75-builder-image-36:2  \
--param=NB_PYTHON_VER=3.6  \
--param=TEST_LOOP=y

```
`NOTE BUILDER_IMAGESTREAM = APPLICATION_NAME:VERSION from first command` 


Note : GPU is not yet supported.
