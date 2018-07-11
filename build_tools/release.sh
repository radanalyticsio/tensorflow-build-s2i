#!/bin/bash

#


GIT_TAG=$1
NOTES=$2
GIT_TOKEN=$3
FILES=$4
BRANCH=$(git rev-parse --abbrev-ref HEAD)
GITHUB_REPO=$(git config --get remote.origin.url | sed 's/.*:\/\/github.com\///;s/.git$//')


echo "GIT_TAG="$GIT_TAG
echo "NOTES="$NOTES
echo "FILES="$FILES
echo "BRANCH="$BRANCH
echo "GITHUB_REPO="$GITHUB_REPO

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

echo "$(POST_DATA)"

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





