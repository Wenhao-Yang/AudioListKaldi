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
from multiprocessing import Process, Queue, Pool, Manager
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


def SaveFromCommands(comms, proid, errqueue, queue):
    for comm in comms:
        pcode = RunCommand(comm[1])
        if pcode is not 0:
            errqueue.put(comm[0])
        else:
            queue.put(comm[0])

        if queue.qsize() % 100 == 0:
            print('\rProcessed [%6s] with [%6s] errors.' % (str(queue.qsize()), str(errqueue.qsize())), end='')

    print('\n>> Process {} finished!'.format(proid))

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
                l_lst[-2] = l_lst[-3].replace('voxceleb1', 'voxceleb1_%s' % s)
                comm = ' '.join(l_lst[1:-1])
                uid = l_lst[0]

                all_convert.append([uid, comm])

                wav_w_path = pathlib.Path(l_lst[-2])
                if not wav_w_path.parent.exists():
                    os.makedirs(str(wav_w_path.parent))

                # RunCommand(comm)

    assert os.path.exists(data_dir)
    # assert os.path.exists(wav_scp_f)

    num_utt = len(all_convert)
    chunk = int(num_utt / nj)
    start_time = time.time()

    # completed_queue = Queue()
    manager = Manager()
    completed_queue = manager.Queue()
    err_queue = manager.Queue()
    # processpool = []
    print('Plan to save augmented %d utterances in %s.' % (num_utt, str(time.asctime())))
    # MakeFeatsProcess(out_dir, wav_scp, 0, completed_queue)

    pool = Pool(processes=nj)  # 创建nj个进程
    for i in range(0, nj):
        j = (i + 1) * chunk
        if i == (nj - 1):
            j = num_utt

        pool.apply_async(SaveFromCommands, args=(all_convert[i * chunk:j], i, err_queue, completed_queue))

    pool.close()  # 关闭进程池，表示不能在往进程池中添加进程
    pool.join()  # 等待进程池中的所有进程执行完毕，必须在close()之后调用
    print(' >> Saving Completed!')

    sys.exit()

"""
For multi threads, average making seconds for 47 speakers is 4.579958657
For one threads, average making seconds for 47 speakers is 4.11888732301

For multi process, average making seconds for 47 speakers is 1.67094940328
For one process, average making seconds for 47 speakers is 3.64203325738
"""