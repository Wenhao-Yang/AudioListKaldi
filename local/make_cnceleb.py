#!/usr/bin/env python
# encoding: utf-8

"""
@Author: yangwenhao
@Contact: 874681044@qq.com
@Software: PyCharm
@File: make_cnceleb.py
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
parser.add_argument('--dataset-dir', type=str, default='/home/yangwenhao/storage/dataset/CN-Celeb',
                    help='path to dataset')
parser.add_argument('--dataset-dir-2', type=str, default='/home/work2020/yangwenhao/dataset/CNCELEB2',
                    help='path to dataset')
parser.add_argument('--output-dir', type=str, default='data/cnceleb',
                    help='path to dataset')

args = parser.parse_args()

if __name__ == '__main__':

    data_dir = '/'.join((args.dataset_dir, 'data'))

    data_dir = os.path.abspath(data_dir)
    data_dir_path = pathlib.Path(data_dir)
    out_dir = args.output_dir
    out_dir_path = pathlib.Path(out_dir)

    assert data_dir_path.exists()
    if not out_dir_path.exists():
        os.makedirs(str(out_dir_path))

    spks_dir = [x for x in data_dir_path.iterdir() if x.is_dir()]
    spks_name = [x.name for x in spks_dir]

    cn_npy = str(out_dir_path) + '/cn.npy'

    try:
        if not os.path.exists(cn_npy):
            raise FileExistsError

        cn_lst = np.load(cn_npy)
        if len(cn_lst) != 130108:
            raise ValueError
        # dom = set()
        # for utt_dic in cn_lst:
        #     dom.add(utt_dic['uid'].split('-')[1])

        print('Load wav lst from %s' % cn_npy)

    except (FileExistsError, ValueError) as e:
        cn_lst = []
        # dom = set()
        for spk in spks_dir:
            # [.../data/id00000/singing-01-002.wav, ...]
            utts = [x for x in spk.iterdir() if x.is_file() and x.suffix == '.wav']
            for utt in utts:
                utt_dic = {}
                uid = spk.name + '-' + utt.name.rstrip('.wav')
                utt_dic['uid'] = uid

                # dom.add(uid.split('-')[1])
                utt_dic['path'] = str(utt)
                utt_dic['spk'] = spk.name
                cn_lst.append(utt_dic)

        cn_lst = np.array(cn_lst)
        np.save(cn_npy, cn_lst)
        print('Saving wav lst to %s' % cn_npy)

    # wav_scp = 'wav.scp'
    # utt2spk = 'spk2utt'
    # utt2dom = 'utt2dom'
    # dev set

    dev_lst = args.dataset_dir + '/dev/dev.lst'
    dev_lst_f = open(dev_lst, 'r')

    dev_dir_path = pathlib.Path(args.output_dir + '/dev')
    if not dev_dir_path.exists():
        os.makedirs(str(dev_dir_path))

    wav_scp = []
    utt2spk = []
    utt2dom = []

    for spk in dev_lst_f.readlines():
        spk_name = spk.rstrip('\n')
        for utt in cn_lst:
            if utt['spk'] == spk_name:
                wav_scp.append(utt['uid'] + ' ' + utt['path'] + '\n')
                u_dom = utt['uid'].split('-')[1]
                utt2dom.append(utt['uid'] + ' ' + u_dom + '\n')
                # f2.write(' ' + utt['uid'])
                # spk_name = spk_name + '\n' if idx < (len(enroll) - 1) else spk_id
                utt2spk.append(utt['uid'] + ' ' + spk_name + '\n')
    wav_scp.sort()
    utt2spk.sort()
    utt2dom.sort()

    with open(args.output_dir + '/dev/wav.scp', 'w') as f1, \
            open(args.output_dir + '/dev/utt2spk', 'w') as f2, \
            open(args.output_dir + '/dev/utt2dom', 'w') as f3:
        f1.writelines(wav_scp)
        f2.writelines(utt2spk)
        f3.writelines(utt2dom)

    print('\nFor dev:\n\twav.scp and utt2spk write to %s/dev .' % args.output_dir)
    print('\tThere are %d in dev' % len(wav_scp))

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

        wav_scp.append(uid + ' ' + path)
        # f2.write(spk_id + ' ' + uid + '\n')
        spk_id = spk_id + '\n'
        utt2spk.append(uid + ' ' + spk_id)

    wav_scp.sort()
    utt2spk.sort()

    with open(args.output_dir + '/enroll/wav.scp', 'w') as f1, \
            open(args.output_dir + '/enroll/utt2spk', 'w') as f2:
        f1.writelines(wav_scp)
        f2.writelines(utt2spk)
    print('\nFor Enroll:\n\twav.scp and utt2spk write to %s/enroll .' % args.output_dir)
    print('\tThere are %d in enroll' % len(wav_scp))

    # eval set
    test_lst = args.dataset_dir + '/eval/lists/test.lst'
    test_lst_f = open(test_lst, 'r')

    test_dir_path = pathlib.Path(args.output_dir + '/eval')
    if not test_dir_path.exists():
        os.makedirs(str(test_dir_path))

    wav_scp = []
    utt2spk = []
    utt2dom = []

    test = test_lst_f.readlines()
    for idx, utt_path in enumerate(test):
        path = utt_path.rstrip('.wav').split('/')  # test/id00999-singing-02-006.wav
        # uid = '-'.join(path).rstrip('.wav\n')  # test-id00999-singing-02-006.wav
        uid = path[-1].rstrip('.wav\n')  # id00999-singing-02-006.wav

        dom = uid.split('-')[2]
        spk_id = uid.split('-')[0]
        path = args.dataset_dir + '/eval/' + utt_path
        wav_scp.append(uid + ' ' + path)
        utt2dom.append(uid + ' ' + dom + '\n')
        # f2.write(spk_id + ' ' + uid + '\n')
        utt2spk.append(uid + ' ' + spk_id + '\n')

    wav_scp.sort()
    utt2spk.sort()
    utt2dom.sort()

    with open(args.output_dir + '/eval/wav.scp', 'w') as f1, \
            open(args.output_dir + '/eval/utt2spk', 'w') as f2, \
            open(args.output_dir + '/eval/utt2dom', 'w') as f3:
        f1.writelines(wav_scp)
        f2.writelines(utt2spk)
        f3.writelines(utt2dom)

    print('\nFor eval:\n\twav.scp and utt2spk write to %s/test .' % args.output_dir)
    print('\tThere are %d in test' % len(wav_scp))

    trials_uid = []
    trials_lst = args.dataset_dir + '/eval/lists/trials.lst'
    trials_lst_f = open(trials_lst, 'r')

    trials = trials_lst_f.readlines()
    for idx, utt_pair in enumerate(trials):
        enroll_uid, test_path, target = utt_pair.split(' ')  # id00800-enroll test/id00800-singing-01-005.wav 1

        path = test_path.rstrip('.wav').split('/')  # test/id00999-singing-02-006.wav
        test_uid = path[1]  # test-id00999-singing-02-006.wav

        trials_uid.append(enroll_uid + ' ' + test_uid + ' ' + target)

    with open(args.output_dir + '/eval/trials', 'w') as f:
        f.writelines(trials_uid)

    data_dirs = ['/'.join((args.dataset_dir_2, 'data1')),
                 '/'.join((args.dataset_dir_2, 'data2'))]

    cn_lst = []
    for data_dir in data_dirs:
        data_dir_path = pathlib.Path(data_dir)
        if data_dir_path.exists():
            spks_dir = [x for x in data_dir_path.iterdir() if x.is_dir()]
            for spk in spks_dir:
                utts = [x for x in spk.iterdir() if x.is_file() and x.suffix == '.wav']
                for utt in utts:
                    utt_dic = {}
                    uid = spk.name + '-' + utt.name.rstrip('.wav')
                    utt_dic['uid'] = uid

                    # dom.add(uid.split('-')[1])
                    utt_dic['path'] = str(utt)
                    utt_dic['spk'] = spk.name

                    cn_lst.append(utt_dic)

    if len(cn_lst) > 0:
        dev_dir_path = pathlib.Path(args.output_dir + '/dev2')
        if not dev_dir_path.exists():
            os.makedirs(str(dev_dir_path))

        wav_scp = []
        utt2spk = []
        utt2dom = []

        for utt in cn_lst:
            wav_scp.append(utt['uid'] + ' ' + utt['path'] + '\n')
            u_dom = utt['uid'].split('-')[1]
            utt2dom.append(utt['uid'] + ' ' + u_dom + '\n')
            utt2spk.append(utt['uid'] + ' ' + utt['spk'] + '\n')

        wav_scp.sort()
        utt2spk.sort()
        utt2dom.sort()

        dev2_dir = args.output_dir + '/dev2'
        with open(dev2_dir + '/wav.scp', 'w') as f1, \
                open(dev2_dir + '/utt2spk', 'w') as f2, \
                open(dev2_dir + '/utt2dom', 'w') as f3:

            f1.writelines(wav_scp)
            f2.writelines(utt2spk)
            f3.writelines(utt2dom)

        print('\nFor dev2:\n\twav.scp and utt2spk write to %s/dev2 .' % args.output_dir)
        print('\tThere are %d in dev' % len(wav_scp))

    print('Saving trials in %s' % (args.output_dir + '/eval/trials'))
    print('Preparing Completed!')
