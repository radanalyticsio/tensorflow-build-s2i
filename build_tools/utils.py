from __future__ import print_function
import yaml
import sys
import tensorflow as tf

argumentList = sys.argv

with open(sys.argv[1], 'r') as f:
    doc = yaml.load(f)

#print(doc)
print("Tensorflow tag", tf.VERSION,"at source_HEAD=",doc['source_HEAD'], \
        ". Built on : ","OS=",doc['OS_VER'],"march=",doc['march'], \
        "(kernel ",doc['kernel'],") with Python-",doc['Python_version'],"",doc['GLIBC_VER']," and ",doc['GCC_VER'], \
        )
