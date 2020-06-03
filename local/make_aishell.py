#!/usr/bin/env python
# encoding: utf-8

"""
@Author: yangwenhao
@Contact: 874681044@qq.com
@Software: PyCharm
@File: make_cnceleb.py
@Time: 2020/06/03 14:03 PM
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

# options for
parser.add_argument('--dataset-dir', type=str, default='/data/AISHELL-2/iOS',
                    help='path to dataset')
parser.add_argument('--output-dir', type=str, default='data/aishell2',
                    help='path to dataset')
parser.add_argument('--test-spk', type=int, default=40,
                    help='path to dataset')
args = parser.parse_args()

if __name__ == '__main__':

    data_dir = '/'.join((args.dataset_dir, 'data/wav'))

    data_dir = os.path.abspath(data_dir)
    data_dir_path = pathlib.Path(data_dir)

    out_dir = args.output_dir
    out_dir_path = pathlib.Path(out_dir)

    assert data_dir_path.exists()
    if not out_dir_path.exists():
        os.makedirs(str(out_dir_path))

    spks_dir = [x for x in data_dir_path.iterdir() if x.is_dir()]
    spks_name = [x.name for x in spks_dir]

    all_dataset = {}
    all_wavs = []

    for spk_dir in spks_dir:
        spk_id = spk_dir.name
        wavs = [str(p) for p in list(spk_dir.glob('*.wav'))]
        for w in wavs:
            all_wavs.append(w)

        all_dataset[spk_id]=wavs

    temp_npy = str(out_dir_path) + '/temp.npy'

    try:
        if not os.path.exists(temp_npy):
            raise FileExistsError

        cn_lst = np.load(temp_npy)
        if len(cn_lst) != 1009223:
            raise ValueError

        print('Load wav lst from %s' % temp_npy)

    except (FileExistsError, ValueError) as e:
        cn_lst = np.array(all_wavs)
        np.save(temp_npy, cn_lst)
        print('Saving wav lst to %s' % temp_npy)

    wav_scp = []
    utt2spk = []

    all_lst = args.dataset_dir + '/data/wav.scp'
    all_lst_f = open(all_lst, 'r')

    all_dir_path = pathlib.Path(args.output_dir + '/all')
    if not all_dir_path.exists():
        os.makedirs(str(all_dir_path))

    for id2path in all_lst_f.readlines():
        # IC0001W0002	wav/C0001/IC0001W0002.wav
        uid, wav_path = id2path.split()
        spk_id = wav_path.split('/')[1]
        wav_path = data_dir + wav_path

        wav_scp.append(uid + ' ' + wav_path + '\n')
        utt2spk.append(uid + ' ' + spk_id + '\n')

    wav_scp.sort()
    utt2spk.sort()

    with open(args.output_dir + '/all/wav.scp', 'w') as f1, \
         open(args.output_dir + '/all/utt2spk', 'w') as f2:
        f1.writelines(wav_scp)
        f2.writelines(utt2spk)

    # dev set

    test_spks = []

    for i in range(args.test_spk):
        j = np.random.randint(len(spks_name))
        test_spks.append(spks_name.pop(j))

    dev_spks = spks_name

    dev_dir_path = pathlib.Path(args.output_dir + '/dev')
    if not dev_dir_path.exists():
        os.makedirs(str(dev_dir_path))

    wav_scp = []
    utt2spk = []

    for spk_id in dev_spks:
        this_spk_wav = all_dataset[spk_id]
        for utt in this_spk_wav: # '/data/AISHELL-2/iOS/data/wav/C0902/IC0902W0278.wav'
            utt_path = pathlib.Path(utt)
            uid = utt_path.name[:-4]

            wav_scp.append(uid + ' ' + utt + '\n')
            utt2spk.append(uid + ' ' + spk_id + '\n')

    wav_scp.sort()
    utt2spk.sort()

    with open(args.output_dir + '/dev/wav.scp', 'w') as f1, \
            open(args.output_dir + '/dev/utt2spk', 'w') as f2:
        f1.writelines(wav_scp)
        f2.writelines(utt2spk)

    print('\nFor dev:\n\twav.scp and utt2spk write to %s/dev .' % args.output_dir)
    print('\tThere are %d in dev' % len(wav_scp))

    test_dir_path = pathlib.Path(args.output_dir + '/test')
    if not test_dir_path.exists():
        os.makedirs(str(test_dir_path))

    wav_scp = []
    utt2spk = []

    for spk_id in test_spks:
        this_spk_wav = all_dataset[spk_id]
        for utt in this_spk_wav:  # '/data/AISHELL-2/iOS/data/wav/C0902/IC0902W0278.wav'
            utt_path = pathlib.Path(utt)
            uid = utt_path.name[:-4]

            wav_scp.append(uid + ' ' + utt + '\n')
            utt2spk.append(uid + ' ' + spk_id + '\n')

    wav_scp.sort()
    utt2spk.sort()

    with open(args.output_dir + '/test/wav.scp', 'w') as f1, \
            open(args.output_dir + '/test/utt2spk', 'w') as f2:
        f1.writelines(wav_scp)
        f2.writelines(utt2spk)

    print('\nFor dev:\n\twav.scp and utt2spk write to %s/test .' % args.output_dir)
    print('\tThere are %d in test' % len(wav_scp))