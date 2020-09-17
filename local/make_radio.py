#!/usr/bin/env python
# encoding: utf-8

"""
@Author: yangwenhao
@Contact: 874681044@qq.com
@Software: PyCharm
@File: make_radio.py
@Time: 2020/7/21 11:51 PM
@Overview:
"""
import argparse
import pathlib
import os
import numpy as np
import glob


parser = argparse.ArgumentParser(description='Prepare scp file for radio noise')
# Model options

# options for
parser.add_argument('--dataset-dir', type=str, default='/home/yangwenhao/storage/dataset/wav_test',
                    help='path to dataset')
parser.add_argument('--output-dir', type=str, default='data/radio_noise',
                    help='path to dataset')
parser.add_argument('--prefix', type=str, default='',
                    help='number of jobs to make feats (default: 10)')
parser.add_argument('--suffix', type=str, default='',
                    help='number of jobs to make feats (default: 10)')

args = parser.parse_args()

def main():
    data_root = args.dataset_dir
    output_dir = args.output_dir
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    prefix = args.prefix + '-' if args.prefix != '' else ''
    suffix = '-' + args.suffix if args.prefix != '' else ''

    num_utt = 0
    for s in 'noise', 'sample':
        if not os.path.exists(os.path.join(output_dir, s)):
            os.makedirs(os.path.join(output_dir, s))

        wav_scp_f = open(os.path.join(output_dir, s, 'wav.scp'), 'w')
        utt2spk_f = open(os.path.join(output_dir, s, 'utt2spk'), 'w')

        set_dir = os.path.join(data_root, s)
        set_dir = pathlib.Path(set_dir)

        all_wavs = list(set_dir.glob(r'*/*.wav'))

        for wav in all_wavs:
            w = str(wav)
            chn = os.path.basename(os.path.dirname(w))
            utt = os.path.basename(os.path.splitext(w)[-2])

            uid = '-'.join((s, chn, utt))
            uid = prefix + uid + suffix

            w_path = os.path.abspath(w)
            wav_scp_f.write(uid + ' ' + w_path + '\n')
            utt2spk_f.write(uid + ' ' + chn + '\n')
            num_utt += 1

        wav_scp_f.close()
        utt2spk_f.close()

    print('List %d utterances.' % num_utt)

if __name__ == '__main__':
    main()

