from __future__ import print_function
import yaml
import sys

argumentList = sys.argv

with open(sys.argv[1], 'r') as f:
    doc = yaml.load(f)

#print(doc)
print("Tensorflow tag", doc['tf.VERSION'], \
        "built on ", doc['OS_VER'],  \
        "(kernel ",doc['kernel'],") with Python-",doc['Python_version']," and ",doc['GCC_VER'])
