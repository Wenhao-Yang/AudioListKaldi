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
import sys
import pdb
from multiprocessing import Pool, Manager
import time
import numpy as np
import subprocess

def RunCommand(command):
    """ Runs commands frequently seen in scripts. These are usually a
        sequence of commands connected by pipes, so we use shell=True """
    #logger.info("Running the command\n{0}".format(command))
    p = subprocess.Popen(command, shell=True,
                         stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE)

    [stdout, stderr] = p.communicate()

    return p.returncode


def SaveFromCommands(proid, task_q, error_q):

    while not task_q.empty():
        comm = task_queue.get()
        pcode = RunCommand(comm[1])

        if pcode is not 0:
            error_q.put(comm[0])

        if task_q.qsize() % 100 == 0:
            print('\rProcess [%3s] There are [%6s] utterances left, with [%6s] errors.' % (str(proid),
                                                                                           str(task_q.qsize()),
                                                                                           str(error_q.qsize())), end='')

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Conver flac to wav in sitw!')
    parser.add_argument('--nj', type=int, default=16, metavar='E',
                        help='number of jobs to make feats (default: 10)')
    parser.add_argument('--data-dir', type=str,
                        default='/home/yangwenhao/local/project/lstm_speaker_verification/data/Vox1_fb64',
                        help='number of jobs to make feats (default: 10)')
    args = parser.parse_args()

    nj = args.nj
    data_dir = args.data_dir

    # sets = ['sitw_dev_enroll', 'sitw_dev_test', 'sitw_eval_enroll', 'sitw_eval_test']
    # dev_aug  dev_babble  dev_music  dev_noise  dev_no_sil  dev_reverb
    all_convert = []
    sets = ['babble', 'music', 'noise', 'reverb']

    for s in sets:
        wav_scp_path = os.path.join(data_dir, 'dev_%s' % s, 'wav.scp')
        assert os.path.exists(wav_scp_path)

        with open(wav_scp_path, 'r') as wf:
            all_wav = wf.readlines()
            for l in all_wav:
                # id10001-7w0IBEWc9Qw-00003-music wav-reverberate --shift-output=true --additive-signals='wav-reverberate --duration=16.26 "/home/yangwenhao/local/dataset/musan/musan/music/fma-western-art/music-fma-wa-0023.wav" - |' --start-times='0' --snrs='10' /work20/yangwenhao/dataset/voxceleb1/vox1_dev_wav/wav/id10001/7w0IBEWc9Qw/00003.wav - |
                l_lst = l.split(' ')
                if s == 'reverb':
                    l_lst[-2] = l_lst[2].replace('voxceleb1', 'voxceleb1_%s' % s)
                else:
                    l_lst[-2] = l_lst[-3].replace('voxceleb1', 'voxceleb1_%s' % s)

                wav_w_path = pathlib.Path(l_lst[-2])
                uid = l_lst[0]
                comm = ' '.join(l_lst[1:-1])

                if not wav_w_path.exists():
                    all_convert.append([uid, comm])

                if not wav_w_path.parent.exists():
                    print('\rMaking dir: %s' % str(wav_w_path.parent), end='')
                    os.makedirs(str(wav_w_path.parent))

                # RunCommand(comm)

    assert os.path.exists(data_dir)
    # assert os.path.exists(wav_scp_f)
    all_convert.sort()

    num_utt = len(all_convert)
    start_time = time.time()

    # completed_queue = Queue()
    manager = Manager()
    task_queue = manager.Queue()
    error_queue = manager.Queue()

    for com in all_convert:
        task_queue.put(com)

    # processpool = []
    print('\nPlan to save augmented %d utterances in %s.' % (task_queue.qsize(), str(time.asctime())))
    # MakeFeatsProcess(out_dir, wav_scp, 0, completed_queue)

    pool = Pool(processes=nj)  # 创建nj个进程
    for i in range(0, nj):
        pool.apply_async(SaveFromCommands, args=(i, task_queue, error_queue))

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

"""
For multi threads, average making seconds for 47 speakers is 4.579958657
For one threads, average making seconds for 47 speakers is 4.11888732301

For multi process, average making seconds for 47 speakers is 1.67094940328
For one process, average making seconds for 47 speakers is 3.64203325738
"""
