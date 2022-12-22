#!/bin/bash

# """
# @Author: yangwenhao
# @Contact: 874681044@qq.com
# @Software: VS Code
# @File: magic.sh
# @Time: 2022/12/22 12:22 AM
# @Overview:
# """

. ./cmd.sh
. ./path.sh
set -e

dataset=magic
stage=0

if [ $stage -le 0 ]; then
  # Make Spectrogram for aug set
  echo "===================              Spectrogram               ========================"
  for name in test ; do
    steps/make_spect.sh --write-utt2num-frames true --spect-config conf/spect_161.conf \
      --nj 14 --cmd "$train_cmd" \
      data/${dataset}/klsp/${name} data/${dataset}/klsp/${name}/log data/${dataset}/klsp/spect/${name}
    utils/fix_data_dir.sh data/${dataset}/klsp/${name}
  done
    # Todo: Is there any better VAD solutioin?
#  sid/compute_vad_decision.sh --nj 12 --cmd "$train_cmd" ${vox1_org_dir}/test exp/make_vad ${vox1_org_dir}/vad
#  utils/fix_data_dir.sh ${vox1_org_dir}/test
#   steps/make_fbank.sh --write-utt2num-frames true --fbank-config conf/fbank_40.conf \
#       --nj 12 data/vox1/klfb/test_fb40 data/vox1/klfb/test_fb40/log data/vox1/klfb/fbank/test_fb40

fi