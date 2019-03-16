#!/usr/bin/env python3

# Copyright 2018 Jason Zaman <jason AT perfinion.com> 2018
# Licensed under Apache-2

import argparse
import os
import sys
import numpy as np
import tensorflow as tf
from timeit import time


#python matmul_bench.py --device=cpu
parser = argparse.ArgumentParser(description='MatMul Benchmark')
parser.add_argument('--dtype', type=str,
                    default='float32',
                    choices=['float16', 'float32', 'float64', 'int32'],
                    help='datatype float{16,32,64}, int32, default=float32')
parser.add_argument('--device', type=str,
                    default='cpu',
                    choices=['cpu', 'gpu'],
                    help='run on cpu or gpu')
parser.add_argument('--out', type=str,
                    default='times.csv',
                    help='output filename')
parser.add_argument('--reps', type=int,
                    default=5,
                    help='number of repetitions')
args = parser.parse_args()


os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
if args.device == 'cpu':
    os.environ['CUDA_VISIBLE_DEVICES'] = '-1'


def bench(n):
    dtype = getattr(tf, args.dtype)

    tf.reset_default_graph()
    with tf.device("/%s:0" % (args.device)):
        matrix1 = tf.Variable(tf.ones((n, n), dtype=dtype))
        matrix2 = tf.Variable(tf.ones((n, n), dtype=dtype))
        product = tf.matmul(matrix1, matrix2)

    times = []
    config = tf.ConfigProto()
    with tf.Session(config=config) as sess:
        sess.run(tf.global_variables_initializer())
        # warmup
        sess.run(product.op)

        for i in range(args.reps):
            start = time.time()
            sess.run(product.op)
            times.append(time.time() - start)

    times_ms = 1000 * np.array(times)  # in seconds, convert to ms
    elapsed_ms = np.median(times_ms)

    ops = n ** 3 + (n - 1) * n ** 2  # n^2*(n-1) additions, n^3 multiplications
    rate = ops / elapsed_ms / 10 ** 6  # in GFLOPS. (/ milli / 10**6) == (/ 10 ** 9)
    print('%d x %d matmul took:   \t%.4f ms,\t %.2f GFLOPS' % (n, n, elapsed_ms, rate,))
    return rate, elapsed_ms


def main():
    np.set_printoptions(suppress=True)
    with open(args.out, "a") as f:
        f.write("# Version: %s, path: %s\n" % (tf.__version__, tf.__path__))
        f.write("size,time,flop\n")

    for i in range(8, 15):  # [256 ... 16384]
        n = 2 ** i
        rate, elapsed_ms = bench(n)

        with open(args.out, "a") as f:
            f.write("%d,%.4f,%.10f\n" % (n, elapsed_ms, rate))

        sys.stdout.flush()


if __name__ == '__main__':
    main()
