#!/usr/bin/env python
# encoding: utf-8

"""
@Author: yangwenhao
@Contact: 874681044@qq.com
@Software: PyCharm
@File: check_data_dir.py
@Time: 2020/11/11 16:57
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
import soundfile as sf
from tqdm import tqdm

parser = argparse.ArgumentParser(description='Conver flac to wav in sitw!')
parser.add_argument('--nj', type=int, default=16, metavar='E',
                    help='number of jobs to make feats (default: 10)')
parser.add_argument('--dataset-dir', type=str, help='number of jobs to make feats (default: 10)')
parser.add_argument('--outset-dir', type=str, help='number of jobs to make feats (default: 10)')

parser.add_argument('--data-dir', type=str,
                    default='/home/yangwenhao/local/project/lstm_speaker_verification/data',
                    help='number of jobs to make feats (default: 10)')
parser.add_argument('--suffix', type=str, default='wav',
                    help='number of jobs to make feats (default: 10)')
parser.add_argument('--set-name', type=str, default='dev.4',
                    help='number of jobs to make feats (default: 10)')
args = parser.parse_args()


def LoadWavFiles(lock, proid, task_q, error_q):
    while True:
        lock.acquire()  # 加上锁
        if not task_q.empty():
            comm = task_queue.get()
            lock.release()  # 释放锁
            try:
                uid, upath = comm
                samples, samplerate = sf.read(upath, dtype='int16')
                if not len(samples)>0:
                    raise Exception(uid)
            except:
                error_q.put(comm[1])
        else:
            lock.release()  # 释放锁
            break

        if task_q.qsize() % 100 == 0:
            print('\rProcess [%3s] There are [%6s] utterances left, with [%6s] errors.' % (str(proid),
                                                                                           str(task_q.qsize()),
                                                                                           str(error_q.qsize())), end='')

if __name__ == "__main__":

    nj = args.nj
    data_dir = args.data_dir
    assert os.path.exists(data_dir)

    wav_scp_path = os.path.join(data_dir, 'wav.scp')
    assert os.path.exists(wav_scp_path)

    all_wav = []
    with open(wav_scp_path, 'r') as f:
        for l in f.readlines():
            uid, upath = l.split()
            all_wav.append((uid, upath))

    num_utt = len(all_wav)
    start_time = time.time()

    # completed_queue = Queue()
    manager = Manager()
    lock = manager.Lock()
    task_queue = manager.Queue()
    error_queue = manager.Queue()

    for com in all_wav:
        task_queue.put(com)

    # processpool = []
    print('\nPlan to check %d utterances in %s.' % (task_queue.qsize(), str(time.asctime())))
    pool = Pool(processes=nj)  # 创建nj个进程
    for i in range(0, nj):
        pool.apply_async(LoadWavFiles, args=(lock, i, task_queue, error_queue))

    pool.close()  # 关闭进程池，表示不能在往进程池中添加进程
    pool.join()  # 等待进程池中的所有进程执行完毕，必须在close()之后调用

    if error_queue.qsize()>0:
        print('\n>> Completed with errors in: ')
        while not error_queue.empty():
            print(error_queue.get() + ' ', end='')
        print('')
    else:
        print('\n>> Completed without errors.!')

    sys.exit()
