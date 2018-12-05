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
              "-p", "BAZEL_VERSION=${bazelVersion}",
              "-p", "DOCKER_FILE_PATH=Dockerfile.${operatingSystem}",
              "-p", "NB_PYTHON_VER=${pythonVersion}",
              "-p", "S2I_IMAGE=${s2iImage}"
            )
            def createdImageStream = openshift.create(builderImageStream)
            createdImageStream.describe()
            def imageStreamBuildConfig = createdImageStream.narrow('bc')
            imageStreamBuildConfig.logs('-f')

            def imageBuildCompleted = false
            timeout(1) {
              imageStreamBuildConfig.related('builds').untilEach {
                if (it.object().status.phase == "Complete") {
                  imageBuildCompleted = true
                }
                return imageBuildCompleted
              }
            }

            if (!imageBuildCompleted) {
              error("An error has occured in tf-${operatingSystem}-${pythonVersionNoDecimal}-image-${uuid}")
            }
          }

          stage("Build Job") {
            def tensorflowJobTemplate = openshift.selector("template", "tensorflow-build-job").object()
            buildJob = openshift.process(
              tensorflowJobTemplate,
              "-p", "APPLICATION_NAME=tf-${operatingSystem}-${pythonVersionNoDecimal}-job-${uuid}",
              "-p", "BAZEL_VERSION=${bazelVersion}",
              "-p", "BUILDER_IMAGESTREAM=tf-${operatingSystem}-${pythonVersionNoDecimal}-image-${uuid}",
              "-p", "CUSTOM_BUILD=${customBuild}",
              "-p", "NB_PYTHON_VER=${pythonVersion}",
              "-p", "SESHETA_GITHUB_ACCESS_TOKEN=${env.GIT_TOKEN}",
              "-p", "TF_GIT_BRANCH=${tfBranch}"
            )
            def createdJob = openshift.create(buildJob)
            def jobPods = createdJob.related('pods')
            timeout(5) {
              jobPods.untilEach {
                return (it.object().status.phase == "Running")
              }
            }
            jobPods.logs("-f")

            def jobSucceeded = false
            timeout(1) {
              jobPods.untilEach {
                if (it.object().status.phase == "Succeeded") {
                  jobSucceeded = true
                }
                return jobSucceeded
              }
            }

            if (!jobSucceeded) {
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
