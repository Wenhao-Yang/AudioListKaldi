#!/usr/bin/env bash

stage=0

if [ $stage -le 0 ]; then
  python local/make_radio.py --dataset-dir home/yangwenhao/storage/dataset/wav_test \
    --output-dir data/radio/noise
fi

if [ $stage -le 1 ]; then
  local/resample_data_dir.sh /home/yangwenhao/storage/dataset/wav_test 8000 data/radio/noise data/radio/noise_8k
fi
