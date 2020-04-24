#!/usr/bin/env python
# encoding: utf-8

"""
@Author: yangwenhao
@Contact: 874681044@qq.com
@Software: PyCharm
@File: make_trials.py
@Time: 2020/3/29 4:14 PM
@Overview:
"""

import os
import random
import sys

import numpy as np

if sys.argv[1].isdigit():
    num_pair = int(sys.argv[1])
    data_roots = sys.argv[2:]
else:
    num_pair = 50000
    data_roots = sys.argv[1:]

print('Current path is ' + os.getcwd())
assert len(data_roots)>0
print("Dirs are: \n" + '; '.join(data_roots))


for data_dir in data_roots:
    spk2utt = data_dir+'/spk2utt'
    assert os.path.exists(spk2utt)
    utt2spk = data_dir + '/utt2spk'
    assert os.path.exists(utt2spk)

    spk2utt_dict = {}
    with open(spk2utt, 'r') as f:
        lines = f.readlines()
        for l in lines:
            lst = l.split()
            spkid = lst[0]
            spk2utt_dict[spkid]=lst[1:]

    utt2spk_dict = {}
    with open(utt2spk, 'r') as f:
        lines = f.readlines()
        for l in lines:
            lst = l.split()
            utt = lst[0]
            utt2spk_dict[utt] = lst[1]

    trials = data_dir+'/trials'
    with open(trials, 'w') as f:
        trials = []
        spks = list(spk2utt_dict.keys())
        num_repeat = int((len(spks) - 1) * 5)
        print('Num of repeats: %d ' % num_repeat)
        pairs = 0
        positive_pairs = 0

        for spk_idx in range(len(spks)):
            spk = spks[spk_idx]
            other_spks = spks.copy()
            other_spks.pop(spk_idx)

            num_utt= len(spk2utt_dict[spk])

            for i in range(num_utt):
                for j in range(num_utt):
                    if i<j:
                        this_line = ' '.join((spk2utt_dict[spk][i], spk2utt_dict[spk][j], 'target\n'))
                        # f.write(this_line)
                        trials.append((this_line, 1))
                        pairs+=1

            for i in range(num_repeat):
                this_uid = np.random.choice(spk2utt_dict[spk])
                other_spk = np.random.choice(other_spks)
                other_uid = np.random.choice(spk2utt_dict[other_spk])

                this_line = ' '.join((this_uid, other_uid, 'nontarget\n'))
                # f.write(this_line)
                trials.append((this_line, 0))
                pairs += 1

        random.shuffle(trials)

        for t, l in trials[:num_pair]:
            positive_pairs += l
            f.write(t)

        print('Generate %d pairs for set: %s, in which %d of them are positive pairs.' % (
            num_pair, data_dir, positive_pairs))
