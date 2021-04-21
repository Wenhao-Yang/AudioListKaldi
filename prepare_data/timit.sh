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

stage=10

if [ $stage -le 0 ]; then
  echo "===================================Script preparing=================================="
  # This script creates data/voxceleb1_test and data/voxceleb1_train.
  # Our evaluation set is the test portion of VoxCeleb1.
  local/make_timit.py --dataset-dir ${timit_root} --output-dir ${timit_out_dir}

#  local/make_timit.py --dataset-dir ~/dataset/timit --output-dir data/timit

#python local/split_trials_dir.py --data-dir data/timit/spect/train_log \
#    --out-dir data/timit/spect/train_log/trials_dir \
#    --trials trials

  for name in ${train} ${test} ; do
    utils/validate_data_dir.sh --no-text --no-feats ${name}
    utils/fix_data_dir.sh ${name}
  done
fi

#stage=5

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

stage=10
if [ $stage -le 10 ]; then
  echo "=====================================Remove Silence========================================"
  # This script applies CMVN and removes nonspeech frames.  Note that this is somewhat
  # wasteful, as it roughly doubles the amount of training data on disk.  After
  # creating training examples, this can be removed.
#  /home/yangwenhao/local/project/lstm_speaker_verification/data/timit/spect/
  local/make_trials.py data/timit/spect/test_noc

  local/nnet3/xvector/prepare_feats_for_cmvn.sh --cmvns true --nj 12 --cmd "$train_cmd" \
    data/timit/spect/train_noc \
    data/timit/spect/dev_wcmvn \
    data/timit/spect/dev_wcmvn/feats_no_sil

  utils/fix_data_dir.sh data/timit/spect/dev_wcmvn

  local/nnet3/xvector/prepare_feats_for_cmvn.sh --cmvns true --nj 12 --cmd "$train_cmd" \
    data/timit/pyfb/train_fb24 \
    data/timit/pyfb/dev_fb24_wcmvn \
    data/timit/pyfb/dev_fb24_wcmvn/feats_no_sil

  utils/fix_data_dir.sh data/timit/pyfb/dev_fb24_wcmvn

  for name in test ; do
    local/nnet3/xvector/prepare_feats_for_cmvn.sh --cmvns true --nj 12 --cmd "$train_cmd" \
      data/timit/spect/${name}_noc \
      data/timit/spect/${name}_wcmvn \
      data/timit/spect/${name}_wcmvn/feats_no_sil

    cp data/timit/spect/${name}_noc/trials data/timit/spect/${name}_wcmvn
    utils/fix_data_dir.sh data/timit/spect/${name}_wcmvn

    local/nnet3/xvector/prepare_feats_for_cmvn.sh --cmvns true --nj 12 --cmd "$train_cmd" \
      data/timit/pyfb/${name}_fb24 \
      data/timit/pyfb/${name}_fb24_wcmvn \
      data/timit/pyfb/${name}_fb24_wcmvn/feats_no_sil

    cp data/timit/spect/${name}_noc/trials data/timit/pyfb/${name}_fb24_wcmvn
    utils/fix_data_dir.sh data/timit/pyfb/${name}_fb24_wcmvn
  done

fi
