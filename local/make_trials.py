#!/usr/bin/env python
# encoding: utf-8

"""
@Author: yangwenhao
@Contact: 874681044@qq.com
@Software: PyCharm
@File: make_trials.py
@Time: 2020/3/29 4:14 PM
@Overview:

make trials from data dir

# remove too short utterances
"""

import argparse
import os
import pdb
import random
import sys
from tqdm import tqdm
import numpy as np

random.seed(123456)
np.random.seed(123456)

parser = argparse.ArgumentParser(description='Make Trials')
parser.add_argument('--data-dir', type=str, required=True, 
                    help='path to dataset')

parser.add_argument('--num-pair', type=int, default=40000,
                    help='how many pairs in test trials')

parser.add_argument('--ignore-gender', action='store_true',
                    default=False,
                    help='ignore spks\' gender')

parser.add_argument('--gender', type=str, default='fm',
                    help='ignore spks\' gender')

parser.add_argument('--trials', type=str, default='trials', 
                    help='path to dataset')


args = parser.parse_args()

# if sys.argv[1].isdigit():
#     num_pair = int(sys.argv[1])
#     data_roots = sys.argv[2:]
# else:
#     num_pair = -1
#     data_roots = sys.argv[1:]

num_pair   = args.num_pair
data_roots = args.data_dir.split(',')

print('Current path: ' + os.getcwd())
assert len(data_roots)>0
print("Dirs are: " + '; '.join(data_roots))

MIN_FRAMES = 50

for data_dir in data_roots:
    spk2utt = data_dir + '/spk2utt'
    assert os.path.exists(spk2utt)

    utt2spk = data_dir + '/utt2spk'
    assert os.path.exists(utt2spk)

    if not args.ignore_gender:
        spk2gender = data_dir + '/spk2gender'
        assert os.path.exists(spk2gender)

        spk2gender_dict = {}
        num_males   = 0
        num_females = 0

        with open(spk2gender, 'r') as f:
            for l in f.readlines():
                sid, gender = l.split()
                spk2gender_dict[sid] = gender

                if 'f' in gender :
                    num_females += 1
                elif 'm' in gender :
                    num_males += 1
    else:
        spk2gender_dict = None

    utt2num_frames = data_dir + '/utt2num_frames'
    if not os.path.exists(utt2num_frames):
        print('utt2num_frames select is skipped, try to use utt2dur...')
        utt2num_frames = data_dir + '/utt2dur'
        MIN_FRAMES = MIN_FRAMES / 100

    valid_utts = set([])

    ignore_utts = 0
    if not os.path.exists(utt2num_frames):
        print('Utterance duration selection is skipped.')
    else:
        with open(utt2num_frames, 'r') as f:
            for l in f.readlines():
                uid, num_frames = l.split()
                if float(num_frames) > MIN_FRAMES:
                    valid_utts.add(uid)
                else:
                    ignore_utts += 1
        print('%d of utterances are ignored, and % d of utterances are valid.' % (ignore_utts, len(valid_utts)))

    spk2utt_dict = {}
    with open(spk2utt, 'r') as f:
        lines = f.readlines()
        for l in lines:
            lst = l.split()
            spkid = lst[0]

            if spk2gender_dict == None:
                spk2utt_dict[spkid] = lst[1:]

            elif spk2gender_dict[spkid] in args.gender:
                spk2utt_dict[spkid] = lst[1:]

    all_spks = set(spk2utt_dict.keys())
    print('Rest Num of Spks: {}'.format(len(all_spks)))

    utt2spk_dict = {}
    skipped_utt = 0
    valid_utt = 0
    with open(utt2spk, 'r') as f:
        lines = f.readlines()
        for l in lines:
            lst = l.split()
            utt = lst[0]
            if lst[1] in all_spks:
                utt2spk_dict[utt] = lst[1]
                valid_utt   += 1
            else:
                skipped_utt += 1
    
    if ignore_utts == 0:
        valid_utts = set(utt2spk_dict.keys())

    print('Gender skipped utterance: {}, valid utterance: {}'.format(skipped_utt, valid_utt))

    trials = data_dir+'/' + args.trials
    if os.path.exists(trials):
        os.system('cp %s %s'%(trials, trials+'.bk'))

    with open(trials, 'w') as f:
        trials = []
        utts = len(list(utt2spk_dict.keys()))
        spks = list(spk2utt_dict.keys())

        # num_repeat = int((len(spks) - 1) * 5)
        # if utts*num_repeat*len(spks)>30*num_pair:
        #     num_repeat = int(10*num_pair/len(spks))

        print('Num of repeats: %d ' % (num_pair/len(spks)))
        pairs = 0
        positive_pairs = set()
        negative_pairs = set()

        random.shuffle(spks)
        pbar = tqdm(range(len(spks)))
        for spk_idx in pbar:
            spk = spks[spk_idx]
            if not args.ignore_gender:
                spk_gender = spk2gender_dict[spk]

                other_spks = []
                for sid in spks:
                    if sid != spk and spk2gender_dict[sid] == spk_gender:
                        other_spks.append(sid)
                
            else:
                other_spks = spks.copy()
                other_spks.pop(spk_idx)

            # pdb.set_trace()
            num_utt= len(spk2utt_dict[spk])
            spk_posi = 0
            for i in range(num_utt):
                for j in range(i+1, num_utt):
                    # if spk_posi >= int(0.7 * num_pair / len(spks)):
                    #     break

                    if spk2utt_dict[spk][i] in valid_utts and spk2utt_dict[spk][j] in valid_utts:
                        this_line   = ' '.join((spk2utt_dict[spk][i], spk2utt_dict[spk][j], 'target\n'))
                        this_line_r = ' '.join((spk2utt_dict[spk][j], spk2utt_dict[spk][i], 'target\n'))
                        # f.write(this_line)
                        if this_line_r not in positive_pairs:
                            positive_pairs.add(this_line)
                            spk_posi += 1

            negt_uids = []
            for i in range(np.max([len(spk2utt_dict[m]) for m in other_spks])):
                for j in other_spks:
                    if i < len(spk2utt_dict[j]):
                        negt_uids.append(spk2utt_dict[j][i])
                    else:
                        break
                    
            for this_uid in spk2utt_dict[spk]:
                spk_negt = 0
                for oi, other_uid in enumerate(negt_uids):
                    if this_uid in valid_utts and other_uid in valid_utts:

                        this_line   = ' '.join((this_uid, other_uid, 'nontarget\n'))
                        this_line_r = ' '.join((other_uid, this_uid, 'nontarget\n'))
                        # f.write(this_line)
                        if this_line_r in negative_pairs:
                            continue
                            
                        if spk_negt <= (6 * num_pair / len(spks) / len(spk2utt_dict[spk])):
                            negative_pairs.add(this_line)
                            spk_negt += 1
                        else:
                            break
                # trials.append((this_line, 0))
                # pairs += 1

        positive_pairs = list(positive_pairs)
        negative_pairs = list(negative_pairs)
        # pdb.set_trace()

        random.shuffle(negative_pairs)
        random.shuffle(positive_pairs)

        if len(positive_pairs) > 0.5*num_pair:
            positive_pairs=positive_pairs[:int(0.5*num_pair)]

        num_positive = len(positive_pairs)
        for l in negative_pairs:
            positive_pairs.append(l)
            if len(positive_pairs)>=num_pair:
                break

        random.shuffle(positive_pairs)
        for l in positive_pairs:
            f.write(l)

        print('Generate %d pairs for set: %s, in which %d of them are positive pairs.' % (
            len(positive_pairs), data_dir, num_positive))
