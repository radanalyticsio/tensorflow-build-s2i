export PORT = 8080
export TF_NEED_JEMALLOC = 1
export TF_NEED_GCP = 0
export TF_NEED_VERBS = 0
export TF_NEED_HDFS = 0
export TF_ENABLE_XLA = 0
export TF_NEED_OPENCL = 0
export TF_NEED_CUDA = 1
export TF_NEED_MPI = 0
export TF_NEED_GDR = 0
export TF_NEED_S3 = 0
export CUSTOM_BUILD = 
export BUILD_OPTS = --config=cuda --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0"
export TF_CUDA_VERSION = 9.0
export TF_CUDA_COMPUTE_CAPABILITIES = 3.0,3.5,5.2,6.0,6.1
export TF_CUDNN_VERSION = 7



command_exists () { type "$1" &> /dev/null ; }
if command_exists bazel ; then 
	echo "exists"; 
else echo "doesnt exists" && cd /tf/tools/ && ./bazel-$BAZEL_VERSION-installer-linux-x86_64.sh --user && export PATH=$HOME/bin:$PATH && bazel ; 
fi

# git clone tf
cd /workspace
git clone --recurse-submodules https://github.com/tensorflow/serving
cd /workspace/serving 
cd /workspace/serving/tensorflow 
./configure
cd /workspace/serving/tensorflow

#BUILD
export PATH=$HOME/bin:$PATH


echo "TF_NEED_CUDA = "$TF_NEED_CUDA
if [ $TF_NEED_CUDA = "1" ]; then 
	echo "######################\n"
	echo "      set cuda       \n"
	echo "######################\n"
	sed -i.bak 's/@org_tensorflow\/\/third_party\/gpus\/crosstool/@local_config_cuda\/\/crosstool:toolchain/g' tools/bazel.rc
fi 


#BUILD GPU binary
#bazel build -c opt --config=cuda --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0" --verbose_failures //tensorflow/tools/pip_package:build_pip_package
#BUILD CPU binary
#bazel build -c opt --verbose_failures //tensorflow/tools/pip_package:build_pip_package


echo "######################\n"
echo "      CUSTOM  BUILD     \n"
echo "######################\n"
eval "$CUSTOM_BUILD" | tee /workspace/ERROR.txt ; test ${PIPESTATUS[0]} -eq 0
if (( $? )); then
    echo "######################\n"
	echo "      BUILD  ERROR     \n"
	echo "######################\n"
	mkdir -p /workspace/bins
	mv /workspace/ERROR.txt /workspace/bins/
else
	echo "######################\n"
	echo "      BUILD  SUCCESS     \n"
	echo "######################\n"
	ls -l  bazel-bin/tensorflow/tools/pip_package/build_pip_package && bazel-bin/tensorflow/tools/pip_package/build_pip_package /workspace/bins ;
fi
