#!/bin/bash

# """
# @Author: yangwenhao
# @Contact: 874681044@qq.com
# @Software: PyCharm
# @File: voxceleb.sh
# @Time: 2020/2/22 4:33 PM
# @Overview:
# """

export train_cmd="run.pl --mem 16G"

./path.sh

set -e

# The trials file is downloaded by local/make_voxceleb1.pl.
# dev_babble  dev_music  dev_noise dev_reverb
subsets=reverb
vox1_root=/work20/yangwenhao/dataset/voxceleb1_${subsets}
vox2_root=/export/corpora/VoxCeleb2

# The trials file is downloaded by local/make_voxceleb1.pl.
musan_root=/home/yangwenhao/local/dataset/musan/musan
rirs_root=/home/yangwenhao/local/dataset/rirs/RIRS_NOISES

#musan_root=/export/corpora/JHU/musan

vox1_org_dir=data/Vox1_fb64
vox1_bab_dir=data/Vox1_babble_fb64
vox1_noi_dir=data/Vox1_noise_fb64
vox1_mus_dir=data/Vox1_music_fb64
vox1_aug_dir=data/Vox1_aug_fb64

fbank_config=conf/fbank_64.conf

#vox1_test_dir=${vox1_out_dir}/test
#vox1_train_dir=${vox1_out_dir}/dev
#vox1_trials=${vox1_test_dir}/trials
#
#vox1_vad_train_dir=${vox1_train_dir}_no_sil
#vox1_vad_test_dir=${vox1_test_dir}_no_sil
#vox1_rev_train_dir=${vox1_train_dir}_reverb
#
#mfccdir=${vox1_out_dir}/mfcc
#fbankdir=${vox1_out_dir}/fbank
#vaddir=${vox1_out_dir}/vad

stage=4

if [ $stage -le 0 ]; then
  echo "===================================Data preparing=================================="
  # This script creates data/voxceleb1_test and data/voxceleb1_train.
  # Our evaluation set is the test portion of VoxCeleb1.
#  local/make_voxceleb1_trials.pl ${vox1_root} ${vox1_out_dir}
  local/make_voxceleb1.py ${vox1_root} ${vox1_org_dir}/dev ${vox1_org_dir}/test

#  cp ${vox1_org_dir}/dev/vad.scp ${vox1_train_dir}/vad.scp
  utils/utt2spk_to_spk2utt.pl ${vox1_org_dir}/dev/utt2spk >${vox1_org_dir}/dev/spk2utt

  utils/copy_data_dir.sh --utt-suffix "-${subsets}" ${vox1_org_dir}/dev ${vox1_org_dir}/dev.new
  rm -rf ${vox1_org_dir}/dev
  mv ${vox1_org_dir}/dev.new ${vox1_org_dir}/dev

  utils/validate_data_dir.sh --no-text --no-feats ${vox1_org_dir}/dev

fi

if [ $stage -le 1 ]; then
  # Make MFCCs and compute the energy-based VAD for each dataset
  echo "==========================Making Fbank features and VAD============================"

  steps/make_fbank.sh --write-utt2num-frames true --fbank_config ${fbank_config} --nj 12 --cmd "$train_cmd" \
        ${vox1_org_dir}/dev exp/make_fbank ${vox1_org_dir}/fbank
  utils/fix_data_dir.sh ${vox1_org_dir}/dev

    # Todo: Is there any better VAD solutioin?
  sid/compute_vad_decision.sh --nj 12 --cmd "$train_cmd" ${vox1_org_dir}/dev exp/make_vad ${vox1_org_dir}/vad
  utils/fix_data_dir.sh ${vox1_org_dir}/dev

fi


if [ $stage -le 4 ]; then
  echo "=====================================CMVN========================================"
  # This script applies CMVN and removes nonspeech frames.  Note that this is somewhat
  # wasteful, as it roughly doubles the amount of training data on disk.  After
  # creating training examples, this can be removed.
  # data/Vox1_fb64/dev_no_sil;       data/Vox1_babble_fb64/dev_no_sil
  # data/Vox1_noise_fb64/dev_no_sil  data/Vox1_music_fb64/dev_no_sil:
  # data/Vox1_reverb_fb64/dev_no_sil
  for name in ${vox1_org_dir} ${vox1_bab_dir} ${vox1_noi_dir} ${vox1_mus_dir} ${vox1_aug_dir}; do
    local/nnet3/xvector/prepare_feats_for_cmvn.sh --cmvns false --nj 8 --cmd "$train_cmd" ${name}/dev ${name}/dev_no_sil ${name}/dev/feats_no_sil
    utils/fix_data_dir.sh ${name}/dev_no_sil
  done

  local/nnet3/xvector/prepare_feats_for_cmvn.sh --cmvns false --nj 8 --cmd "$train_cmd" ${vox1_org_dir}/test ${vox1_org_dir}/test ${vox1_org_dir}/test/feats_no_sil
  utils/fix_data_dir.sh ${vox1_org_dir}/test_no_sil

fi

if [ $stage -le 5 ]; then
  echo "================================Combining subsets=================================="
  # This script applies CMVN and removes nonspeech frames.  Note that this is somewhat
  # wasteful, as it roughly doubles the amount of training data on disk.  After
  # creating training examples, this can be removed.

  utils/combine_data.sh data/Vox1_aug_fb64/dev_no_sil data/Vox1_fb64/dev_no_sil data/Vox1_babble_fb64/dev_no_sil data/Vox1_noise_fb64/dev_no_sil data/Vox1_music_fb64/dev_no_sil data/Vox1_reverb_fb64/dev_no_sil

  utils/fix_data_dir.sh data/Vox1_aug_fb64/dev_no_sil

fi
exit 0;