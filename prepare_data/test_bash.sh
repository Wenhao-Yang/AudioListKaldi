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

#
#python prepare_data/split_trials_dir.py --data-dir data/army/spect/dev_8k_v2 \
#  --out-dir data/army/spect/dev_8k_v2/trials_dir \
#  --trials trials

#python prepare_data/split_trials_dir.py --data-dir data/vox1/pyfb/dev_fb64 \
#  --out-dir data/vox1/pyfb/dev_fb64/trials_dir \
#  --trials trials_2w

#for name in kaldi pitch; do
#  python prepare_data/Split_trials_dir.py --data-dir data/vox1/pyfb/dev_fb24_${name} \
#  --out-dir data/vox1/pyfb/dev_fb24_${name}/trials_dir \
#  --trials trials_2w
#done

stage=40
if [ $stage -le 40 ]; then
  dataset=vox1
  name=fb40
  python local/split_trials_dir.py --data-dir data/${dataset}/pyfb/dev_${name} \
    --out-dir data/${dataset}/pyfb/dev_${name}/trials_dir \
    --trials trials_2w
fi