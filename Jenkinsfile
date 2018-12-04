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
  def uuid = UUID.randomUUID().toString()

  openshift.withCluster() {
    openshift.withProject(project) {
      withCredentials([[$class: 'StringBinding', credentialsId: 'GIT_TOKEN', variable: 'GIT_TOKEN']]) {
        try {
          stage("Build Image") {
            def tensorflowImageTemplate = openshift.selector("template", "tensorflow-build-image").object()
            builderImageStream = openshift.process(
              tensorflowImageTemplate,
              "-p", "APPLICATION_NAME=tf-${operatingSystem}-${pythonVersionNoDecimal}-image-${uuid}",
              "-p", "S2I_IMAGE=${s2iImage}",
              "-p", "DOCKER_FILE_PATH=Dockerfile.${operatingSystem}",
              "-p", "NB_PYTHON_VER=${pythonVersion}",
              "-p", "BAZEL_VERSION=${bazelVersion}"
            )
            def createdImageStream = openshift.create(builderImageStream)
            createdImageStream.describe()
            def builds = createdImageStream.narrow('bc')
            builds.logs('-f')

            def completedSuccessfully = false
            timeout(1) {
              builds.related('builds').untilEach {
                if (it.object().status.phase == "Complete") {
                  completedSuccessfully = true
                }
                return completedSuccessfully
              }
            }

            if (!completedSuccessfully) {
              error("An error has occured in tf-${operatingSystem}-${pythonVersionNoDecimal}-image-${uuid}")
            }
          }

          stage("Build Job") {
            def tensorflowJobTemplate = openshift.selector("template", "tensorflow-build-job").object()
            buildJob = openshift.process(
              tensorflowJobTemplate,
              "-p", "APPLICATION_NAME=tf-${operatingSystem}-${pythonVersionNoDecimal}-job-${uuid}",
              "-p", "BUILDER_IMAGESTREAM=tf-${operatingSystem}-${pythonVersionNoDecimal}-image-${uuid}",
              "-p", "NB_PYTHON_VER=${pythonVersion}",
              "-p", "CUSTOM_BUILD=${customBuild}",
              "-p", "BAZEL_VERSION=${bazelVersion}",
              "-p", "TF_GIT_BRANCH=${tfBranch}",
              "-p", "SESHETA_GITHUB_ACCESS_TOKEN=${env.GIT_TOKEN}"
            )
            def createdJob = openshift.create(buildJob)
            def pods = createdJob.related('pods')
            timeout(5) {
              pods.untilEach {
                return (it.object().status.phase == "Running")
              }
            }
            pods.logs("-f")

            def completedSuccessfully = false
            timeout(1) {
              pods.untilEach {
                if (it.object().status.phase == "Succeeded") {
                  completedSuccessfully = true
                }
                return completedSuccessfully
              }
            }

            if (!completedSuccessfully) {
              error("An error has occured in tf-${operatingSystem}-${pythonVersionNoDecimal}-job-${uuid}")
            }
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
