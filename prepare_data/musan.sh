#!/usr/bin/env bash

# author: yangwenhao
# contact: 874681044@qq.com
# file: musan.sh
# time: 2021/9/10 19:42
# Description:

. ./cmd.sh
. ./path.sh
set -e

stage=1
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

if [ $stage -le 1 ]; then
  name=fb40
  dataset=musan
  feat=klfb

  for name in music_fb40 noise_fb40 ; do # dev_aug_fb40
    steps/make_fbank.sh --write-utt2num-frames true --fbank-config conf/fbank_40.conf \
      --nj 14 --cmd "$train_cmd" \
      data/${dataset}/klfb/${name} data/${dataset}/klfb/${name}/log data/${dataset}/klfb/fbank/${name}
    utils/fix_data_dir.sh data/${dataset}/klfb/${name}
  done

#  for s in music noise; do
#    python local/split_trials_dir.py --data-dir data/${dataset}/${feat}/dev_${name} \
#      --out-dir data/${dataset}/${feat}/dev_${name}/trials_dir \
#      --trials trials_2w
#  done
fi