#!/usr/bin/env bash

# author: yangwenhao
# contact: 874681044@qq.com
# file: musan.sh
# time: 2021/9/10 19:42
# Description:

. ./cmd.sh
. ./path.sh
set -e

stage=0
dataset=musan

if [ $stage -le 0 ]; then
  # Make Spectrogram for aug set
  echo "===================              Spectrogram               ========================"
  for name in musan_music musan_noise musan_speech; do
    steps/make_spect.sh --write-utt2num-frames true --spect-config conf/spect_161.conf \
      --nj 14 --cmd "$train_cmd" \
      data/${dataset}/klsp/${name} data/${dataset}/klsp/${name}/log data/${dataset}/klsp/spect/${name}
    utils/fix_data_dir.sh data/${dataset}/klsp/${name}
  done

fi
