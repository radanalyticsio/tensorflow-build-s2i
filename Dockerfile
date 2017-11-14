# base image for tensorflow
FROM centos:latest

MAINTAINER Subin Modeel <smodeel@redhat.com>

USER root

## taken/adapted from jupyter dockerfiles
# Not essential, but wise to set the lang
# Note: Users with other languages should set this in their derivative image
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV PYTHONIOENCODING UTF-8
ENV NB_USER=nbuser
ENV NB_UID=1011
ENV NB_PYTHON_VER=2.7
ENV TINI_VERSION=v0.16.1 

## Bazel
ENV PYTHON_LIB_PATH=/usr/lib64/python2.7/site-packages
ENV LD_LIBRARY_PATH="/usr/local/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}";
ENV BAZELRC /root/.bazelrc
ENV BAZEL_VERSION 0.5.4
ENV CURL_VERSION 7.54.1

## tensorflow ./configure options for Bazel
ENV CC_OPT_FLAGS -march=native
ENV TF_NEED_JEMALLOC 1
ENV TF_NEED_GCP 0
ENV TF_NEED_VERBS 0
ENV TF_NEED_HDFS 0
ENV TF_ENABLE_XLA 0
ENV TF_NEED_OPENCL 0
ENV TF_NEED_CUDA 0
ENV TF_NEED_MPI 0
ENV TF_NEED_GDR 0
ENV TF_NEED_S3 0
ENV TENSORBOARD_LOG_DIR /workspace
ENV PATH /usr/local/bin:$PATH
ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-1.8.0*

# Tensorflow compilation files
ENV TENSORFLOW_BUILD_FILES /root/.cache/bazel/_bazel_root/*/execroot/serving/bazel-out/host/ \
                /root/.cache/bazel/_bazel_root/install/ \
            /root/.cache/bazel/_bazel_root/*/execroot/serving/bazel-out/local-opt/bin/external/org_tensorflow/tensorflow/core/ \
            /root/.cache/bazel/_bazel_root/*/execroot/serving/bazel-out/local-opt/bin/external/org_tensorflow/tensorflow/c/ \
            /root/.cache/bazel/_bazel_root/*/execroot/serving/bazel-out/local-opt/bin/external/org_tensorflow/tensorflow/cc/ \
            /root/.cache/bazel/_bazel_root/*/execroot/serving/bazel-out/local-opt/bin/external/org_tensorflow/tensorflow/stream_executor/ \
            /root/.cache/bazel/_bazel_root/*/execroot/serving/bazel-out/local-opt/bin/tensorflow_serving/batching \
            /root/.cache/bazel/_bazel_root/*/execroot/serving/bazel-out/local-opt/bin/tensorflow_serving/servables \
            /root/.cache/bazel/_bazel_root/*/execroot/serving/bazel-out/local-opt/bin/tensorflow_serving/core \
            /root/.cache/bazel/_bazel_root/*/execroot/serving/bazel-out/local-opt/bin/tensorflow_serving/apis \
            /root/.cache/bazel/_bazel_root/*/execroot/serving/bazel-out/local-opt/bin/tensorflow_serving/test_util \
            /root/.cache/bazel/_bazel_root/*/execroot/serving/bazel-out/local-opt/bin/tensorflow_serving/config \
            /root/.cache/bazel/_bazel_root/*/execroot/serving/bazel-out/local-opt/bin/tensorflow_serving/resources \
            /root/.cache/bazel/_bazel_root/*/execroot/serving/bazel-out/local-opt/bin/tensorflow_serving/sources \
            /root/.cache/bazel/_bazel_root/*/execroot/serving/bazel-out/local-opt/bin/tensorflow_serving/util \
            /usr/local/lib/bazel \
            /usr/local/bin/bazel \
            /root/.cache/pip/ \
            /serving/.git \
            /serving/tf_models/syntaxnet



LABEL io.k8s.description="Tensorflow Builder." \
      io.k8s.display-name="Tensorflow Builder Image" \
      io.openshift.expose-services="6006:http"

ADD entrypoint /entrypoint


# Python binary and source dependencies and Development tools
RUN echo 'PS1="\u@\h:\w\\$ \[$(tput sgr0)\]"' >> /root/.bashrc \
    && chmod +x /entrypoint \
    && yum install -y epel-release \
    && yum install -y tar git curl wget java-headless bzip2 gnupg2 sqlite3 python-pip \
    && chgrp -R root /opt \
    && chmod -R a+rwx /opt \
    && chmod a+rw /etc/passwd \
    && yum install -y gcc gcc-c++ glibc-devel openssl-devel \
    && yum install -y kernel-devel make automake autoconf swig zip unzip libtool binutils \
    && yum install -y freetype-devel libpng12-devel zlib-devel giflib-devel zeromq3-devel \
    && yum install -y which libxml2 libxml2-devel libxslt libxslt-devel gzip python-devel \
    && yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel patch gdb file pciutils cmake \
    && wget -q https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini -P /tmp \
    && wget -q https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc -P /tmp \
    && cd /tmp \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 0527A9B7 && gpg --verify /tmp/tini.asc \
    && mv /tmp/tini /usr/local/bin/tini \
    && chmod +x /usr/local/bin/tini \
    && echo "startup --batch" >>/root/.bazelrc \
    && echo "build --spawn_strategy=standalone --genrule_strategy=standalone" >>/root/.bazelrc


#https://github.com/tensorflow/tensorflow/blob/master/tensorflow/tools/ci_build/install/.bazelrc
# Running bazel inside a `docker build` command causes trouble, cf:
#   https://github.com/bazelbuild/bazel/issues/134
# The easiest solution is to set up a bazelrc file forcing --batch.
# Similarly, we need to workaround sandboxing issues:
#   https://github.com/bazelbuild/bazel/issues/418
#
#Size of serving repo is 700MB+ 
# instead of git clone --recurse-submodules https://github.com/tensorflow/serving to download
# A cloned repo is found under serving folder
#Size of bazel-$BAZEL_VERSION-installer-linux-x86_64.sh is 200MB+
# downloaded file is available under bazel folder



# No yum commands here
# removed python to fix numpy issue
RUN mkdir -p /tf \
    && pip install --upgrade pip \
    && pip install enum34 futures mock six pixiedust \
    && pip install 'protobuf>=3.0.0a3' \
    && pip install -i https://testpypi.python.org/simple --pre grpcio \
    && pip install grpcio_tools mock tensorflow-serving-api \
    && mkdir -p /tf/tools \
    && cd /tf/tools \
    && wget -q https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh \
    && ls -l /tf/tools \
    && chmod +x bazel-$BAZEL_VERSION-installer-linux-x86_64.sh \
    && ./bazel-$BAZEL_VERSION-installer-linux-x86_64.sh \
    && bazel \
    && cd /tf \
    && cd /tf/tools \
    && git clone https://github.com/tatsuhiro-t/nghttp2.git \
    && cd nghttp2 \
    && autoreconf -i \
    && automake \
    && autoconf \
    && ./configure \
    && make \
    && make install \
    && echo '/usr/local/lib' > /etc/ld.so.conf.d/custom-libs.conf \
    && ldconfig \
    && cd /tf/tools \
    && wget http://curl.haxx.se/download/curl-$CURL_VERSION.tar.bz2 \
    && tar -xvjf curl-$CURL_VERSION.tar.bz2 \
    && cd curl-$CURL_VERSION \
    && ./configure --with-nghttp2=/usr/local --with-ssl \
    && make \
    && make install \
    && ldconfig \
    && touch /usr/include/stropts.h \
    && rm -fr $TENSORFLOW_BUILD_FILES \
    && rm -rf /root/.npm \
    && rm -rf /root/.cache \
    && rm -rf /root/.config \
    && rm -rf /root/.local \
    && rm -rf /root/tmp \
    && rm -f /tf/tools/curl-$CURL_VERSION.tar.bz2 \
    && useradd -m -s /bin/bash -N -u $NB_UID $NB_USER \
    && usermod -g root $NB_USER \
    && mkdir -p /notebooks \
    && chown $NB_UID:root /notebooks \
    && chmod 1777 /notebooks \
    && chown -R $NB_UID:root /home/$NB_USER \
    && chmod g+rwX,o+rX -R /home/$NB_USER



# NO CLEANUP
# Donot add below commands
#    && yum erase -y gcc gcc-c++ glibc-devel \
#    && yum clean all -y \


# TensorBoard
EXPOSE 6006


ENV HOME /home/$NB_USER
USER $NB_UID
# Make the default PWD somewhere that the user can write. This is
# useful when connecting with 'oc run' and starting a 'spark-shell',
# which will likely try to create files and directories in PWD and
# error out if it cannot.
WORKDIR /notebooks

ENTRYPOINT ["/entrypoint"]

CMD ["/bin/bash"]
