#!/usr/bin/env python
# encoding: utf-8

"""
@Author: yangwenhao
@Contact: 874681044@qq.com
@Software: PyCharm
@File: make_sitw.py.py
@Time: 2020/4/5 8:53 AM
@Overview:
"""
import argparse
import pathlib
import os
import pdb
import numpy as np
from tqdm import tqdm

parser = argparse.ArgumentParser(description='Prepare scp file for sitw')
# Model options

# options for vox1
parser.add_argument('--dataset-dir', type=str, default='/home/yangwenhao/storage/dataset/sitw_wav',
                    help='path to dataset')
parser.add_argument('--output-dir', type=str, default='data/sitw',
                    help='path to dataset')
args = parser.parse_args()

def main():
    data_root = args.dataset_dir
    output_dir = args.output_dir

    assert os.path.exists(data_root), print(data_root, " not exist!")

    for s in 'dev', 'eval':
        print("Processing %s set ...")
        set_dir = os.path.join(data_root, s)
        # set_audio_dir = os.path.join(set_dir, 'audio')
        set_lst_dir = os.path.join(set_dir, 'lists')

        spk2uid = {}
        # uid2spk = {}
        wav2scp = {}
        print("  Processing enroll-core.lst ...")
        with open(os.path.join(str(set_lst_dir), 'enroll-core.lst'), 'r') as ec:
            enroll_core = ec.readlines()
            pbar = tqdm(enroll_core)
            for l in pbar:
                # 12013 audio/unotx.flac
                spk_id, flac_path = l.split()

                flac_rela = pathlib.Path(flac_path)

                uid = '-'.join((s, os.path.splitext(flac_rela.name)[0]))
                if spk_id in spk2uid:
                    pdb.set_trace()

                spk2uid[spk_id] = uid
                # uid2spk[uid] = spk_id


                full_flac_path = os.path.join(set_dir, flac_path)
                wav_path = full_flac_path.replace('flac', 'wav')

                if os.path.exists(wav_path):
                    full_flac_path = wav_path
                else:
                    assert os.path.exists(full_flac_path), print("%s does not exists!"%full_flac_path)
                wav2scp[uid] = full_flac_path

        print("  Processing enroll-assist.lst ...")
        with open(os.path.join(str(set_lst_dir), 'enroll-assist.lst'), 'r') as ea:
            enroll_assi = ea.readlines()
            pbar = tqdm(enroll_assi)
            for l in pbar:
                # 45205 audio/ggjnl.flac 88.000 97.990
                spk_id, flac_path, start, end = l.split()
                audio_format='flac'


                flac_rela = pathlib.Path(flac_path)
                if spk_id in spk2uid:
                    pdb.set_trace()

                uid = '-'.join(('dev',
                                os.path.splitext(flac_rela.name)[0],
                                '%04d' % int(float(start)),
                                '%04d' % int(float(end))
                                )
                               )

                spk2uid[spk_id] = uid
                full_flac_path = os.path.join(set_dir, flac_path)
                wav_path = full_flac_path.replace('flac', 'wav')
                if os.path.exists(wav_path):
                    full_flac_path = wav_path
                    audio_format = 'wav'
                else:
                    assert os.path.exists(full_flac_path)

                duration = float(end) - float(start)
                soxed_path = 'sox %s -t %s - trim %s %.3f |' % (full_flac_path, audio_format, start, duration)
                wav2scp[uid] = soxed_path

        set_output = os.path.join(output_dir, s)
        if not os.path.exists(set_output):
            os.makedirs(set_output)

        set_keys_dir = os.path.join(set_dir, 'keys')
        trials = os.path.join(set_output, 'trials')
        all_test_wav = []
        all_test_spk = []

        print("  Processing core-core.lst ...")
        with open(os.path.join(set_keys_dir, 'core-core.lst'), 'r') as cc, \
            open(trials, 'w') as trials_f:
            pairs = cc.readlines()
            pbar = tqdm(pairs)
            for p in pbar:
                # 12013 audio/mihtz.flac imp
                ppp = p.split()
                pair_a_spk = ppp[0]
                all_test_spk.append(pair_a_spk)
                pair_a = spk2uid[pair_a_spk]
                flac_rela = pathlib.Path(ppp[1])

                pair_b = '-'.join((s, os.path.splitext(flac_rela.name)[0]))
                if ppp[2]=='tgt':
                    trials_f.write(pair_a + ' ' + pair_b + ' ' + 'target\n')
                else:
                    trials_f.write(pair_a + ' ' + pair_b + ' ' + 'nontarget\n')
                all_test_wav.append(pair_a)
                all_test_wav.append(pair_b)

        uids = np.unique(all_test_wav)
        uids.sort()
        wav_scp = os.path.join(set_output, 'wav.scp')
        with open(wav_scp, 'w') as f:
            for u in uids:
                f.write(u + ' ' + wav2scp[u] + '\n')

        spks = np.unique(all_test_spk)
        spks.sort()
        spk2utt = os.path.join(set_output, 'spk2utt')
        with open(spk2utt, 'w') as f:
            for spk in spks:
                f.write(spk + ' ' + spk2uid[spk] + '\n')
        # wav_scp = os.path.join(set_output, 'wav.scp')
        # uid2wav = {}
        #
        # all_wav = list(set_root.glob('*flac'))
        #
        # for wav in all_wav:
        #     uid = '-'.join((s, wav.name.rstrip('.flac')))
        #     wav_path = str(wav)
        #     uid2wav[uid] = wav_path

        # write wav.scp
        # sox aahtm.flac -t flac - trim 0 30
        # with open(wav_scp, 'w') as f:
        #     uids = list(uid2wav.keys())
        #     uids.sort()
        #
        #     for u in uids:
        #         f.write(u+' '+uid2wav[u]+'\n')

if __name__ == '__main__':
    main()