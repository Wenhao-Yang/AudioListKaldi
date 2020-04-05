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

parser = argparse.ArgumentParser(description='Prepare scp file for sitw')
# Model options

# options for vox1
parser.add_argument('--dataset-dir', type=str, default='/work20/yangwenhao/dataset/sitw',
                    help='path to dataset')
parser.add_argument('--output-dir', type=str, default='data/sitw',
                    help='path to dataset')
args = parser.parse_args()

def main():
    data_root = args.dataset_dir
    output_dir = args.output_dir

    for s in 'dev', 'eval':

        set_dir = os.path.join(data_root, s)
        set_audio_dir = os.path.join(set_dir, 'audio')
        set_lst_dir = os.path.join(set_dir, 'lists')

        spk2uid = {}
        wav2scp = {}
        with open(os.path.join(str(set_lst_dir), 'enroll-core.lst'), 'r') as ec:
            enroll_core = ec.readlines()
            for l in enroll_core:
                # 12013 audio/unotx.flac
                spk_id, flac_path = l.split()

                flac_rela = pathlib.Path(flac_path)

                uid = '-'.join((s, os.path.splitext(flac_rela.name)[0]))
                if spk_id in spk2uid.keys():
                    pdb.set_trace()

                spk2uid[spk_id] = uid
                wav2scp[uid] = os.path.join(set_audio_dir, flac_path)

        with open(os.path.join(str(set_lst_dir), 'enroll-assist.lst'), 'r') as ea:
            enroll_assi = ea.readlines()
            for l in enroll_assi:
                # 45205 audio/ggjnl.flac 88.000 97.990
                spk_id, flac_path, start, end = l.split()
                flac_rela = pathlib.Path(flac_path)

                uid = '-'.join(('dev',
                                os.path.splitext(flac_rela.name)[0],
                                '%04d' % int(float(start)),
                                '%04d' % int(float(end))
                                )
                               )

                spk2uid[spk_id] = uid
                full_flac_path = os.path.join(set_audio_dir, flac_path)
                duration = float(end) - float(start)
                soxed_path = 'sox %s -t flac - trim %s %.3f |' % (full_flac_path, start, duration)
                wav2scp[uid] = soxed_path

        set_output = os.path.join(output_dir, s)
        if not os.path.exists(set_output):
            os.makedirs(set_output)

        wav_scp = os.path.join(set_output, 'wav.scp')
        uids = list(wav2scp.keys())
        uids.sort()
        with open(wav_scp, 'w') as f:
            for u in uids:
                f.write(u+' '+wav2scp[u]+'\n')


        spk2utt = os.path.join(set_output, 'spk2utt')
        spks = list(spk2uid.keys())
        spks.sort()
        with open(spk2utt, 'w') as f:
            for spk in spks:
                f.write(spk + ' ' + spk2uid[spk] + '\n')

        set_keys_dir = os.path.join(set_dir, 'keys')
        trials = os.path.join(set_output, 'trials')
        with open(os.path.join(set_keys_dir, 'core-core.lst'), 'r') as cc, \
            open(trials, 'w') as trials_f:
            pairs = cc.readlines()
            for p in pairs:
                # 12013 audio/mihtz.flac imp
                ppp = p.split()
                pair_a_spk = ppp[0]
                pair_a = spk2uid[pair_a_spk]
                flac_rela = pathlib.Path(ppp[1])

                pair_b = '-'.join((s, os.path.splitext(flac_rela.name)[0]))
                if ppp[2]=='tgt':
                    trials_f.write(pair_a + ' ' + pair_b + ' ' + 'target\n')
                else:
                    trials_f.write(pair_a + ' ' + pair_b + ' ' + 'nontarget\n')

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