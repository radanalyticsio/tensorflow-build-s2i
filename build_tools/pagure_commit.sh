#!/bin/sh
TENSORFLOW_BUILD_DIR_NAME="$1"
GIT_COMMIT_MSG="$2"
FILES="$3"
WHFLL="$4"
BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo "=============================="
echo "TENSORFLOW_BUILD_DIR_NAME="$TENSORFLOW_BUILD_DIR_NAME
echo "NOTES="$GIT_COMMIT_MSG
echo "FILES="$FILES
echo "BRANCH="$BRANCH
echo "=============================="

## TODO remove the HARDCODING
cat $HOME/.ssh/known_hosts
if [ ! -n "$(grep "^pagure.io " $HOME/.ssh/known_hosts)" ]; then echo "pagure doesnt exists" && ssh-keyscan pagure.io >> /home/$NB_USER/.ssh/known_hosts; fi;

# Config: Script commit files on behalf of
git config --local user.name "Red Hat's AICoE"
git config --local user.email "goern+aicoe@redhat.com"


CHECK_LOCAL_AND_UPSTREAM(){
	UPSTREAM="origin/$BRANCH"
	LOCAL=$(git rev-parse HEAD)
	REMOTE=$(git rev-parse "$UPSTREAM")
	BASE=$(git merge-base HEAD "$UPSTREAM")
	echo "=============================="
	echo "UPSTREAM="$UPSTREAM
	echo "LOCAL="$LOCAL
	echo "REMOTE="$REMOTE
	echo "BASE="$BASE
	echo "=============================="

	if [ $LOCAL = $REMOTE ]; then
		echo "Up-to-date"
	elif [ $LOCAL = $BASE ]; then
		echo "Need to pull"
		git pull --rebase origin $BRANCH
	elif [ $REMOTE = $BASE ]; then
		echo "Need to push"
		git push origin master
	else
		echo "Diverged"

	fi
}

# NOTE: Update the index.html for each commit, better logic needed.
UPDATE_INDEX_HTML(){
	TAG="<h3 style=\"text-transform: capitalize;\">$OSVER - Python $NB_PYTHON_VER</h3>\n\t\t\t<ul>\n\t\t\t\t<li>\n\t\t\t\t\t<a href=\"${TENSORFLOW_BUILD_DIR_NAME}\/${WHFLL}\">${TENSORFLOW_BUILD_DIR_NAME}\/${WHFLL}</a>\n\t\t\t\t</li>\n\t\t\t</ul>"
	sed -i "/<section>/a $TAG" index.html
}

COPY_FILES(){
	for f in $FILES;do
		echo "FILE="$f
		if [ -f "$f" == "../build_info.yaml" ]; then
			cp $f $TENSORFLOW_BUILD_DIR_NAME/build_info-${TENSORFLOW_BUILD_DIR_NAME::-4}.yaml
		else
			cp $f $TENSORFLOW_BUILD_DIR_NAME/
		fi
	done
}

PUSH_DATA(){
	git status
	echo "=============================="
	CHECK_LOCAL_AND_UPSTREAM
	git add $TENSORFLOW_BUILD_DIR_NAME
	git status
	echo "=============================="
	git commit -m "$GIT_COMMIT_MSG"
	git status
	echo "=============================="
	until git push origin $BRANCH; do
		git pull --rebase origin $BRANCH
	done
}

if [ ! -d "$TENSORFLOW_BUILD_DIR_NAME" ]; then
	mkdir -p "$TENSORFLOW_BUILD_DIR_NAME"
	COPY_FILES
	UPDATE_INDEX_HTML
	git add index.html
	PUSH_DATA
elif [ -d "$TENSORFLOW_BUILD_DIR_NAME" && ! -f "$TENSORFLOW_BUILD_DIR_NAME/$WHFLL" ]
	echo 'OS version exists - new python version'
	COPY_FILES
	UPDATE_INDEX_HTML
	git add index.html
	PUSH_DATA
else 
	echo 'OS version exists - adding updated files'
	COPY_FILES
	PUSH_DATA
fi
