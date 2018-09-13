### Test Usage example :

#### Setup 
```
PYTH_VERSION=2.7
```

#### Create the templates.
```
oc create -f tensorflow-build-image.json
oc create -f test/tensorflow-test-job.json
```

#### Create the Build Image of rhel75 for testing.
```
oc new-app --template=tensorflow-build-image  \
--param=APPLICATION_NAME=tf-rhel75-build-image-${PYTH_VERSION//.} \
--param=S2I_IMAGE=registry.access.redhat.com/rhscl/s2i-core-rhel7  \
--param=DOCKER_FILE_PATH=Dockerfile.rhel75 \
--param=NB_PYTHON_VER=$PYTH_VERSION  \
--param=VERSION=1
```

#### Test precreated wheel file on an Image.
```
oc new-app --template=tensorflow-test-job  \
--param=APPLICATION_NAME=tf-rhel75-test-job-${PYTH_VERSION//.}  \
--param=BUILDER_IMAGESTREAM=tf-rhel75-build-image-${PYTH_VERSION//.}:1   \
--param=NEW_WHEEL_FILE=https://github.com/AICoE/wheels/releases/download/tf-r1.9-cpu-2018-07-24_160352/tensorflow-1.9.0-cp27-cp27mu-linux_x86_64.whl
```

The wheel files are available at [AICoE/wheels](https://github.com/AICoE/wheels/releases).


#### To delete all resources
```
oc delete  all -l appName=tf-rhel75-build-image-${PYTH_VERSION//.}
oc delete  all -l appName=tf-rhel75-test-job-${PYTH_VERSION//.}

```
Credits: the matrixmul code is used from https://blog.perfinion.com/2018/07/tensorflow-cpu-supports-instructions/
