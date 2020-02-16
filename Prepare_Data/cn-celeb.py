#!/usr/bin/env python
# encoding: utf-8

"""
@Author: yangwenhao
@Contact: 874681044@qq.com
@Software: PyCharm
@File: cn-celeb.py
@Time: 2020/2/11 12:03 PM
@Overview:

wav.scp
spk2utt

"""

# Training settings
import argparse
import pathlib
import os
import numpy as np

parser = argparse.ArgumentParser(description='Prepare scp file for cn-celeb')
# Model options

# options for vox1
parser.add_argument('--dataset-dir', type=str, default='/home/young/store/dataset/CN-Celeb',
                    help='path to dataset')
parser.add_argument('--output-dir', type=str, default='/home/young/store/project/lstm_speaker_verification/data/CN-Celeb',
                    help='path to dataset')

args = parser.parse_args()

data_dir = '/'.join((args.dataset_dir, 'data'))
data_dir_path = pathlib.Path(data_dir)
out_dir = args.output_dir
out_dir_path = pathlib.Path(out_dir)

assert data_dir_path.exists()
if not out_dir_path.exists():
    os.makedirs(str(out_dir_path))

spks_dir = [x for x in data_dir_path.iterdir() if x.is_dir()]
spks_name = [x.name for x in spks_dir]

cn_npy = str(out_dir_path)+'/cn.npy'
try:
    cn_lst = np.load(cn_npy)
    if len(cn_lst)!=130108:
        raise Exception
except:
    cn_lst = []
    for spk in spks_dir:
        utts = [x for x in spk.iterdir() if x.is_file() and x.suffix == '.wav']  # [.../data/id00000/singing-01-002.wav, ...]
        for utt in utts:
            utt_dic = {}
            uid = spk.name + '-' + utt.name.rstrip('.wav')
            utt_dic['uid'] = uid
            utt_dic['path'] = str(utt)
            utt_dic['spk'] = spk.name
            cn_lst.append(utt_dic)
    np.save(cn_npy, cn_lst)


wav_scp = 'wav.scp'
utt2spk = 'spk2utt'
# dev set

dev_lst = args.dataset_dir + '/dev/dev.lst'
dev_lst_f = open(dev_lst, 'r')

dev_dir_path = pathlib.Path(args.output_dir + '/dev')
if not dev_dir_path.exists():
    os.makedirs(str(dev_dir_path))

wav_scp = []
utt2spk = []

for spk in dev_lst_f.readlines():
    spk_name = spk.rstrip('\n')
    for utt in cn_lst:
        if utt['spk'] == spk_name:
            wav_scp.append(utt['uid'] + ' ' + utt['path'] + '\n')
            # f2.write(' ' + utt['uid'])
            # spk_name = spk_name + '\n' if idx < (len(enroll) - 1) else spk_id
            utt2spk.append(utt['uid'] + ' ' + spk_name + '\n')
wav_scp.sort()
utt2spk.sort()

with open(args.output_dir + '/dev/wav.scp', 'w') as f1, \
     open(args.output_dir + '/dev/utt2spk', 'w') as f2:
    f1.writelines(wav_scp)
    f2.writelines(utt2spk)

enroll_lst = args.dataset_dir + '/eval/lists/enroll.lst'
enroll_lst_f = open(enroll_lst, 'r')

enroll_dir_path = pathlib.Path(args.output_dir + '/enroll')
if not enroll_dir_path.exists():
    os.makedirs(str(enroll_dir_path))

wav_scp = []
utt2spk = []

enroll = enroll_lst_f.readlines()
for idx, utt_pair in enumerate(enroll):
    uid, path = utt_pair.split(' ')  # id00998-enroll enroll/id00998-enroll.wav
    spk_id = uid.rstrip('-enroll')
    path = args.dataset_dir + '/eval/' + path

    wav_scp.append(uid + ' '+ path)
    # f2.write(spk_id + ' ' + uid + '\n')
    spk_id = spk_id + '\n'
    utt2spk.append(uid + ' ' + spk_id)

wav_scp.sort()
utt2spk.sort()

with open(args.output_dir + '/enroll/wav.scp', 'w') as f1, \
     open(args.output_dir + '/enroll/utt2spk', 'w') as f2:
    f1.writelines(wav_scp)
    f2.writelines(utt2spk)


# eval set



















