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
import random
from itertools import combinations, permutations
import numpy as np

random.seed(123456)
np.random.seed(123456)

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Split trials pairs!')
    parser.add_argument('--nj', type=int, default=16, metavar='E',
                        help='number of jobs to make feats (default: 10)')
    parser.add_argument('--data-dir', default='data/cnceleb/dev', type=str)
    parser.add_argument('--out-dir', default='data/cnceleb/dev/subtrials', type=str)
    parser.add_argument('--max-pairs', default=300000, type=int)
    # parser.add_argument('--trials', default='data/cnceleb/dev/trials_640w', type=str)
    # parser.add_argument('--domains', type=str)

    args = parser.parse_args()

    utt2dom = {}
    dom2utt = {}
    with open(args.data_dir + '/utt2dom', 'r') as f:
        for l in f.readlines():
            uid, udom = l.split()
            utt2dom[uid] = udom

            if udom in dom2utt:
                dom2utt[udom].append(uid)
            else:
                dom2utt[udom] = [uid]

    utt2spk = {}
    spk2utt = {}
    with open(args.data_dir + '/utt2spk', 'r') as f:
        for l in f.readlines():
            uid, sid = l.split()
            utt2spk[uid] = sid

            if sid in spk2utt:
                spk2utt[sid].append(uid)
            else:
                spk2utt[sid] = [uid]

    if not os.path.exists(args.out_dir):
        os.makedirs(args.out_dir)

    num_trials = 0
    print('')
    domains = list(dom2utt.keys())
    domains.sort()

    for i in range(len(domains)):
        dom_enroll = domains[i]
        positive_percent = '{:<20s}'.format(dom_enroll + ':')
        positive_percent += i *  "      "

        for j in range(i, len(domains)):
            dom_eval = domains[j]
            # subset = dom_enroll[:4] + '_' + dom_eval[:4]
            subset = dom_enroll[:2] + dom_eval[:2]
            pairs = set()
            enroll_utts = dom2utt[dom_enroll].copy()
            eval_utts = dom2utt[dom_eval].copy()

            random.shuffle(enroll_utts)
            random.shuffle(eval_utts)
            positive = 0
            negative = 0
            for enroll_utt in enroll_utts:
                for eval_utt in enroll_utts:
                    if enroll_utt != eval_utt:
                        pair_str = enroll_utt + ' ' + eval_utt + ' '

                        if utt2spk[enroll_utt] == utt2spk[eval_utt]:
                            pair_str += 'target\n'
                            positive += 1
                        else:
                            if negative > (args.max_pairs*2):
                                continue
                            pair_str += 'nontarget\n'
                            negative += 1

                        pairs.add(pair_str)
                        if len(pairs) > args.max_pairs and positive > args.max_pairs * 0.2:
                            break
            positive_percent += ' {:>5.2f}'.format(100 * positive / len(pairs))
            with open(os.path.join(args.out_dir, "trials_" + subset), 'w') as f:
                for l in pairs:
                    f.write(l)

                num_trials += 1
        print(positive_percent)
    print('\nThere are %d trials list.' % num_trials)
