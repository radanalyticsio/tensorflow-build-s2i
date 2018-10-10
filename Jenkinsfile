openshift.withCluster( 'mycluster' ) {
    echo "================================================"
    echo "============= Tensorflow Build ================="
    echo "================================================"
    echo "======== ${openshift.cluster()}'s default project: ${openshift.project()} ========"
    
    //
    //  Create all templates
    //
    def tensorflow_build_image = openshift.selector( "template", "tensorflow-build-image")
    def tensorflow_build_job = openshift.selector( "template", "tensorflow-build-job")
    def tensorflow_build_image_Exists = tensorflow_build_image.exists()
    def tensorflow_build_job_Exists = tensorflow_build_job.exists()
    
    def tensorflow_build_image_obj
    if (!tensorflow_build_image_Exists) {
        tensorflow_build_image_obj = openshift.create('https://raw.githubusercontent.com/thoth-station/tensorflow-build-s2i/master/tensorflow-build-image.json').object()
    } else {
        tensorflow_build_image_obj = templateSelector.object()
    }

    def tensorflow_build_job_obj
    if (!tensorflow_build_job_Exists) {
        tensorflow_build_image_obj = openshift.create('https://raw.githubusercontent.com/thoth-station/tensorflow-build-s2i/master/tensorflow-build-job.json').object()
    } else {
        tensorflow_build_job_obj = templateSelector.object()
    }

    //
    //  Create Centos7 Build Images
    //
    tensorflow_build_image_obj.labels["APPLICATION_NAME"] = "tf-rhel75-build-image-2.7"
    tensorflow_build_image_obj.labels["S2I_IMAGE"] = "registry.access.redhat.com/rhscl/s2i-core-rhel7"
    tensorflow_build_image_obj.labels["DOCKER_FILE_PATH"] = "Dockerfile.rhel75"
    tensorflow_build_image_obj.labels["NB_PYTHON_VER"] = "2.7"
    tensorflow_build_image_obj.labels["VERSION"] = "1"
    tensorflow_build_image_obj.labels["BAZEL_VERSION"] = "0.15.0"

    def created = openshift.create( openshift.process(tensorflow_build_image_obj))
    created.describe()
    def bc = created.narrow('bc')
    bc.logs('-f')

}