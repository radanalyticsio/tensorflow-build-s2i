#!/bin/sh
GIT_COMMIT_MSG="$1"
FILES="$2"
WHFLL="$3"
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Naming the directory according to the naming convention
for varname in ${!TF_NEED_*}; do
    if [ "${!varname}" = "1" ]; then
        WORD=$(echo "${varname//TF_NEED_}" | tr '[:upper:]' '[:lower:]')
        if [ "$varname" = "TF_NEED_CUDA" ]; then
                WORD+=$TF_CUDA_VERSION
        fi
        FINAL_STR+=$WORD"+"
    fi
done
TENSORFLOW_BUILD_DIR_NAME=$OSVER/${TF_GIT_BRANCH//r}/${FINAL_STR::-1}

echo "=============================="
echo "TENSORFLOW_BUILD_DIR_NAME="$TENSORFLOW_BUILD_DIR_NAME
echo "NOTES="$GIT_COMMIT_MSG
echo "FILES="$FILES
echo "BRANCH="$BRANCH
echo "=============================="


# Config: Script commit files on behalf of
git config --global user.name "Harshad Reddy Nalla"
git config --global user.email "hnalla@redhat.com"


CHECK_LOCAL_AND_UPSTREAM(){
	UPSTREAM="origin/$BRANCH"
	LOCAL=$(git rev-parse @)
	REMOTE=$(git rev-parse "$UPSTREAM")
	BASE=$(git merge-base @ "$UPSTREAM")

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


PUSH_DATA(){
	for f in $FILES;do
		echo "FILE="$f
		cp $f $TENSORFLOW_BUILD_DIR_NAME/
	done
	CHECK_LOCAL_AND_UPSTREAM
	UPDATE_INDEX_HTML
	git add $TENSORFLOW_BUILD_DIR_NAME && git add index.html
	git commit -m "$GIT_COMMIT_MSG"
	git push origin $BRANCH || {
		git pull --rebase origin $BRANCH
		git push origin $BRANCH
	}
}

# NOTE: Logging will be intergated.
if [ ! -d "$TENSORFLOW_BUILD_DIR_NAME" ]; then
	mkdir -p "$TENSORFLOW_BUILD_DIR_NAME"
	PUSH_DATA
else
	echo 'OS version exists - adding updated files'
	PUSH_DATA
fi
