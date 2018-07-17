from __future__ import print_function
import yaml
import sys
import tensorflow as tf

argumentList = sys.argv

with open(sys.argv[1], 'r') as f:
    doc = yaml.load(f)

#print(doc)
#print("Tensorflow tag", tf.VERSION,"at source_HEAD=",doc['source_HEAD'], \
#        ". Built on : ","OS=",doc['OS_VER'],"march=",doc['march'], \
#        "(kernel ",doc['kernel'],") with Python-",doc['Python_version'],"",doc['GLIBC_VER']," and ",doc['GCC_VER'], \
#        )

print("Tensorflow tag %s at source_HEAD %s \n" \
"Built on : \n" \
"OS=%s  \n" \
"march=%s \n" \
"kernel=%s \n" \
"Python= %s \n" \
"glibc= %s and gcc=%s " %(tf.VERSION, doc['source_HEAD'], 
	doc['OS_VER'], doc['march'], doc['kernel'], 
	doc['Python_version'],doc['GLIBC_VER'],doc['GCC_VER']))
