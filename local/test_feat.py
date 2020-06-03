#!/usr/bin/env python
# encoding: utf-8

"""
@Author: yangwenhao
@Contact: 874681044@qq.com
@Software: PyCharm
@File: test_feat.py
@Time: 2020/6/3 11:41 PM
@Overview:
"""
import argparse
import os
import kaldi_io
from tqdm import tqdm

parser = argparse.ArgumentParser(description='Make trials for vox1')
# Data options
parser.add_argument('--data-path', type=str,
                    default='data/aishell2/spect/dev',
                    help='path to dataset')

args = parser.parse_args()

feat_scp = args.data_path + '/feats.scp'
spk2utt = args.data_path + '/spk2utt'
utt2spk = args.data_path + '/utt2spk'

if not os.path.exists(feat_scp):
    raise FileExistsError(feat_scp)

error_num = 0
correct_num = 0
with open(feat_scp, 'r') as f:
    pbar = tqdm(enumerate(f.readlines()))
    for idx, line in pbar:
        uid, feat_offset = line.split()
        try:
            kaldi_io.read_mat(feat_offset)
            correct_num += 1
        except:
            error_num+=1
            print(feat_offset)

print('==>There are {} utterances in {} Dataset and {} errors.'.format(correct_num, args.data_path, error_num))

