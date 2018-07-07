#!/bin/bash

#
GIT_TAG=$1
NOTES=$2
GIT_TOKEN=$3
WHEEL_FILE=$4
BRANCH=$(git rev-parse --abbrev-ref HEAD)
GITHUB_REPO=$(git config --get remote.origin.url | sed 's/.*:\/\/github.com\///;s/.git$//')


POST_DATA()
{
  cat <<EOF
{
  "tag_name": "$GIT_TAG",
  "target_commitish": "$BRANCH",
  "name": "$GIT_TAG",
  "body": "$NOTES",
  "draft": false,
  "prerelease": false
}
EOF
}

echo "Create release $GIT_TAG for repo: $GITHUB_REPO BRANCH: $BRANCH"
curl --data "$(POST_DATA)" "https://api.github.com/repos/$GITHUB_REPO/releases?access_token=$GIT_TOKEN"


LATEST_TAG_ID=$(curl -s -H "Authorization: token $GIT_TOKEN" \
	"https://api.github.com/repos/$GITHUB_REPO/releases/latest" \
 	| grep "\"id\":"  2>&1 | head -n 1 | sed -e 's/\"id\": //g' | tr -d " " |tr -d ",")


LATEST_REL_ID=$(curl -s -H "Authorization: token $GIT_TOKEN" \
	"https://api.github.com/repos/$GITHUB_REPO/releases/$LATEST_TAG_ID"  \
	| grep "\"id\":"  2>&1 | head -n 1 | sed -e 's/\"id\": //g' | tr -d " " |tr -d ",")
 

curl -H "Authorization: token $GIT_TOKEN" \
     -H "Accept: application/vnd.github.manifold-preview" \
     -H "Content-Type: application/zip" \
     --data-binary @"$WHEEL_FILE" \
     "https://uploads.github.com/repos/$GITHUB_REPO/releases/$LATEST_REL_ID/assets?name="$WHEEL_FILE""

