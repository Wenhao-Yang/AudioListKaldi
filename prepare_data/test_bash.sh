#!/usr/bin/env bash

#loss=center
#
#if [ $loss == "center" ] ; then
#  loss_ratio=0.1
#elif [ $loss == "coscenter" ] ;then
#  loss_ratio=0.01
#fi
#
#echo $loss_ratio

python prepare_data/Split_trials_dir.py --data-dir data/army/spect/dev_8k_v2 \
  --out-dir data/army/spect/dev_8k_v2/trials_dir \
  --trials trials