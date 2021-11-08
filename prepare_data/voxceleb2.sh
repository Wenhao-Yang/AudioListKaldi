#!/bin/bash

# """
# @Author: yangwenhao
# @Contact: 874681044@qq.com
# @Software: PyCharm
# @File: voxceleb.sh
# @Time: 2020/2/22 4:33 PM
# @Overview:
# """

. ./cmd.sh
. ./path.sh
set -e

# The trials file is downloaded by local/make_voxceleb1.pl.
vox1_root=/work20/yangwenhao/dataset/voxceleb1
vox2_root=/export/corpora/VoxCeleb2
#nnet_dir=exp/xvector_nnet_1a
#res_dir=exp/resnt
#tdnn_dir=exp/tdnn

#musan_root=/export/corpora/JHU/musan
vox2_out_dir=data/Vox2_fb64
fbank_config=conf/fbank_64.conf

vox2_test_dir=${vox2_out_dir}/test
vox2_train_dir=${vox2_out_dir}/dev
vox1_trials=${vox1_test_dir}/trials

vox2_vad_train_dir=${vox2_train_dir}_no_sil
vox2_vad_test_dir=${vox2_test_dir}_no_sil

mfccdir=${vox2_out_dir}/mfcc
fbankdir=${vox2_out_dir}/fbank
vaddir=${vox2_out_dir}/vad

stage=5

if [ $stage -le 0 ]; then
  echo "===================================Data preparing=================================="
  # This script creates data/voxceleb1_test and data/voxceleb1_train.
  # Our evaluation set is the test portion of VoxCeleb1.
  # local/make_voxceleb2.pl /home/storage/yangwenhao/dataset/voxceleb2 dev data/vox2/dev
  local/make_voxceleb2.pl ${vox2_root} dev ${vox2_out_dir}/dev

  utils/utt2spk_to_spk2utt.pl ${vox2_train_dir}/utt2spk >${vox2_train_dir}/spk2utt
  utils/validate_data_dir.sh --no-text --no-feats $vox2_train_dir

  utils/utt2spk_to_spk2utt.pl ${vox2_test_dir}/utt2spk >${vox2_test_dir}/spk2utt
  utils/validate_data_dir.sh --no-text --no-feats $vox2_test_dir

fi

#stage=4
if [ $stage -le 1 ]; then
  # Make MFCCs and compute the energy-based VAD for each dataset
  echo "==========================Making Fbank features and VAD============================"
  for name in ${vox2_train_dir} ${vox2_test_dir}; do
    steps/make_fbank.sh --write-utt2num-frames true --fbank_config ${fbank_config} --nj 12 --cmd "$train_cmd" \
        ${name} exp/make_fbank $fbankdir
    utils/fix_data_dir.sh ${name}

    # Todo: Is there any better VAD solutioin?
    sid/compute_vad_decision.sh --nj 12 --cmd "$train_cmd" ${name} exp/make_vad $vaddir
    utils/fix_data_dir.sh ${name}
  done
fi

if [ $stage -le 2 ]; then
  echo "=====================================CMVN========================================"
  # This script applies CMVN and removes nonspeech frames.  Note that this is somewhat
  # wasteful, as it roughly doubles the amount of training data on disk.  After
  # creating training examples, this can be removed.

  local/nnet3/xvector/prepare_feats_for_egs.sh --nj 5 --cmd "$train_cmd" ${vox1_train_dir} ${vox1_vad_train_dir} ${vox1_train_dir}/feats_no_sil
  utils/fix_data_dir.sh ${vox1_vad_train_dir}

  local/nnet3/xvector/prepare_feats_for_egs.sh --nj 5 --cmd "$train_cmd" ${vox1_test_dir} ${vox1_vad_test_dir} ${vox1_test_dir}/feats_no_sil
  utils/fix_data_dir.sh ${vox1_vad_test_dir}

fi

if [ $stage -le 3 ]; then
  echo "=====================================make fanks========================================"
  # This script applies CMVN and removes nonspeech frames.  Note that this is somewhat
  # wasteful, as it roughly doubles the amount of training data on disk.  After
  # creating training examples, this can be removed.
  for data_dir in data/vox1/klfb/dev_fb80 data/vox1/klfb/test_fb80 ; do
    steps/make_fbank.sh --nj 12 --cmd "$train_cmd" \
     --fbank-config conf/fbank_80.conf \
     --write-utt2num-frames true \
     --write-utt2dur true \
     $data_dir
  done
  exit
fi

if [ $stage -le 4 ]; then
  # Make Spectrogram for aug set
  echo "===================              Spectrogram               ========================"
  for name in dev ; do
    steps/make_spect.sh --write-utt2num-frames true --spect-config conf/spect_161.conf \
      --nj 14 --cmd "$train_cmd" \
      data/vox2/klsp/${name} data/vox2/klsp/${name}/log data/vox2/klsp/spect/${name}
    utils/fix_data_dir.sh data/vox2/klsp/${name}
  done
    # Todo: Is there any better VAD solutioin?
#  sid/compute_vad_decision.sh --nj 12 --cmd "$train_cmd" ${vox1_org_dir}/test exp/make_vad ${vox1_org_dir}/vad
#  utils/fix_data_dir.sh ${vox1_org_dir}/test
  steps/make_fbank.sh --write-utt2num-frames true --fbank-config conf/fbank_40.conf \
      --nj 12 data/vox1/klfb/test_fb40 data/vox1/klfb/test_fb40/log data/vox1/klfb/fbank/test_fb40

fi

if [ $stage -le 5 ]; then
  # Make Spectrogram for aug set
  dataset=vox2
  echo "===================              Fbank               ========================"
  for name in dev ; do
    steps/make_fbank.sh --write-utt2num-frames true --fbank-config conf/fbank_40.conf \
      --nj 12 data/${dataset}/klfb/${name}_fb40 data/${dataset}/klfb/${name}_fb40/log data/${dataset}/klfb/fbank/${name}_fb40
  done
    # Todo: Is there any better VAD solutioin?
#  sid/compute_vad_decision.sh --nj 12 --cmd "$train_cmd" ${vox1_org_dir}/test exp/make_vad ${vox1_org_dir}/vad
#  utils/fix_data_dir.sh ${vox1_org_dir}/test


fi

