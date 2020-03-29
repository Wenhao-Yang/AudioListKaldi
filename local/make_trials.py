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
import sys
import numpy as np

data_roots = sys.argv[1:]
assert len(data_roots)>0

num_repeat = 100

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
        spks = list(spk2utt_dict.keys())
        pairs = 0
        for spk_idx in range(len(spks)):
            spk = spks[spk_idx]
            other_spks = spks.copy()
            other_spks.pop(spk_idx)

            num_utt= len(spk2utt_dict[spk])

            for i in range(num_utt):
                for j in range(num_utt):
                    if i<j:
                        this_line = ' '.join((spk2utt_dict[spk][i], spk2utt_dict[spk][i], 'target\n'))
                        f.write(this_line)
                        pairs+=1

            for i in range(num_repeat):
                this_uid = np.random.choice(spk2utt_dict[spk])
                other_spk = np.random.choice(other_spks)
                other_uid = np.random.choice(spk2utt_dict[other_spk])

                this_line = ' '.join((this_uid, other_uid, 'nontarget\n'))
                f.write(this_line)
                pairs += 1

        print('Generate %d pairs for set: %s' % (pairs, data_dir))
