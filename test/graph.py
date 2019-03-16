#!/usr/bin/env python3

import sys
import numpy as np

try:
    # for Python2
    from Tkinter import *   ## notice capitalized T in Tkinter 
except ImportError:
    # for Python3
    from tkinter import * 

import matplotlib
matplotlib.use('Agg') 
import matplotlib.pyplot as plt


if len(sys.argv) != 2:
    print("usage: %s cvsbasename" % sys.argv[1])
    sys.exit(1)

basename = sys.argv[1]


def readdata(name):
    fname = '%s-%s.csv' % (basename, name)
    return np.genfromtxt(fname, delimiter=',', names=['size', 'time', 'flop'], skip_header=1)


def doplot(data, name, ax):
    ax.plot(data['google']['size'], data['google'][name], label='google')
    ax.plot(data['custom']['size'], data['custom'][name], label='custom')
    #ax.plot(data['gpu']['size'], data['gpu'][name], label='gpu')
    ax.set_xlabel('Matrix size')
    ax.legend(loc='best')


data = {i: readdata(i) for i in ['google', 'custom']}

fig, ax = plt.subplots(1, 2, figsize=(10, 5), dpi=300)
doplot(data, 'time', ax[0])
doplot(data, 'flop', ax[1])

ax[0].set_title('Time per matrix size')
ax[0].set_ylabel('Time (ms)')
ax[1].set_title('GFLOPS per matrix size')
ax[1].set_ylabel('GFLOPS')


plt.tight_layout()
#plt.show()
plt.savefig(basename + '.png')

