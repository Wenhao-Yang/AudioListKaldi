#!/usr/bin/env python
# encoding: utf-8

"""
@Author: yangwenhao
@Contact: 874681044@qq.com
@Software: PyCharm
@File: aug2wav.py
@Time: 2020/3/14 11:26 PM
@Overview:
"""
from __future__ import print_function
import argparse
import os
import pathlib
import shutil
import sys
import pdb
from multiprocessing import Pool, Manager
import time
import numpy as np
import subprocess

from tqdm import tqdm


def RunCommand(command):
    """ Runs commands frequently seen in scripts. These are usually a
        sequence of commands connected by pipes, so we use shell=True """
    #logger.info("Running the command\n{0}".format(command))
    p = subprocess.Popen(command, shell=True,
                         stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE)

    [stdout, stderr] = p.communicate()

    return p.returncode


def SaveFromCommands(lock, proid, task_q, error_q):
    while True:
        lock.acquire()  # 加上锁
        if not task_q.empty():
            comm = task_queue.get()
            lock.release()  # 释放锁
            try:
                # print(comm[1])
                pcode = RunCommand(comm[1])
                if pcode is not 0:
                    raise Exception(comm[0])
            except:
                error_q.put(comm[0])
        else:
            lock.release()  # 释放锁
            break

        if task_q.qsize() % 100 == 0:
            print('\rProcess [%3s] There are [%6s] utterances left, with [%6s] errors.' % (str(proid),
                                                                                           str(task_q.qsize()),
                                                                                           str(error_q.qsize())), end='')

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Conver flac to wav in sitw!')
    parser.add_argument('--nj', type=int, default=16, metavar='E',
                        help='number of jobs to make feats (default: 10)')
    parser.add_argument('--dataset-dir', type=str, help='number of jobs to make feats (default: 10)')
    parser.add_argument('--outset-dir', type=str, help='number of jobs to make feats (default: 10)')

    parser.add_argument('--data-dir', type=str,
                        default='/home/yangwenhao/local/project/lstm_speaker_verification/data',
                        help='number of jobs to make feats (default: 10)')
    parser.add_argument('--suffix', type=str,
                        default='wav',
                        help='number of jobs to make feats (default: 10)')
    parser.add_argument('--set-name', type=str,
                        default='dev.4',
                        help='number of jobs to make feats (default: 10)')
    args = parser.parse_args()

    nj = args.nj
    data_dir = args.data_dir

    # sets = ['sitw_dev_enroll', 'sitw_dev_test', 'sitw_eval_enroll', 'sitw_eval_test']
    # dev_aug  dev_babble  dev_music  dev_noise  dev_no_sil  dev_reverb
    all_convert = []
    # sets = ['babble', 'music', 'noise', 'reverb', 'radio']
    sets = args.set_name.split(',')
    print('Out data dir is %s' % args.outset_dir % args.suffix)

    for s in sets:
        wav_scp_path = os.path.join(data_dir, s, 'wav.scp')

        if not os.path.exists(wav_scp_path):
            continue
        new_wav_scp_path = os.path.join(data_dir, s + '_wav', 'wav.scp')
        if not os.path.exists(os.path.join(data_dir, s + '_wav')):
            os.makedirs(os.path.join(data_dir, s + '_wav'))

        new_wf = open(new_wav_scp_path, 'w')
        with open(wav_scp_path, 'r') as wf:
            all_wav = wf.readlines()
            pbar = tqdm(all_wav)
            for l in pbar:

                # id10001-7w0IBEWc9Qw-00002-radio sox /data/voxceleb/voxceleb1_wav/vox1_dev_wav/wav/id10001/7w0IBEWc9Qw/00002.wav -r 8000 -p - | wav-reverberate --shift-output=true --additive-signals='wav-reverberate --duration=6.000062 "sox /home/cca01/work2019/yangwenhao/mydataset/wav_test/noise/CHN13/D01-U000013.wav -r 8000 -p - |" - |' --start-times='0' --snrs='10' - - |

                # id10001-7w0IBEWc9Qw-00003-music wav-reverberate --shift-output=true --additive-signals='wav-reverberate --duration=16.26 "/home/yangwenhao/local/dataset/musan/musan/music/fma-western-art/music-fma-wa-0023.wav" - |' --start-times='0' --snrs='10' /work20/yangwenhao/dataset/voxceleb1/vox1_dev_wav/wav/id10001/7w0IBEWc9Qw/00003.wav - |
                l_lst = l.split(' ')
                if 'reverb' in s or '8k' in s :
                    print(l_lst)
                    l_lst[-2] = l_lst[2].replace(args.dataset_dir,
                                                 args.outset_dir % args.suffix)
                    if '8k' in s:
                        l_lst.pop(-3)
                else:
                    # dataset_Dri ='/work20/yangwenhao/dataset/voxceleb1'
                    # outset_dir = '/work20/yangwenhao/dataset/voxceleb1_%s'
                    l_lst[-2] = l_lst[-3].replace(args.dataset_dir, args.outset_dir % args.suffix)

                wav_w_path = pathlib.Path(l_lst[-2])
                uid = l_lst[0]
                comm = ' '.join(l_lst[1:-1])
                new_wf.write(l_lst[0] + ' ' +l_lst[-2]+'\n')

                if not wav_w_path.exists():
                    all_convert.append([uid, comm])

                if not wav_w_path.parent.exists():
                    print('\rMaking dir: %s' % str(wav_w_path.parent), end='')
                    os.makedirs(str(wav_w_path.parent))

        new_wf.close()
        for scr_f in ['utt2spk', 'spk2utt', 'trials']:
            if os.path.exists(os.path.join(data_dir, s, scr_f)):
                shutil.copy(os.path.join(data_dir, s, scr_f), os.path.join(data_dir, s + '_wav', scr_f))

                # RunCommand(comm)

    assert os.path.exists(data_dir)
    # assert os.path.exists(wav_scp_f)
    all_convert.sort()

    num_utt = len(all_convert)
    start_time = time.time()

    # completed_queue = Queue()
    manager = Manager()
    lock = manager.Lock()
    task_queue = manager.Queue()
    error_queue = manager.Queue()

    for com in all_convert:
        task_queue.put(com)

    # processpool = []
    print('\nPlan to save augmented %d utterances in %s.' % (task_queue.qsize(), str(time.asctime())))
    pool = Pool(processes=nj)  # 创建nj个进程
    for i in range(0, nj):
        pool.apply_async(SaveFromCommands, args=(lock, i, task_queue, error_queue))

    pool.close()  # 关闭进程池，表示不能在往进程池中添加进程
    pool.join()  # 等待进程池中的所有进程执行完毕，必须在close()之后调用

    if error_queue.qsize()>0:
        print('\n>> Saving Completed with errors in: ')
        while not error_queue.empty():
            print(error_queue.get() + ' ', end='')
        print('')
    else:
        print('\n>> Saving Completed without errors.!')

    sys.exit()
