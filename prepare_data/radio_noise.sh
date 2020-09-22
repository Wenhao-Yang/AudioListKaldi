#!/usr/bin/env bash

stage=2

if [ $stage -le 0 ]; then
  python local/make_radio.py --dataset-dir /home/storage/yangwenhao/dataset/wav_test \
    --output-dir data/radio
fi

if [ $stage -le 1 ]; then
  for name in noise sample ;do
    local/resample_data_dir.sh wav_test 8000 data/radio/${name} data/radio/${name}_8k
  done
fi

if [ $stage -le 2 ]; then
 local/make_radio_examples.py --dataset-dir /home/work2020/yangwenhao/dataset/radio/radio_examples_8k --output-dir data/radio/example_8k

fi
