def operatingSystem = env.OPERATING_SYSTEM ?: "fedora28"
def s2iImage = env.S2I_IMAGE ?: "registry.fedoraproject.org/f28/s2i-core"
def pythonVersion = env.PYTHON_VERSION ?: "3.6"
def pythonVersionNoDecimal = pythonVersion.replaceAll("[^a-zA-Z0-9]+","")
def bazelVersion = env.BAZEL_VERSION ?: "0.15.0"
def tfBranch = env.TF_GIT_BRANCH ?: "r1.10"
def customBuild = env.CUSTOM_BUILD ?: "bazel build -c opt --cxxopt='-D_GLIBCXX_USE_CXX11_ABI=0' --local_resources 2048,2.0,1.0 --verbose_failures //tensorflow/tools/pip_package:build_pip_package"

// Name of project in OpenShift
def project = "tensorflow"

node {
  def builderImageStream = ''
  def buildJob = ''
  def uuid = UUID.randomUUID().toString()

  openshift.withCluster() {
    openshift.withProject(project) {
      withCredentials([[$class: 'StringBinding', credentialsId: 'GIT_TOKEN', variable: 'GIT_TOKEN']]) {
        try {
          // This stage builds the base image to be used later for testing Tensorflow
          stage("Build Image") {
            def tensorflowImageTemplate = openshift.selector("template", "tensorflow-build-image").object()
            builderImageStream = openshift.process(
              tensorflowImageTemplate,
              "-p", "APPLICATION_NAME=tf-${operatingSystem}-${pythonVersionNoDecimal}-image-${uuid}",
              "-p", "BAZEL_VERSION=${bazelVersion}",
              "-p", "DOCKER_FILE_PATH=Dockerfile.${operatingSystem}",
              "-p", "NB_PYTHON_VER=${pythonVersion}",
              "-p", "S2I_IMAGE=${s2iImage}"
            )
            def createdImageStream = openshift.create(builderImageStream)
            createdImageStream.describe()
            def imageStreamBuildConfig = createdImageStream.narrow('bc')
            imageStreamBuildConfig.logs('-f')

            // Check OpenShift to see if the build has completed
            def imageBuildCompleted = false
            timeout(1) {
              imageStreamBuildConfig.related('builds').untilEach {
                if (it.object().status.phase == "Complete") {
                  imageBuildCompleted = true
                }
                return imageBuildCompleted
              }
            }

            // If build is not completed after 1 minuete, we are assuming there was an error
            // And throwing to the catch block
            if (!imageBuildCompleted) {
              error("An error has occured in tf-${operatingSystem}-${pythonVersionNoDecimal}-image-${uuid}")
            }
          }

          // This stage uses the image built previously and runs the s2i/bin/run script to verify Tensorflow
          stage("Build Job") {
            def tensorflowJobTemplate = openshift.selector("template", "tensorflow-build-job").object()
            buildJob = openshift.process(
              tensorflowJobTemplate,
              "-p", "APPLICATION_NAME=tf-${operatingSystem}-${pythonVersionNoDecimal}-job-${uuid}",
              "-p", "BAZEL_VERSION=${bazelVersion}",
              "-p", "BUILDER_IMAGESTREAM=tf-${operatingSystem}-${pythonVersionNoDecimal}-image-${uuid}",
              "-p", "CUSTOM_BUILD=${customBuild}",
              "-p", "NB_PYTHON_VER=${pythonVersion}",
              "-p", "GIT_TOKEN=${env.GIT_TOKEN}",
              "-p", "TF_GIT_BRANCH=${tfBranch}"
            )
            def createdJob = openshift.create(buildJob)
            def jobPods = createdJob.related('pods')

            // Check OpenShift to make sure the pod is running before trying to tail the logs
            timeout(5) {
              jobPods.untilEach {
                return (it.object().status.phase == "Running")
              }
            }
            jobPods.logs("-f")

            // Check OpenShift to see if the build has Succeeded
            def jobSucceeded = false
            timeout(1) {
              jobPods.untilEach {
                if (it.object().status.phase == "Succeeded") {
                  jobSucceeded = true
                }
                return jobSucceeded
              }
            }

            // If build is not completed after 1 minuete, we are assuming there was an error
            // And throwing to the catch block
            if (!jobSucceeded) {
              error("An error has occured in tf-${operatingSystem}-${pythonVersionNoDecimal}-job-${uuid}")
            }
          }
        } catch (e) {
          echo e.toString()
          throw e
        } finally {
          // Delete all resources related to the current build
          stage("Cleanup") {
            openshift.delete(builderImageStream)
            openshift.delete(buildJob)
          }
        }
      }
    }
  }
}
