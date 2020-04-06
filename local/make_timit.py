#!/usr/bin/env python
# encoding: utf-8

"""
@Author: yangwenhao
@Contact: 874681044@qq.com
@Software: PyCharm
@File: make_timit.py
@Time: 2020/4/7 12:09 AM
@Overview:
"""
import argparse
import pathlib
import os
import pdb
import numpy as np

parser = argparse.ArgumentParser(description='Prepare scp file for timit')
# Model options

# options for vox1
parser.add_argument('--dataset-dir', type=str, default='/data/timit',
                    help='path to dataset')
parser.add_argument('--output-dir', type=str, default='data/timit',
                    help='path to dataset')
args = parser.parse_args()


def main():
    data_root = args.dataset_dir
    output_dir = args.output_dir

    print('==>Preparing Timit in %s.' % data_root)
    # /data/timit/test/dr1/faks0/s

    for s in 'train', 'test':
        set_dir = os.path.join(data_root, s)
        set_output = os.path.join(output_dir, s)

        if not os.path.exists(set_output):
            os.makedirs(set_output)
        # dr1/fcjf0/sa1.wav
        set_dir_path = pathlib.Path(set_dir)
        all_wavs = list(set_dir_path.glob('*/*/*.wav'))

        # uid2spk = {}
        wav_scp = os.path.join(set_output, 'wav.scp')
        uid2spk = os.path.join(set_output, 'utt2spk')

        wav2scp_dict = {}
        uid2spk_dict = {}
        spk2uid_dict = {}

        for l in all_wavs:
            # /data/timit/train/dr1/fcjf0/sa1.wav
            wav_path = str(l)
            spk_id = l.parent.name
            uid = '-'.join((spk_id, os.path.splitext(l.name)[0]))  # os.path.splitext(flac_rela.name)[0]

            if spk_id in spk2uid_dict.keys():
                spk2uid_dict[spk_id].append(uid)
            else:
                spk2uid_dict[spk_id] = [uid]

            wav2scp_dict[uid] = wav_path
            uid2spk_dict[uid] = spk_id

        uids = list(wav2scp_dict.keys())
        uids.sort()
        print('There are %d utterances in %s' % (len(uids), s))
        with open(wav_scp, 'w') as ws, open(uid2spk, 'w') as us:
            for u in uids:
                ws.write(u + ' ' + wav2scp_dict[u] + '\n')
                us.write(u + ' ' + uid2spk_dict[u] + '\n')

        spk2uid = os.path.join(set_output, 'spk2utt')
        spks = list(spk2uid_dict.keys())
        spks.sort()
        print('There are %d speakers in %s' % (len(uids), s))
        with open(spk2uid, 'w') as su:
            for spk in spks:
                su.write(spk)
                for uid in spk2uid_dict[spk]:
                    su.write(' ' + uid)
                ws.write('\n')


if __name__ == '__main__':
    main()
