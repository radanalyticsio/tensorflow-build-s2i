#!/bin/bash -e
MY_EXIT_1() {  exit 1; }
MY_RETURN_1() {  return 1; }
MY_RETURN_0() {  return 0; }
env_check () {
  exit_function=MY_RETURN_0;
  # If exit function is passed as $2 use it.
  if [[ ! -z "$2" ]];then exit_function=$2 ;fi 
  if [ $# -eq 0 ];then printf "No arguments supplied. \nUsage:\n env_check \"ENV_NAME\" [\"exit_function\"]\n" && $exit_function;fi
  param=$1;
  # The exclamation mark makes param to get the value of the variable with that name.
  if [[ -z "${!param}" ]];then echo "$1 is undefined" && $exit_function; else echo "$1 = "${!param} ;fi 
}

R_WHEEL_FILE=$(basename `ls  $1` )
#ls -l /workspace/bins | awk '{print $9}'
R_BUILD_INFO_DIR=$2
env_check R_BUILD_INFO_DIR MY_EXIT_1
R_BUILD_INFO=`ls -l $R_BUILD_INFO_DIR | awk '{print $9}'`
env_check R_WHEEL_FILE MY_EXIT_1
env_check R_BUILD_INFO MY_EXIT_1
[[  -z "$R_WHEEL_FILE" ]] && echo "R_WHEEL_FILE value needed" && exit 1 
[[  -z "$R_BUILD_INFO" ]] && echo "R_BUILD_INFO value needed" && exit 1 


echo "Changing METADATA..."
unzip -xvf $R_WHEEL_FILE | grep METADATA
unzip -q $R_WHEEL_FILE
ls -l *.dist-info/

printf "METADATA...\n"
grep -e "Platform" -e "Author-email"   -e "Author"  -e "Disclaimer" *.dist-info/METADATA 
sed -i "s/Platform.*/Platform: $(cat /etc/redhat-release)\\nKernel: $(uname -or |awk '{print $1;}')/" *.dist-info/METADATA
sed -i "s/Author-email:.*/Author-email: smodeel@redhat.com/" *.dist-info/METADATA
sed -i "s/Author:.*/Author: Red Hat Inc./" *.dist-info/METADATA		
DISCLAIMER="$(cat <<-EOF
Disclaimer: Following wheel files are created by Red Hat AICoE experimental builds and are without any support.
There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
EOF
)"
echo "$DISCLAIMER" >> *.dist-info/METADATA

for f in $R_BUILD_INFO; do
    R_BUILD_INFO_FILE="$R_BUILD_INFO_DIR/$f"
    env_check R_BUILD_INFO_FILE
    cp $R_BUILD_INFO_FILE *.dist-info/
done
zip -u $R_WHEEL_FILE *.dist-info/*
rm -fr *.dist-info/
rm -fr *.data/
ls -l


printf "New METADATA...\n"
unzip -qo $R_WHEEL_FILE
grep -e "Platform" -e "Author-email"   -e "Author"  -e "Disclaimer" *.dist-info/METADATA
ls -l 
ls -l *.dist-info/ | grep build_info.json
#whlff=$(basename `ls  *.whl` .whl )
#env_check whlff
#mv /workspace/bins/*.whl /workspace/bins/$whlff.whl.bkp
#cp *.whl /workspace/bins/

#TODO write a testcase here
pip install *.whl --user
