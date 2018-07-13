#!/bin/bash

#


GIT_TAG=$1
RELEASE_NAME=$2
NOTES=$3
GIT_TOKEN=$4
FILES=
BRANCH=$(git rev-parse --abbrev-ref HEAD)
GITHUB_REPO=$(git config --get remote.origin.url | sed 's/.*:\/\/github.com\///;s/.git$//')

POST_DATA()
{
  cat <<EOF
{
  "tag_name": "$GIT_TAG",
  "target_commitish": "$BRANCH",
  "name": "$RELEASE_NAME",
  "body": "$NOTES",
  "draft": false,
  "prerelease": false
}
EOF
}

echo "=============================="
echo "GIT_TAG="$GIT_TAG
echo "RELEASE_NAME="$RELEASE_NAME
echo "NOTES="$NOTES
echo "FILES="$FILES
echo "BRANCH="$BRANCH
echo "GITHUB_REPO="$GITHUB_REPO
echo "$(POST_DATA)"
echo "=============================="

echo "Create release $GIT_TAG for repo: $GITHUB_REPO BRANCH: $BRANCH"
curl -s -H "Authorization: token $GIT_TOKEN" --data "$(POST_DATA)" "https://api.github.com/repos/$GITHUB_REPO/releases"

#?access_token=$GIT_TOKEN


echo "get LATEST_TAG_ID..."
LATEST_TAG_ID=$(curl -s -H "Authorization: token $GIT_TOKEN" \
	"https://api.github.com/repos/$GITHUB_REPO/releases/latest" \
 	| grep "\"id\":"  2>&1 | head -n 1 | sed -e 's/\"id\": //g' | tr -d " " |tr -d ",")
 echo "get LATEST_TAG_ID="$LATEST_TAG_ID


echo "get LATEST_REL_ID..."
LATEST_REL_ID=$(curl -s -H "Authorization: token $GIT_TOKEN" \
	"https://api.github.com/repos/$GITHUB_REPO/releases/$LATEST_TAG_ID"  \
	| grep "\"id\":"  2>&1 | head -n 1 | sed -e 's/\"id\": //g' | tr -d " " |tr -d ",")

echo "get LATEST_REL_ID="$LATEST_REL_ID

for f in $FILES; do
    echo "FILE="$f
    filename=$(basename `ls  $f` )
    echo "FILE NAME="$filename
    curl -H "Authorization: token $GIT_TOKEN" \
     -H "Accept: application/vnd.github.manifold-preview" \
     -H "Content-Type: application/zip" \
     --data-binary @$f \
     "https://uploads.github.com/repos/$GITHUB_REPO/releases/$LATEST_REL_ID/assets?name="$filename
done





