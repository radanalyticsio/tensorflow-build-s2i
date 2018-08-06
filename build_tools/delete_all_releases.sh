#!/bin/bash

#https://github.community/t5/How-to-use-Git-and-GitHub/How-to-create-full-release-from-command-line-not-just-a-tag/td-p/6895
#https://developer.github.com/v3/repos/releases/
#https://stackoverflow.com/questions/5207269/releasing-a-build-artifact-on-github
#

GIT_TOKEN=$1
GITHUB_REPO=${2:-"AICoE/tensorflow-wheels"}

[[  -z "$GIT_TOKEN" ]] && echo "GIT_TOKEN value needed" && exit 1
[[  -z "$GITHUB_REPO" ]] && echo "GITHUB_REPO value needed" && exit 1


get_all_releases() {
  # Get all releases from GitHub api
  curl --silent -H "Authorization: token $GIT_TOKEN" "https://api.github.com/repos/$GITHUB_REPO/releases" | 
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
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
echo "RELEASE_TAGS=$(get_all_release_tags)"
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


read -r -p "Are you sure? You will delete RELEASES and RELEASES_TAGS? [y/N] " response
response=$(echo "$response" | tr '[:upper:]' '[:lower:]')  # tolower
if [[ "$response" =~ ^(no|n)$ ]]
then
  exit 0
fi


LATEST_TAG_ID=$(curl -s -H "Authorization: token $GIT_TOKEN" \
	"https://api.github.com/repos/$GITHUB_REPO/releases/latest" \
 	| grep "\"id\":"  2>&1 | head -n 1 | sed -e 's/\"id\": //g' | tr -d " " |tr -d ",")

[[ "$LATEST_TAG_ID" != "" ]] && echo "latest release="$LATEST_TAG_ID
 

while [[ "$LATEST_TAG_ID" =~ ^[0-9]+$ ]]; 
do
  LATEST_TAG_ID=$(curl -s -H "Authorization: token $GIT_TOKEN" \
    "https://api.github.com/repos/$GITHUB_REPO/releases/latest" \
    | grep "\"id\":"  2>&1 | head -n 1 | sed -e 's/\"id\": //g' | tr -d " " |tr -d ",")
  echo "deleting release $LATEST_TAG_ID...."
  if ! [[ "$LATEST_TAG_ID" =~ ^[0-9]+$ ]]
  then
        break
  fi
  curl -X DELETE -s -H "Authorization: token $GIT_TOKEN" \
  "https://api.github.com/repos/$GITHUB_REPO/releases/$LATEST_TAG_ID" 
  sleep 5

done


echo "=========================="
echo "No more releases to delete."
echo "=========================="

for t in $(get_all_release_tags);
do
  curl -X DELETE -s -H "Authorization: token $GIT_TOKEN" \
  "https://api.github.com/repos/$GITHUB_REPO/git/$t" 
  echo "deleting ref $t...."
  sleep 5
done


echo "=========================="
echo "No more tags to delete."
echo "=========================="






