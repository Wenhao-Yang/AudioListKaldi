#!/usr/bin/env bash

# """
# @Author: yangwenhao
# @Contact: 874681044@qq.com
# @Software: PyCharm
# @File: sitw.sh
# @Time: 2020/4/7 00:36 AM
# @Overview:
# """

export train_cmd="run.pl --mem 16G"
export KALDI_ROOT=/work20/yangwenhao/project/kaldi
export PATH=$PWD/utils/:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/tools/sph2pipe_v2.5:$PWD:$PATH
[ ! -f $KALDI_ROOT/tools/config/common_path.sh ] && echo >&2 "The standard file $KALDI_ROOT/tools/config/common_path.sh is not present -> Exit!" && exit 1
. $KALDI_ROOT/tools/config/common_path.sh
export LC_ALL=C

set -e

# The trials file is downloaded by local/make_voxceleb1.pl.
timit_root=/data/timit
timit_out_dir=data/timit
fbank_config=conf/fbank_64.conf

dev=${timit_out_dir}/train
test=${timit_out_dir}/test

mfccdir=${timit_out_dir}/mfcc
fbankdir=${timit_out_dir}/fbank
vaddir=${timit_out_dir}/vad

stage=0

if [ $stage -le 0 ]; then
  echo "===================================Script preparing=================================="
  # This script creates data/voxceleb1_test and data/voxceleb1_train.
  # Our evaluation set is the test portion of VoxCeleb1.
  local/make_timit.py --dataset-dir ${timit_root} --output-dir ${timit_out_dir}
  for name in ${train} ${test} ; do
    utils/fix_data_dir.sh --no-text --no-feats ${name}
  done
fi

stage=5

if [ $stage -le 1 ]; then
  # Make MFCCs and compute the energy-based VAD for each dataset
  echo "==========================Making Fbank features and VAD============================"
  for name in ${dev} ${test}; do
    steps/make_fbank.sh --write-utt2num-frames true --fbank_config ${fbank_config} --nj 12 --cmd "$train_cmd" \
    ${timit_out_dir}/${name} exp/make_fbank $fbankdir
    utils/fix_data_dir.sh ${timit_out_dir}/${name}

    sid/compute_vad_decision.sh --nj 12 --cmd "$train_cmd" ${timit_out_dir}/${name} exp/make_vad $vaddir
    utils/fix_data_dir.sh ${timit_out_dir}/${name}
  done
fi

if [ $stage -le 3 ]; then
  echo "=====================================Remove Silence========================================"
  # This script applies CMVN and removes nonspeech frames.  Note that this is somewhat
  # wasteful, as it roughly doubles the amount of training data on disk.  After
  # creating training examples, this can be removed.
  for name in ${dev} ${test}; do
    local/nnet3/xvector/prepare_feats_for_cmvn.sh --cmvns true --nj 8 --cmd "$train_cmd" ${timit_out_dir}/${name} ${timit_out_dir}/${name}_no_sil ${timit_out_dir}/${name}/feats_no_sil

    utils/fix_data_dir.sh ${timit_out_dir}/${name}_no_sil
  done

fi

if [ $stage -le 5 ]; then
  echo "================================Generate trials=================================="
  local/make_trials.py ${test}
fi