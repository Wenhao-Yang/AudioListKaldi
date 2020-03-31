#!/usr/bin/env bash

# """
# @Author: yangwenhao
# @Contact: 874681044@qq.com
# @Software: PyCharm
# @File: cnceleb.sh
# @Time: 2020/3/31 12:13 PM
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
cnceleb_root=/work20/yangwenhao/dataset/CN-Celeb
cnceleb_out_dir=data/cnceleb_fb64
fbank_config=conf/fbank_64.conf

# cnceleb_dev_enroll  cnceleb_dev_test  cnceleb_eval_enroll  cnceleb_eval_test
# cnceleb_test_dir=${cnceleb_out_dir}/test
# cnceleb_vad_dev_dir=${cnceleb_dev_dir}_no_sil

mfccdir=${cnceleb_out_dir}/mfcc
fbankdir=${cnceleb_out_dir}/fbank
vaddir=${cnceleb_out_dir}/vad

stage=0

if [ $stage -le 0 ]; then
  echo "===================================Data preparing=================================="
  # This script creates data/voxceleb1_test and data/voxceleb1_train.
  # Our evaluation set is the test portion of VoxCeleb1.
  local/make_cnceleb.py --dataset-dir ${cnceleb_root} --output-dir ${cnceleb_out_dir}
  for name in dev enroll test ; do
    utils/utt2spk_to_spk2utt.pl ${cnceleb_out_dir}/${name}/utt2spk >${cnceleb_out_dir}/${name}/spk2utt
    utils/validate_data_dir.sh --no-text --no-feats ${cnceleb_out_dir}/${name}
  done
fi

if [ $stage -le 1 ]; then
  # Make MFCCs and compute the energy-based VAD for each dataset
  echo "==========================Making Fbank features and VAD============================"
  for name in dev enroll test ; do
    steps/make_fbank.sh --write-utt2num-frames true --fbank_config ${fbank_config} --nj 12 --cmd "$train_cmd" \
        ${cnceleb_out_dir}/${name} exp/make_fbank $fbankdir
    utils/fix_data_dir.sh ${cnceleb_out_dir}/${name}

    sid/compute_vad_decision.sh --nj 12 --cmd "$train_cmd" ${cnceleb_out_dir}/${name} exp/make_vad $vaddir
    utils/fix_data_dir.sh ${cnceleb_out_dir}/${name}
  done
fi

#if [ $stage -le 2 ]; then
#  echo "=====================================CMVN========================================"
#  # This script applies CMVN and removes nonspeech frames.  Note that this is somewhat
#  # wasteful, as it roughly doubles the amount of training data on disk.  After
#  # creating training examples, this can be removed.
#  for name in dev enroll test ; do
#    local/nnet3/xvector/prepare_feats_for_egs.sh --nj 5 --cmd "$train_cmd" ${cnceleb_out_dir}/${name} ${cnceleb_out_dir}/${name}_no_sil ${cnceleb_out_dir}/${name}/feats_no_sil
#    utils/fix_data_dir.sh ${cnceleb_out_dir}/${name}_no_sil
#  done
#fi

if [ $stage -le 3 ]; then
  echo "===============================Select VAD========================================"
  # This script applies CMVN and removes nonspeech frames.  Note that this is somewhat
  # wasteful, as it roughly doubles the amount of training data on disk.  After
  # creating training examples, this can be removed.
  for name in dev enroll test ; do
    local/nnet3/xvector/prepare_feats_for_cmvn.sh --cmvns true --nj 12 --cmd "$train_cmd" ${cnceleb_out_dir}/${name} ${cnceleb_out_dir}/${name}_cmvn ${cnceleb_out_dir}/${name}/feats_cmvn

    utils/fix_data_dir.sh ${cnceleb_out_dir}/${name}_cmvn
  done
fi

