#!/usr/bin/env python
# encoding: utf-8

"""
@Author: yangwenhao
@Contact: 874681044@qq.com
@Software: PyCharm
@File: prep_sitw_trials.py
@Time: 2021/4/21 16:21
@Overview:
"""
import argparse
import os

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Prepare trials in sitw!')
    parser.add_argument('--enroll-dir', type=str)
    parser.add_argument('--test-dir', type=str)
    parser.add_argument('--trials', type=str)
    parser.add_argument('--out-trials', type=str)
    args = parser.parse_args()

    assert os.path.exists(args.trials)
    assert os.path.exists(os.path.join(args.enroll_dir, 'spk2utt'))
    assert os.path.exists(os.path.join(args.enroll_dir, 'wav.scp'))

    spk2utt = {}
    spk2utt_f = open(os.path.join(args.enroll_dir, 'spk2utt'), 'r')
    for l in spk2utt_f.readlines():
        spk, uid = l.split()
        spk2utt[spk] = uid

    if not os.path.exists(os.path.dirname(args.out_trials)):
        os.makedirs(os.path.dirname(args.out_trials))
        print('mkdirs: ', str(os.path.dirname(args.out_trials)))

    trials_f = open(args.trials, 'r')
    out_trails_num = 0
    with open(args.out_trials, 'w') as out_f:
        for l in trials_f.readlines():
            try:
                sid_a, uid_b, tag = l.split()
                uid_a = spk2utt[sid_a]
            except Exception as e:
                print("error in trials: ", e)
                continue
            out_f.write(' '.join([uid_a, uid_b, tag, '\n']))
            out_trails_num += 1

    print('Write %d trails pairs to %s' %(out_trails_num, args.out_trials))

# this_wav=data/sitw/eval/wav.scp
# mv ${this_wav} ${this_wav}.bcp
# cat ${this_wav}.bcp | \
#   while read line; do
#     l=($line)
#     if [ ${#l[@]} = 2 ]; then
#       orig_path=${l[-1]}
#       new_path=${orig_path/"flac"/"wav"}
#
#       if [ -s ${new_path} ]; then
#         echo -e "${l[-2]} ${new_path}" >> ${this_wav}
#       fi
#     fi
#
#   done






