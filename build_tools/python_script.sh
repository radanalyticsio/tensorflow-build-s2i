#!/bin/bash -e
# The Python conundrum
# ----------------------------
#rpm -ql python27-python-devel  | grep Python.h
#/opt/rh/python27/root/usr/include/python2.7/Python.h
#rpm -ql python-devel  | grep Python.h
#/usr/include/python2.7/Python.h
#rpm -ql rh-python35-scldevel  | grep Python.h 
# /opt/rh/rh-python35/root/usr/include/python3.5m/Python.h
#rpm -ql rh-python36-scldevel  | grep Python.h 
# /opt/rh/rh-python36/root/usr/include/python3.6m/Python.h
#/opt/rh/python27/root/usr/lib64/
# scl python
#https://www.softwarecollections.org/en/scls/rhscl/python27/
#https://linuxize.com/post/how-to-install-python-3-on-centos-7/
#
#python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())"
#/opt/rh/rh-python36/root/usr/lib/python3.6/site-packages
#
#export PYTHON_LIB_PATH=/opt/rh/python27/root/usr/lib/python2.7/site-packages && 


# only for 2.7 
#/usr/include/python2.7/
#/usr/lib64/python2.7
#Requirement already up-to-date: pip in /usr/lib/python2.7/site-packages (10.0.1)
#/usr/lib/python2.7/site-packages
#/usr/lib64/python2.7/site-packages

# only for 3.6
# /opt/rh/rh-python36/root/usr/lib/python3.6/site-packages/

#PYTHON_VERSION_OUTPUT=`python --version 2>&1` \n\
#export PYTHON_LIB_PATH="$(echo /usr/lib/python${PYTHON_VERSION_OUTPUT:7:3}/site-packages)" \n\
#export PYTHON_INCLUDE_PATH="$(echo /usr/include/python${PYTHON_VERSION_OUTPUT:7:3}*)" \n\

#by defaults needs it at /usr/local/include/Python.h
echo "==============================="
echo "The Python conundrum..."
OSVER=$(. /etc/os-release;echo $ID)
echo "OSVER = "$OSVER
if [ "$PYTHON_VERSION" = "2.7" ] ; then 
	if [[ "$OSVER" = "rhel" ]] || [[ "$OSVER" = "centos" ]] ; then
		echo "$OSVER-$PYTHON_VERSION"  &&
		export LD_LIBRARY_PATH=/usr/include/python2.7/:/usr/lib64:/usr/lib64/python2.7:/opt/rh/python27/root/usr/include:/opt/rh/python27/root/usr/lib64/:/opt/rh/python27/root/usr/include/python2.7/:/usr/local/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}} &&
		#export LIBRARY_PATH=/opt/rh/python27/root/usr/include/python2.7/:$LIBRARY_PATH &&
		echo "PYTHON_H="`rpm -ql python27-python-devel | grep Python.h` &&
		echo "PYTHON_H="`rpm -ql python-devel | grep Python.h` &&
		echo "PYTHON_INCLUDE_PATH ="$PYTHON_INCLUDE_PATH ;
		#export PATH=/opt/rh/python27/root/usr/bin${PATH:+:${PATH}}
		#export PYTHONPATH=/usr/lib/python2.7/site-packages:/usr/lib64/python2.7/site-packages:$PYTHONPATH
		export LD_LIBRARY_PATH=/usr/include/python2.7/:/usr/lib:/usr/lib/python2.7:/usr/lib64:/usr/lib64/python2.7:/opt/rh/python27/root/usr/include:/opt/rh/python27/root/usr/lib64/:/opt/rh/python27/root/usr/include/python2.7/:/usr/local/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}} &&
		export LD_LIBRARY_PATH=/opt/rh/python27/root/usr/lib64/:/opt/rh/python27/root/usr/include:/opt/rh/python27/root/usr/include/python2.7/:/usr/local/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}} &&
		export CPATH=/opt/rh/python27/root/usr/include:/opt/rh/python27/root/usr/include/python2.7:$CPATH &&
		export LIBRARY_PATH=/opt/rh/python27/root/usr/include:/opt/rh/python27/root/usr/include/python2.7:$LIBRARY_PATH &&
		export PYTHON_INCLUDE_PATH=/opt/rh/python27/root/usr/include/python2.7 &&
		#export PKG_CONFIG_PATH=/opt/rh/python27/root/usr/lib64/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}} &&
		#export XDG_DATA_DIRS="/opt/rh/python27/root/usr/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}" &&
		echo "LD_LIBRARY_PATH ="$LD_LIBRARY_PATH  &&
		echo "PYTHONPATH ="$PYTHONPATH;
	fi
	if [[ "$OSVER" = "fedora" ]] ; then
		echo "$OSVER-$PYTHON_VERSION"  &&
		export LD_LIBRARY_PATH="/usr/lib64:/usr/local/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}" && 
		export PYTHON_INCLUDE_PATH=/usr/include/python2.7/ &&
		echo "PYTHON_H="`rpm -ql python-devel | grep Python.h`;
	fi
fi
if [ "$PYTHON_VERSION" = "3.5" ] ; then 
	if [[ "$OSVER" = "rhel" ]] || [[ "$OSVER" = "centos" ]] ; then
		echo "$OSVER-$PYTHON_VERSION"  &&
		export PATH=/opt/rh/rh-python35/root/usr/bin${PATH:+:${PATH}}
		export LD_LIBRARY_PATH=/opt/rh/rh-python35/root/usr/lib64/:/opt/rh/rh-python35/root/usr/include:/opt/rh/rh-python35/root/usr/include/python3.5m/:/usr/local/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}} &&
		export CPATH=/opt/rh/rh-python35/root/usr/include:/opt/rh/rh-python35/root/usr/include/python3.5m:$CPATH &&
		export LIBRARY_PATH=/opt/rh/rh-python35/root/usr/include:/opt/rh/rh-python35/root/usr/include/python3.5m:$LIBRARY_PATH &&
		export PYTHON_INCLUDE_PATH=/opt/rh/rh-python35/root/usr/include/python3.5m &&
		export PYTHON_LIB_PATH=/opt/rh/rh-python35/root/usr/lib/python3.5/site-packages &&
		export PKG_CONFIG_PATH=/opt/rh/rh-python35/root/usr/lib64/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}} &&
		export XDG_DATA_DIRS="/opt/rh/rh-python35/root/usr/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}" &&
		echo "PYTHON_H="`rpm -ql rh-python35-python-devel | grep Python.h` ;
	fi
	if [[ "$OSVER" = "fedora" ]] ; then
		echo "$OSVER-$PYTHON_VERSION"  &&
		export LD_LIBRARY_PATH="/usr/lib64:/usr/local/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}" && 
		export PYTHON_INCLUDE_PATH=/usr/include/python3.5m/ && 
		echo "PYTHON_H="`rpm -ql python3-devel | grep Python.h`;
	fi
fi 
if [ "$PYTHON_VERSION" = "3.6" ] ; then 
	if [[ "$OSVER" = "rhel" ]] || [[ "$OSVER" = "centos" ]] ; then
		echo "$OSVER-$PYTHON_VERSION"  &&
		export PATH=/opt/rh/rh-python36/root/usr/bin${PATH:+:${PATH}}
		export LD_LIBRARY_PATH=/opt/rh/rh-python36/root/usr/lib64/:/opt/rh/rh-python36/root/usr/include:/opt/rh/rh-python36/root/usr/include/python3.6m/:/usr/local/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}} &&
		export CPATH=/opt/rh/rh-python36/root/usr/include:/opt/rh/rh-python36/root/usr/include/python3.6m:$CPATH &&
		export LIBRARY_PATH=/opt/rh/rh-python36/root/usr/include:/opt/rh/rh-python36/root/usr/include/python3.6m:$LIBRARY_PATH &&
		export PYTHON_INCLUDE_PATH=/opt/rh/rh-python36/root/usr/include/python3.6m &&
		export PYTHON_LIB_PATH=/opt/rh/rh-python36/root/usr/lib/python3.6/site-packages &&
		export PKG_CONFIG_PATH=/opt/rh/rh-python36/root/usr/lib64/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}} &&
		export XDG_DATA_DIRS="/opt/rh/rh-python36/root/usr/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}" &&
		echo "PYTHON_H="`rpm -ql rh-python36-python-devel | grep Python.h`;
	fi
	if [[ "$OSVER" = "fedora" ]] ; then
		echo "$OSVER-$PYTHON_VERSION"  &&
		export LD_LIBRARY_PATH="/usr/lib64:/usr/local/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}" && 
		export PYTHON_INCLUDE_PATH=/usr/include/python3.6m/ && 
		echo "PYTHON_H="`rpm -ql python3-devel | grep Python.h`;
	fi
fi

echo "LD_LIBRARY_PATH ="$LD_LIBRARY_PATH;
echo "CPATH ="$CPATH;
echo "PATH ="$PATH; 
echo "LIBRARY_PATH ="$LIBRARY_PATH;
echo "PYTHON_INCLUDE_PATH ="$PYTHON_INCLUDE_PATH;
echo "PYTHON_LIB_PATH ="$PYTHON_LIB_PATH;
echo "==============================="