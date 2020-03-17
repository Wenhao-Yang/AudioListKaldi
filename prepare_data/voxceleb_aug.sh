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
subsets=music
vox1_root=/work20/yangwenhao/dataset/voxceleb1_${subsets}
vox2_root=/export/corpora/VoxCeleb2

# The trials file is downloaded by local/make_voxceleb1.pl.
musan_root=/home/yangwenhao/local/dataset/musan/musan
rirs_root=/home/yangwenhao/local/dataset/rirs/RIRS_NOISES

#musan_root=/export/corpora/JHU/musan
vox1_out_dir=data/Vox1_${subsets}_fb64

fbank_config=conf/fbank_64.conf

vox1_test_dir=${vox1_out_dir}/test
vox1_train_dir=${vox1_out_dir}/dev
vox1_trials=${vox1_test_dir}/trials

vox1_vad_train_dir=${vox1_train_dir}_no_sil
vox1_vad_test_dir=${vox1_test_dir}_no_sil
vox1_rev_train_dir=${vox1_train_dir}_reverb

mfccdir=${vox1_out_dir}/mfcc
fbankdir=${vox1_out_dir}/fbank
vaddir=${vox1_out_dir}/vad

stage=0

if [ $stage -le 0 ]; then
  echo "===================================Data preparing=================================="
  # This script creates data/voxceleb1_test and data/voxceleb1_train.
  # Our evaluation set is the test portion of VoxCeleb1.
#  local/make_voxceleb1_trials.pl ${vox1_root} ${vox1_out_dir}
  local/make_voxceleb1.py ${vox1_root} ${vox1_train_dir} ${vox1_test_dir}

  cp data/Vox1_fb64/dev/vad.scp ${vox1_train_dir}/vad.scp
  utils/utt2spk_to_spk2utt.pl ${vox1_train_dir}/utt2spk >${vox1_train_dir}/spk2utt

  utils/copy_data_dir.sh --utt-suffix "-${subsets}" ${vox1_train_dir} ${vox1_train_dir}.new
  rm -rf ${vox1_train_dir}
  mv ${vox1_train_dir}.new ${vox1_train_dir}

  utils/validate_data_dir.sh --no-text --no-feats ${vox1_train_dir}

fi

if [ $stage -le 1 ]; then
  # Make MFCCs and compute the energy-based VAD for each dataset
  echo "==========================Making Fbank features and VAD============================"

  steps/make_fbank.sh --write-utt2num-frames true --fbank_config ${fbank_config} --nj 12 --cmd "$train_cmd" \
        ${vox1_train_dir} exp/make_fbank $fbankdir
  utils/fix_data_dir.sh ${vox1_train_dir}

    # Todo: Is there any better VAD solutioin?
  sid/compute_vad_decision.sh --nj 12 --cmd "$train_cmd" ${vox1_train_dir} exp/make_vad $vaddir
  utils/fix_data_dir.sh ${vox1_train_dir}

fi

if [ $stage -le 4 ]; then
  echo "=====================================CMVN========================================"
  # This script applies CMVN and removes nonspeech frames.  Note that this is somewhat
  # wasteful, as it roughly doubles the amount of training data on disk.  After
  # creating training examples, this can be removed.

  local/nnet3/xvector/prepare_feats_for_egs.sh --nj 5 --cmd "$train_cmd" ${vox1_train_dir} ${vox1_vad_train_dir} ${vox1_train_dir}/feats_no_sil
  utils/fix_data_dir.sh ${vox1_vad_train_dir}

fi

exit 0;