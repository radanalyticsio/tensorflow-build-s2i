# Tensorflow BUILD S2I

## About

This S2I respository has [template](https://docs.openshift.org/latest/dev_guide/templates.html) files used for building tensorflow wheel files for:
* `Centos7`
* `Fedora27`
* `Fedora28`
* `RHEL7.5`

NOTE: for `RHEL7.5` you need a system with RHEL Subscription enabled.

##### For CPU
Building Tensorflow from source on Linux can give better performance.
This is because 
> ...the default TensorFlow wheel files target the broadest range of hardware to make TensorFlow accessible to everyone.
> If you are using CPUs for training or inference, it is recommended to compile TensorFlow with all of the optimizations available for the CPU in use.
> To install the most optimized version of TensorFlow, build and install from source. 
> If there is a need to build TensorFlow on a platform that has different hardware than the target, 
> then cross-compile with the highest optimizations for the target platform....

For example:

```--copt=-mavx --copt=-mavx2 --copt=-mavx512f --copt=-mfma --copt=-mfpmath=both --copt=-msse4.2 ```

using above options in `CUSTOM_BUILD` will build the package with optimizations for `FMA, AVX and SSE`.

Build and install from source is fraught with errors due to `gcc` compatability issues, mismatch between CUDA platform and cuDNN libraries with TensorFlow, `python` versions, `bazel` versions , unsupported optimizations on the target CPU etc.

The templates and Dockerfiles available here provide a flexible approach to create wheel files for different combinations of OS, `python` version, `bazel` version etc by specifying them as PARAMS(`--param=`) in the templates. 
The wheel files created from these templates are available at [AICoE/wheels](https://github.com/AICoE/wheels/releases).

##### For GPU: TODO
GPU is not yet supported.


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
* `TF_CUDA_COMPUTE_CAPABILITIES`: = 3.0,3.5,5.2,6.0,6.1,7.0
* `TF_CUDNN_VERSION`: = 7
* `TF_NEED_OPENCL_SYCL`:= 0
* `TF_NEED_TENSORRT`:= 0
* `TF_CUDA_CLANG`:= 0
* `GCC_HOST_COMPILER_PATH`:= /usr/bin/gcc
* `CUDA_TOOLKIT_PATH`:= /usr/lib/cuda
* `CUDNN_INSTALL_PATH`:= /usr/lib/cuda
* `TF_NEED_KAFKA`:=0
* `TF_NEED_OPENCL_SYCL`:=0
* `TF_DOWNLOAD_CLANG`:=0
* `TF_SET_ANDROID_WORKSPACE`:=0

Here is the default build command used to build tensorflow. 
* `CUSTOM_BUILD`:=`bazel build --copt=-mavx --copt=-mavx2 --copt=-mfma --copt=-mfpmath=both --copt=-msse4.2  --cxxopt='-D_GLIBCXX_USE_CXX11_ABI=0' --cxxopt='-D_GLIBCXX_USE_CXX11_ABI=0' --local_resources 2048,2.0,1.0 --verbose_failures //tensorflow/tools/pip_package:build_pip_package`

Following should be left blank for a build job.
* `TEST_LOOP`:=
* `BUILD_OPTS`:=



## Usage

### To create a wheel file

*set some environment values for convenience*
```
# valid values are 2.7,3.6,3.5
PYTH_VERSION=3.6

# git token and repo
export GIT_TOKEN=
export GIT_RELEASE_REPO=
```

#### 1. Create the templates
```
oc create -f tensorflow-build-image.json
oc create -f tensorflow-build-job.json
oc create -f tensorflow-build-dc.json
```

#### 2. Create Tensorflow build image
```
oc new-app --template=tensorflow-build-image  
--param=APPLICATION_NAME=tf-rhel75-build-image-${PYTH_VERSION//.} \
--param=S2I_IMAGE=registry.access.redhat.com/rhscl/s2i-core-rhel7  \
--param=DOCKER_FILE_PATH=Dockerfile.rhel75  \
--param=NB_PYTHON_VER=$PYTH_VERSION \
--param=VERSION=2 \
--param=BAZEL_VERSION=0.11.0
```
The above command creates a tensorflow builder image `APPLICATION_NAME:VERSION` for specific OS.

The values for `S2I_IMAGE` are :
- Fedora26- `registry.fedoraproject.org/f26/s2i-core`
- Fedora27- `registry.fedoraproject.org/f27/s2i-core`
- Fedora27- `registry.fedoraproject.org/f28/s2i-core`
- RHEL7.5- `registry.access.redhat.com/rhscl/s2i-core-rhel7`
- Centos7- `openshift/base-centos7`

The values for `DOCKER_FILE_PATH` are :
- Fedora26- `Dockerfile.fedora26`
- Fedora27- `Dockerfile.fedora27`
- Fedora28- `Dockerfile.fedora28`
- RHEL7.5- `Dockerfile.rhel75`
- Centos7- `Dockerfile.centos7`


*OR*

Import the template `tensorflow-build-image.json` into your namespace from Openshift UI.
And then deploy from UI with appropriate values.

#### 3. Create Tensorflow wheel for CPU using the build image

```
oc new-app --template=tensorflow-build-job  
--param=APPLICATION_NAME=tf-rhel75-build-job-${PYTH_VERSION//.} \
--param=BUILDER_IMAGESTREAM=tf-rhel75-build-image-${PYTH_VERSION//.}:2  \
--param=NB_PYTHON_VER=$PYTH_VERSION  \
--param=BAZEL_VERSION=0.11.0 \
--param=GIT_RELEASE_REPO=$GIT_RELEASE_REPO  \
--param=GIT_TOKEN=$GIT_TOKEN
```
NOTE: `BUILDER_IMAGESTREAM = APPLICATION_NAME:VERSION` from step 2.

*OR*

Import the template `tensorflow-build-job.json` into your namespace from Openshift UI.
And then deploy from UI with appropriate values.
Tensorflow wheel files will be pushed to `$GIT_RELEASE_REPO` using the token `$GIT_TOKEN`.
(NOTE: This will ONLY work if the oauth token has scope of "repo".
You can generate Personal API access token at https://github.com/settings/tokens. Minimal token scope is "repo".)

### To create a DEV environment for debugging build issues :
```
oc new-app --template=tensorflow-build-dc  
--param=APPLICATION_NAME=tf-rhel75-build-dc-${PYTH_VERSION//.} \
--param=BUILDER_IMAGESTREAM=tf-rhel75-build-image-${PYTH_VERSION//.}:2  \
--param=NB_PYTHON_VER=$PYTH_VERSION  \
--param=GIT_TOKEN=$GIT_TOKEN \
--param=TEST_LOOP=y

```
NOTE: `BUILDER_IMAGESTREAM = APPLICATION_NAME:VERSION` from step 2. 

See [Usage example](https://github.com/thoth-station/tensorflow-build-s2i/blob/master/Developing.md)
