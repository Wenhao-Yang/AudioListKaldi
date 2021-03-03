#!/usr/bin/env python
# encoding: utf-8

"""
@Author: yangwenhao
@Contact: 874681044@qq.com
@Software: PyCharm
@File: make_aidata.py
@Time: 2021/3/3 11:20
@Overview:
"""
# Training settings
import argparse
import pathlib
import os
import numpy as np

parser = argparse.ArgumentParser(description='Prepare scp file for cn-celeb')
# Model options

# options for
parser.add_argument('--dataset-dir', type=str, default='/home/storage/yangwenhao/dataset/aidatatang_200zh',
                    help='path to dataset')
parser.add_argument('--output-dir', type=str, default='data/aidata',
                    help='path to dataset')
parser.add_argument('--test-spk', type=int, default=40,
                    help='path to dataset')
parser.add_argument('--np-seed', type=int, default=1234,
                    help='path to dataset')
parser.add_argument('--suffix', type=str, default='',
                    help='number of jobs to make feats (default: 10)')
args = parser.parse_args()

if __name__ == '__main__':

    data_dir = '/'.join((args.dataset_dir, 'corpus'))

    data_dir = os.path.abspath(data_dir)
    data_dir_path = pathlib.Path(data_dir)

    out_dir = args.output_dir
    out_dir_path = pathlib.Path(out_dir)

    assert data_dir_path.exists()
    if not out_dir_path.exists():
        os.makedirs(str(out_dir_path))

    subsets_dir = [x for x in data_dir_path.iterdir() if x.is_dir()]
    for subset_dir in subsets_dir:
        set_name = subset_dir.name

        spks_dir = [x for x in subset_dir.iterdir() if x.is_dir()]
        spks_name = [x.name for x in spks_dir]

        all_dataset = {}
        all_wavs = []

        for spk_dir in spks_dir:
            spk_id = spk_dir.name
            wavs = [str(p) for p in list(spk_dir.glob('*.wav'))]
            for w in wavs:
                all_wavs.append(w)

            all_dataset[spk_id] = wavs

        wav_scp = []
        utt2spk = []

        subset_lst = subset_dir + '/wav.scp'

        subset_dir_out = pathlib.Path(args.output_dir + set_name)
        if not subset_dir_out.exists():
            os.makedirs(str(subset_dir_out))

        if os.path.exists(subset_lst):
            all_lst_f = open(subset_lst, 'r')
            for id2path in all_lst_f.readlines():
                # IC0001W0002	wav/C0001/IC0001W0002.wav
                uid, wav_path = id2path.split()
                if args.suffix != '':
                    uid = uid + '-%s' % args.suffix

                spk_id = wav_path.split('/')[-2]
                wav_path = subset_dir + wav_path

                if os.path.exists(wav_path):
                    wav_scp.append(uid + ' ' + wav_path + '\n')
                    utt2spk.append(uid + ' ' + spk_id + '\n')

        else:
            for wav in all_wavs:
                uid = os.path.basename(wav)[:-4]
                spk_id = os.path.basename(os.path.dirname(uid))
                if os.path.exists(wav):
                    # wav_rela_path = str(pathlib.Path(wav).relative_to(args.dataset_dir))
                    wav_scp.append(uid + ' ' + wav + '\n')
                    utt2spk.append(uid + ' ' + spk_id + '\n')

        wav_scp.sort()
        utt2spk.sort()
        with open(subset_dir_out + '/wav.scp', 'w') as f1, \
                open(subset_dir_out + '/utt2spk', 'w') as f2:
            f1.writelines(wav_scp)
            f2.writelines(utt2spk)

        print('\nFor %s :\n\twav.scp and utt2spk write to %s where there are %d utterances' % (set_name, subset_dir_out, len(wav_scp)))