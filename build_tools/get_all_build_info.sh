#!/bin/bash

#https://github.community/t5/How-to-use-Git-and-GitHub/How-to-create-full-release-from-command-line-not-just-a-tag/td-p/6895
#https://developer.github.com/v3/repos/releases/
#https://stackoverflow.com/questions/5207269/releasing-a-build-artifact-on-github
#

GIT_TOKEN=$1
GITHUB_REPO=${2:-"AICoE/tensorflow-wheels"}
DIRECTORY="assets_folder"
ASSETS_FILE="build_info.yaml"

[[  -z "$GIT_TOKEN" ]] && echo "GIT_TOKEN value needed" && exit 1
[[  -z "$GITHUB_REPO" ]] && echo "GITHUB_REPO value needed" && exit 1

trap ctrl_c INT

ctrl_c() {
  echo ""
  echo "CTRL_C..."
  $(cleanup_dir)
  exit 1
}

cleanup_dir() {
  if [ -d "$DIRECTORY" ]; then
    # Control will enter here if $DIRECTORY doesn't exist.
    read -r -p "Are you sure? You will delete $DIRECTORY? [y/N] " response
    response=$(echo "$response" | tr '[:upper:]' '[:lower:]')  # tolower
    if [[ "$response" =~ ^(no|n)$ ]]
    then
      exit 1
    fi

    rm -r $DIRECTORY
    exit 0
  fi
}

get_all_releases() {
  # Get all releases from GitHub api
  curl --silent -H "Authorization: token $GIT_TOKEN" "https://api.github.com/repos/$GITHUB_REPO/releases" | 
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

get_specific_assets() {
  # Get all releases from GitHub api
  curl --silent -H "Authorization: token $GIT_TOKEN" "https://api.github.com/repos/$GITHUB_REPO/releases" | 
    grep '"browser_download_url":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/' | grep "$1"                                    # Pluck JSON value
}

get_all_release_tags() {
  # Get all the tags from repo
  # donot include refs/heads/master and refs/pull/*/head
  curl --silent -H "Authorization: token $GIT_TOKEN" "https://api.github.com/repos/$GITHUB_REPO/git/refs" | 
    grep '"ref":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/' | grep "refs/tags"                                   # Pluck JSON value
}

check_oauth_scope() {
  # check to see if X-OAuth-Scopes has repo
  curl --silent -i -H "Authorization: token $GIT_TOKEN" https://api.github.com/rate_limit | 
    grep "X-OAuth-Scopes:" | tr -d ":" | awk -v N=$2 '{print $2}'                                   # Pluck JSON value
}

echo "==========================================="
echo "GITHUB_REPO="$GITHUB_REPO
echo "RELEASES=$(get_all_releases)"
echo "OUATH_SCOPE=$(check_oauth_scope)"
OUATH_SCOPE=$(check_oauth_scope)
[[  -z "$OUATH_SCOPE" ]] && echo "OUATH_SCOPE value should be repo" && exit 1
[[ "$OUATH_SCOPE" != *"repo"* ]] && echo "## This command will ONLY work if the oauth token has scope of repo.
## You can generate Personal API access token at https://github.com/settings/tokens. Minimal token scope is repo
" && exit 1
#curl -I -H "Authorization: token $GIT_TOKEN" https://api.github.com/rate_limit
echo "==========================================="



## This command will ONLY work if the oauth token has scope of "repo".
## You can generate Personal API access token at https://github.com/settings/tokens. Minimal token scope is repo

## DONOT use below command
## curl -s -i -H --data "$(POST_DATA)" "https://api.github.com/repos/$GITHUB_REPO/releases?access_token=$GIT_TOKEN"


read -r -p "Are you sure? You will download all $ASSETS_FILE ? [y/N] " response
response=$(echo "$response" | tr '[:upper:]' '[:lower:]')  # tolower
if [[ "$response" =~ ^(no|n)$ ]]
then
  exit 0
fi


if [ ! -d "$DIRECTORY" ]; then
  # Control will enter here if $DIRECTORY doesn't exist.
  mkdir -p $DIRECTORY
  cd $DIRECTORY
  RELEASE_ASSETS=$(get_specific_assets $ASSETS_FILE)
  echo "RELEASE_ASSETS="$RELEASE_ASSETS
  for t in $RELEASE_ASSETS;
  do
    echo "downloading asset $t...."
    wget -q $t
  done
  grep -E 'march:|OS_VER:|GCC_VER:|architecture:|processor|CPU_FAMILY|CPU_MODEL' *
  cd ..
fi

#CLEANUP
echo "cleanup..."
$(cleanup_dir)




