#!/usr/bin/env bash

stage=1

if [ $stage -le 0 ]; then
  python local/make_radio.py --dataset-dir /home/storage/yangwenhao/dataset/wav_test \
    --output-dir data/radio
fi

if [ $stage -le 1 ]; then
  for name in noise, sample ;do
    local/resample_data_dir.sh /home/yangwenhao/storage/dataset/wav_test 8000 data/radio/${name} data/radio/${name}_8k
  done
fi
