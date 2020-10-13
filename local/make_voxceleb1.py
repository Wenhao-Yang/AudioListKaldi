#!/usr/bin/env python
# encoding: utf-8

"""
@Author: yangwenhao
@Contact: 874681044@qq.com
@Software: PyCharm
@File: make_voxceleb.py
@Time: 2019/3/16 下午2:48
@Overview:
data dir structure:
    /data/voxceleb/voxceleb1_wav/vox1_test_wav/wav/id10309/vobW27_-JyQ/00015.wav
produce files:
    spk2utt: spkid filepath
    utt2spk: produced by *.sh script
    wav.scp: uttid filepath
"""
import argparse
import os
import csv
import sys
import pathlib
from tqdm import tqdm
parser = argparse.ArgumentParser(description='Prepare scp file for cn-celeb')
# Model options

# options for
parser.add_argument('--dataset-dir', type=str, default='/home/yangwenhao/storage/dataset/voxceleb1',
                    help='path to dataset')
parser.add_argument('--output-dir', type=str, default='data/vox1',
                    help='path to dataset')
args = parser.parse_args()

def prep_id_idname(meta_path):
    id_idname = {}
    with open(meta_path) as f:
        meta_file = csv.reader(f)
        for row in meta_file:
            if meta_file.line_num > 1:
                (id,idname,gender,country,set) = row[0].split('\t')
                id_idname[id] = idname
    return id_idname

def prep_u2s_ws(flistpath, id_idname, out_dir):
    uid2scp = []
    uid2idname = []
    if not os.path.exists(out_dir):
        os.mkdir(out_dir)
    with open(flistpath) as f:
        for line in f.readlines():
            # id11251/s4R4hvqrhFw/00006.wav
            id = line[-30:-23]
            rec_id = line[-22:-11]
            wav_name = line[-9:-1]
            uid = str(id_idname[id]) + '-' +str(rec_id) + '-' + str(wav_name)
            uid2scp.append((uid, line))
            uid2idname.append((uid, id_idname[id]))

    with open(os.path.join(out_dir, 'wav.scp'), 'w') as f:
        for e in uid2scp:
            f.writelines(str(e[0]) + ' ' + str(e[1]))

    with open(os.path.join(out_dir, 'utt2spk'), 'w') as f:
        for e in uid2idname:
            f.writelines(str(e[0]) + ' ' + str(e[1]) + '\n')

def read_vox1_structure(directory, train_dir, test_dir):
    """
    :param directory:
    :return: [{'subset': b'dev', 'speaker_id': b'id10133', 'filename': b'vox1_dev_wav/wav/id10133/wqLbqjw42L0/00001', 'uri': 0}...
             ]
    """
    voxceleb = []
    # /CDShare/voxceleb1/
    data_root = pathlib.Path(directory)
    data_root.cwd()
    print('>>  Data root is %s' % str(data_root))

    # /CDShare/voxceleb1/vox1_test_wav/id10270/5r0dWxy17C8/00019.wav
    if not os.path.exists(train_dir):
        os.makedirs(train_dir)

    all_wav_path = list(data_root.glob('*/*/*/*/*/*.wav'))
    print('The number of wav file is: ', len(all_wav_path))
    dev_wav_path = []
    test_wav_path = []
    print('Dev set: ')
    for wav in all_wav_path:
        if wav.parents[3].name=='vox1_test_wav':
            test_wav_path.append(wav)
        elif wav.parents[3].name=='vox1_dev_wav':
            dev_wav_path.append(wav)

    wav_scp = []
    utt2spk = []
    pbar = tqdm(dev_wav_path)

    for wav in pbar:
        spkid = wav.parents[1].name
        utt = wav.parents[0].name
        uid = wav.name.rstrip('.wav')
        uid = '-'.join((spkid, utt, uid))
        wav_scp.append(uid + ' ' + str(wav) + '\n')
        utt2spk.append(uid + ' ' + str(spkid) + '\n')
    assert len(wav_scp)==148642, print(len(wav_scp))
    wav_scp.sort()
    utt2spk.sort()
    with open(os.path.join(train_dir, 'wav.scp'), 'w') as f1, \
         open(os.path.join(train_dir, 'utt2spk'), 'w') as f2:
        for i in range(len(utt2spk)):
            f1.write(wav_scp[i])
            f2.write(utt2spk[i])
    print('Train set preparing completed.')

    wav_scp = []
    utt2spk = []
    print('Test set: ')
    pbar = tqdm(test_wav_path)
    for wav in pbar:
        spkid = wav.parents[1].name
        utt = wav.parents[0].name
        uid = wav.name.rstrip('.wav')
        uid = '-'.join((spkid, utt, uid))
        wav_scp.append(uid + ' ' + str(wav) + '\n')
        utt2spk.append(uid + ' ' + str(spkid) + '\n')

    if len(wav_scp)==4874:
        if not os.path.exists(test_dir):
            os.makedirs(test_dir)

        wav_scp.sort()
        utt2spk.sort()
        with open(os.path.join(test_dir, 'wav.scp'), 'w') as f1, \
                open(os.path.join(test_dir, 'utt2spk'), 'w') as f2:
            for i in range(len(utt2spk)):
                f1.write(wav_scp[i])
                f2.write(utt2spk[i])

        print('Test set preparing completed.')
    else:
        print('Test set skipped!')

if __name__ == '__main__':
    data_root = args.dataset_dir
    train_dir = os.path.join(args.output_dir, 'dev')
    test_dir = os.path.join(args.output_dir, 'test')

    for i in train_dir, test_dir:
        check_path = pathlib.Path(i)
        if not check_path.parent.exists():
            print('Making dir: %s' % i)
            os.makedirs(str(check_path.parent))
            
    read_vox1_structure(data_root, train_dir, test_dir)
#
#
# train_set_path = '/home/yangwenhao/projects/data/mydataset/voxceleb/voxceleb1_wav/vox1_dev_wav/'
# test_set_path = '/home/yangwenhao/projects/data/mydataset/voxceleb/voxceleb1_wav/vox1_test_wav/'
#
# train_flist_path = os.path.join(train_set_path, 'wav.flist')
# test_flist_path = os.path.join(test_set_path, 'wav.flist')
#
# id_idname_set = prep_id_idname('data/vox1_meta.csv')
# prep_u2s_ws(train_flist_path, id_idname_set, train_dir)
# prep_u2s_ws(test_flist_path, id_idname_set, test_dir)
