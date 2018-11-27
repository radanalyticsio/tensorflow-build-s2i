def operatingSystem = env.OPERATING_SYSTEM ?: "fedora28"
def s2iImage = env.S2I_IMAGE ?: "registry.fedoraproject.org/f28/s2i-core"
def pythonVersion = env.PYTHON_VERSION ?: "3.6"
def pythonVersionNoDecimal = pythonVersion.replaceAll("[^a-zA-Z0-9]+","")
def bazelVersion = env.BAZEL_VERSION ?: "0.15.0"
def tfBranch = env.TF_GIT_BRANCH ?: "r1.10"
def customBuild = env.CUSTOM_BUILD ?: "bazel build -c opt --cxxopt='-D_GLIBCXX_USE_CXX11_ABI=0' --local_resources 2048,2.0,1.0 --verbose_failures //tensorflow/tools/pip_package:build_pip_package"

def project = "tensorflow"

node {
  def builderImageStream = ''
  def buildJob = ''

  openshift.withCluster() {
    openshift.withProject(project) {
      withCredentials([[$class: 'StringBinding', credentialsId: 'GIT_TOKEN', variable: 'GIT_TOKEN']]) {
        try {
          stage("Build Image") {
            def tensorflowImageTemplate = openshift.selector("template", "tensorflow-build-image").object()
            def imageSelector = openshift.selector( "bc/tf-${operatingSystem}-build-image-${pythonVersionNoDecimal}")
            def imageExists = imageSelector.exists()
            builderImageStream = openshift.process(
              tensorflowImageTemplate,
              "-p", "APPLICATION_NAME=tf-${operatingSystem}-build-image-${pythonVersionNoDecimal}",
              "-p", "S2I_IMAGE=${s2iImage}",
              "-p", "DOCKER_FILE_PATH=Dockerfile.${operatingSystem}",
              "-p", "NB_PYTHON_VER=${pythonVersion}",
              "-p", "BAZEL_VERSION=${bazelVersion}"
            )
            def createdImageStream = openshift.create(builderImageStream)
            createdImageStream.describe()
            createdImageStream.narrow('bc').logs('-f')
          }

          stage("Build Job") {
            def tensorflowJobTemplate = openshift.selector("template", "tensorflow-build-job").object()
            buildJob = openshift.process(
              tensorflowJobTemplate,
              "-p", "APPLICATION_NAME=tf-${operatingSystem}-build-job-${pythonVersionNoDecimal}",
              "-p", "BUILDER_IMAGESTREAM=tf-${operatingSystem}-build-image-${pythonVersionNoDecimal}",
              "-p", "NB_PYTHON_VER=${pythonVersion}",
              "-p", "CUSTOM_BUILD=${customBuild}",
              "-p", "BAZEL_VERSION=${bazelVersion}",
              "-p", "TF_GIT_BRANCH=${tfBranch}",
              "-p", "SESHETA_GITHUB_ACCESS_TOKEN=${env.GIT_TOKEN}"
            )
            def createdJob = openshift.create(buildJob)
            def pods = createdJob.related('pods')
            pods.untilEach {
              if (it.object().status.phase == "Failed") {
                echo "Pod failed to start"
                throw it.object().status
              }

              return (it.object().status.phase == "Running")
            }
            pods.logs("-f")
          }
        } catch (e) {
          echo e.toString()
          throw e
        } finally {
          stage("Cleanup") {
            openshift.delete(builderImageStream)
            openshift.delete(buildJob)
          }
        }
      }
    }
  }
}
