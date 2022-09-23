#!/usr/bin/env bash

# """
# @Author: yangwenhao
# @Contact: 874681044@qq.com
# @Software: PyCharm
# @File: sitw.sh
# @Time: 2020/3/13 16:13 PM
# @Overview:
# """


stage=10
if [ $stage -le 0 ]; then
  ls *.tar.gz | xargs -n1 tar xzvf
fi


if [ $stage -le 5 ]; then
  python local/make_aidata.py --dataset-dir /home/work2020/yangwenhao/dataset/aidatatang_200zh/aidatatang_200zh/corpus \
    --output-dir data/aidata

  ./local/resample_data_dir.sh /home/work2020/yangwenhao/dataset/aidatatang_200zh/aidatatang_200zh/corpus/train 8000 data/aidata/train data/aidata/train_8k

  ./local/resample_data_dir.sh /home/work2020/yangwenhao/dataset/aidatatang_200zh/aidatatang_200zh/corpus/dev 8000 data/aidata/dev data/aidata/dev_8k
fi


if [ $stage -le 10 ]; then

  for dim in 40 ; do # dev_aug_fb40
    for sets in train; do
      name=${sets}_fb${dim}
      if [ ! -d data/aidata/klfb/${name} ]; then
        utils/copy_data_dir.sh data/aidata/${sets} data/aidata/klfb/${name}
      fi
      steps/make_fbank.sh --write-utt2num-frames true --fbank-config conf/fbank_${dim}.conf \
        --nj 14 --cmd "$train_cmd" \
        data/aidata/klfb/${name} data/aidata/klfb/${name}/log data/aidata/klfb/fbank/${name}
      utils/fix_data_dir.sh data/aidata/klfb/${name}
  done
  done

  exit

# steps/make_fbank.sh --write-utt2num-frames true --fbank-config conf/fbank_40.conf \
#       --nj 12 data/vox1/klfb/test_fb40 data/vox1/klfb/test_fb40/log data/vox1/klfb/fbank/test_fb40
fi