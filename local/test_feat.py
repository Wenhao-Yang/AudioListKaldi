#!/usr/bin/env python
# encoding: utf-8

"""
@Author: yangwenhao
@Contact: 874681044@qq.com
@Software: PyCharm
@File: test_feat.py
@Time: 2020/6/3 11:41 PM
@Overview:
"""
import argparse
import os
import time
from multiprocessing import Pool, Manager
import kaldi_io


parser = argparse.ArgumentParser(description='Make trials for vox1')
# Data options
parser.add_argument('--data-path', type=str, default='data/aishell2/spect/dev',
                    help='path to dataset')
args = parser.parse_args()

feat_scp = args.data_path + '/feats.scp'

if not os.path.exists(feat_scp):
    raise FileExistsError(feat_scp)

def valid_load(t_queue, e_queue, cpid, lock):
    while True:
        lock.acquire()  # 加上锁
        if not t_queue.empty():
            utt = t_queue.get()
            lock.release()  # 释放锁
            try:
                kaldi_io.read_mat(utt)
            except Exception:
                e_queue.put(utt)
            print('\rProcess [%6s] There are [%6s] utterances' \
                  ' left, with [%6s] errors.' % (str(os.getpid()), str(t_queue.qsize()), str(e_queue.qsize())), end='')
        else:
            lock.release()  # 释放锁
            # print('\n>> Process {}:  queue empty!'.format(os.getpid()))
            break
    pass

if __name__ == '__main__':
    manager = Manager()
    lock = manager.Lock()
    task_queue = manager.Queue()
    error_queue = manager.Queue()
    nj=32

    uid2feat = []

    with open(feat_scp, 'r') as f:
        for l in f.readlines():
            uid2feat.append(l.split()[-1])

    for u in uid2feat:
        task_queue.put(u)
    print('Plan to valid feats for %d utterances in %s with %d jobs.\n' % (task_queue.qsize(), str(time.asctime()), nj))

    pool = Pool(processes=nj)  # 创建nj个进程
    for i in range(0, nj):
        pool.apply_async(valid_load, args=(task_queue, error_queue, i, lock))

    pool.close()  # 关闭进程池，表示不能在往进程池中添加进程
    pool.join()  # 等待进程池中的所有进程执行完毕，必须在close()之后调用

    if error_queue.qsize() > 0:
        print('\n>> valid Completed with errors in: ')
        while not error_queue.empty():
            print(error_queue.get() + ' ', end='')
        print('')
    else:
        print('\n>> valid Completed without errors.!')



