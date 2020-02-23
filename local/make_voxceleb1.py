#!/backup/liumeng/anaconda3/bin/python
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

import os
import csv
import sys
import pathlib

data_root = sys.argv[1]
train_dir = sys.argv[2]
test_dir = sys.argv[3]
for i in train_dir, test_dir:
    check_path = pathlib.Path(i)
    if not check_path.parent.exists():
        print('Making dir: %s' % i)
        os.makedirs(str(check_path.parent))

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
    print('>>Data root is %s' % str(data_root))

    # /CDShare/voxceleb1/vox1_test_wav/id10270/5r0dWxy17C8/00019.wav
    all_wav_path = list(data_root.glob('*/*/*/*.wav'))

    dev_wav_path = []
    test_wav_path = []
    for wav in all_wav_path:
        if wav.parents[2]=='vox1_test_wav':
            test_wav_path.append(wav)
        else:
            dev_wav_path.append(wav)

    wav_scp = open(os.path.join(train_dir, 'wav_scp'), 'w')
    utt2spk = open(os.path.join(train_dir, 'utt2spk'), 'w')
    for wav in dev_wav_path:
        spkid = wav.parents[1].name
        utt = wav.parents[0].name
        uid = wav.name.rstrip('.wav')
        uid = '-'.join(spkid, utt, uid)
        wav_scp.write(uid + ' ' + str(wav) + '\n')
        utt2spk.write(uid + ' ' + str(spkid) + '\n')

    wav_scp.close()
    utt2spk.close()
    print('dev set preparing completed.')

    wav_scp = open(os.path.join(test_dir, 'wav_scp'), 'w')
    utt2spk = open(os.path.join(test_dir, 'utt2spk'), 'w')
    for wav in test_wav_path:
        spkid = wav.parents[1].name
        utt = wav.parents[0].name
        uid = wav.name.rstrip('.wav')
        uid = '-'.join(spkid, utt, uid)
        wav_scp.write(uid + ' ' + str(wav) + '\n')
        utt2spk.write(uid + ' ' + str(spkid) + '\n')

    wav_scp.close()
    utt2spk.close()
    print('test set preparing completed.')

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
