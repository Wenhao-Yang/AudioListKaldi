#!/usr/bin/env bash

# """
# @Author: yangwenhao
# @Contact: 874681044@qq.com
# @Software: PyCharm
# @File: sitw.sh
# @Time: 2020/3/13 16:13 PM
# @Overview:
# """


stage=0
if [ $stage -le 0 ]; then
  ls *.tar.gz | xargs -n1 tar xzvf
fi


if [ $stage -le 5 ]; then
  python local/make_aidata.py --dataset-dir /home/work2020/yangwenhao/dataset/aidatatang_200zh/aidatatang_200zh/corpus \
    --output-dir data/aidata

  ./local/resample_data_dir.sh /home/work2020/yangwenhao/dataset/aidatatang_200zh/aidatatang_200zh/corpus/train 8000 data/aidata/train data/aidata/train_8k

  ./local/resample_data_dir.sh /home/work2020/yangwenhao/dataset/aidatatang_200zh/aidatatang_200zh/corpus/dev 8000 data/aidata/dev data/aidata/dev_8k
fi