#!/usr/bin/env python
# encoding: utf-8

"""
@Author: yangwenhao
@Contact: 874681044@qq.com
@Software: PyCharm
@File: split_trials.py
@Time: 2021/10/26 15:58
@Overview:
"""
import os
import argparse
from itertools import combinations, permutations

import numpy as np

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Split trials pairs!')
    parser.add_argument('--nj', type=int, default=16, metavar='E',
                        help='number of jobs to make feats (default: 10)')
    parser.add_argument('--out-dir', default='data/cnceleb/dev/subtrials', type=str)
    parser.add_argument('--trials', default='data/cnceleb/dev/trials_30w', type=str)
    # parser.add_argument('--domains', type=str)

    args = parser.parse_args()

    subsets = {}
    with open(args.trials, 'r') as f:
        for l in f.readlines():
            utt_a, utt_b, truth = l.split()
            dom_a = utt_a.split('-')[1]
            dom_b = utt_b.split('-')[1]
            subset = [dom_a, dom_b]
            subset.sort()

            subset = '_'.join(subset)
            if subset in subsets:
                subsets[subset].append(l)
            else:
                subsets[subset] = [l]

    if not os.path.exists(args.out_dir):
        os.makedirs(args.out_dir)

    for subset in subsets:
        with open(os.path.join(args.out_dir, "trials_" + subset), 'w') as f:
            for l in subsets[subset]:
                f.write(l)

    print('There are %d trials list.' % len(list(subsets.keys())))
