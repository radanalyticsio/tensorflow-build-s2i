### Usage example :

#### Setup 
```
PYTH_VERSION=3.6
export GIT_TOKEN=
export GIT_RELEASE_REPO=
export PAGURE_SSH_PRIVATE_KEY="$(cat dummy_pagure_ssh_key)"
```

#### Create the templates
```
oc create -f tensorflow-build-image.json
oc create -f tensorflow-build-job.json
oc create -f tensorflow-build-dc.json
```

#### Create the Build Image for fedora27
```
oc new-app --template=tensorflow-build-image  \
--param=APPLICATION_NAME=tf-fedora27-build-image-${PYTH_VERSION//.} \
--param=S2I_IMAGE=registry.fedoraproject.org/f27/s2i-core  \
--param=DOCKER_FILE_PATH=Dockerfile.fedora27  \
--param=NB_PYTHON_VER=$PYTH_VERSION \
--param=BAZEL_VERSION=0.11.0 \
--param=PAGURE_SSH_PRIVATE_KEY=$PAGURE_SSH_PRIVATE_KEY \
--param=VERSION=1 
```

#### Create Tensorflow wheel for CPU using the build image
```
oc new-app --template=tensorflow-build-job  \
--param=APPLICATION_NAME=tf-fedora27-builder-job-${PYTH_VERSION//.}  \
--param=BUILDER_IMAGESTREAM=tf-fedora27-build-image-${PYTH_VERSION//.}:1  \
--param=NB_PYTHON_VER=$PYTH_VERSION \
--param=CUSTOM_BUILD="bazel build -c opt --cxxopt='-D_GLIBCXX_USE_CXX11_ABI=0' --local_resources 2048,2.0,1.0 --verbose_failures //tensorflow/tools/pip_package:build_pip_package"  \
--param=GIT_TOKEN=$GIT_TOKEN \
--param=GIT_RELEASE_REPO=$GIT_RELEASE_REPO \
--param=PAGURE_SSH_PRIVATE_KEY=$PAGURE_SSH_PRIVATE_KEY \
--param=BAZEL_VERSION=0.11.0
```

#### Setup a DEV pod for fedora27
```
oc new-app --template=tensorflow-build-dc  \
--param=APPLICATION_NAME=tf-fedora27-builder-dc-${PYTH_VERSION//.} \
--param=BUILDER_IMAGESTREAM=tf-fedora27-build-image-${PYTH_VERSION//.}:1  \
--param=NB_PYTHON_VER=$PYTH_VERSION \
--param=CUSTOM_BUILD="bazel build -c opt --cxxopt='-D_GLIBCXX_USE_CXX11_ABI=0' --local_resources 2048,2.0,1.0 --verbose_failures //tensorflow/tools/pip_package:build_pip_package"  \
--param=GIT_TOKEN=$GIT_TOKEN \
--param=GIT_RELEASE_REPO=$GIT_RELEASE_REPO \
--param=BAZEL_VERSION=0.11.0 \
--param=PAGURE_SSH_PRIVATE_KEY=$PAGURE_SSH_PRIVATE_KEY \
--param=TEST_LOOP=y 
```

#### To delete all resources
```
oc delete  all -l appName=tf-fedora27-build-image-${PYTH_VERSION//.}
oc delete  all -l appName=tf-fedora27-build-dc-${PYTH_VERSION//.}
oc delete  all -l appName=tf-fedora27-build-job-${PYTH_VERSION//.}
```

