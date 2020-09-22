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
parser.add_argument('--dataset-dir', type=str, default='/home/yangwenhao/storage/dataset/AISHELL-2/iOS',
                    help='path to dataset')
parser.add_argument('--output-dir', type=str, default='data/aishell2',
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

    wav_scp_f = open(os.path.join(output_dir, 'wav.scp'), 'w')
    utt2spk_f = open(os.path.join(output_dir, 'utt2spk'), 'w')

    num_utt = 0
    for wav in glob.glob('%s/*/*.wav' % data_root):
        sid_path = os.path.dirname(wav)
        sid = os.path.basename(sid_path)
        wav_name = os.path.split(wav)[-1][:-4]

        if len(wav_name) > 8:
            wav_name = wav_name[-8:]

        uid = '-'.join((sid, wav_name))
        if prefix != '':
            uid = prefix + '-' + uid
        if suffix != '':
            uid = uid + '-' + suffix

        wav_scp_f.write(uid + ' ' + wav + '\n')
        utt2spk_f.write(uid + ' ' + sid + '\n')
        num_utt += 1


    wav_scp_f.close()
    utt2spk_f.close()

    print('List %d utterances.' % num_utt)

if __name__ == '__main__':
    main()

