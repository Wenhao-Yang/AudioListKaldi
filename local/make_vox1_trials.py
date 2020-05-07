#!/usr/bin/env python
# encoding: utf-8

"""
@Author: yangwenhao
@Contact: 874681044@qq.com
@Software: PyCharm
@File: make_vox1_trials.py
@Time: 2020/4/29 9:35 PM
@Overview:
"""
import argparse

parser = argparse.ArgumentParser(description='Make trials for vox1')
# Data options
parser.add_argument('--trials-path', type=str,
                    default='data/Vox1/list_test_hard.txt',
                    help='path to dataset')
parser.add_argument('--write-path', type=str,
                    default='data/Vox1/trials_h',
                    help='path to dataset')

args = parser.parse_args()

trials_path = args.trials_path
trials = []
num_positve= 0
with open(trials_path, 'r') as f:
    trials_pairs = f.readlines()
    # 1 id10003/bDxy7bnj_bc/00010.wav id10003/yzIXg93UOIM/00009.wav
    # 0 id10003/bDxy7bnj_bc/00010.wav id10131/tavhppbwchM/00001.wav
    # 1 id10003/tCq2LcKO6xY/00001.wav id10003/yzIXg93UOIM/00012.wav
    for t in trials_pairs:
        l_a_b = t.split()
        a = l_a_b[1].split('/')
        a[2] = a[2].rstrip('.wav')
        uid_a = '-'.join(a)

        b = l_a_b[2].split('/')
        b[2] = b[2].rstrip('.wav')
        uid_b = '-'.join(b)

        if l_a_b[0]=='1':
            l='target\n'
            num_positve+=1
        else:
            l='nontarget\n'
        this_line = ' '.join((uid_a, uid_b, l))

        trials.append(this_line)
print('There are %d pairs with %d positive ones.' % (len(trials), num_positve))
with open(args.write_path, 'w') as f:
    for l in trials:
        f.write(l)
print('Write to %s' % str(args.write_path))