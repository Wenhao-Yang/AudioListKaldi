#!/usr/bin/env bash
# Copyright   2017   Johns Hopkins University (Author: Daniel Garcia-Romero)
#             2017   Johns Hopkins University (Author: Daniel Povey)
#        2017-2018   David Snyder
#             2018   Ewald Enzinger
# Apache 2.0.
#
# See ../README.txt for more info on data required.
# Results (mostly equal error-rates) are inline in comments below.

#. ./cmd.sh
export train_cmd="run.pl --mem 4G"

#. ./path.sh
export KALDI_ROOT=/home/hdd2020/yangwenhao/project/kaldi
export PATH=$PWD/utils/:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/tools/sph2pipe_v2.5:$PWD:$PATH
[ ! -f $KALDI_ROOT/tools/config/common_path.sh ] && echo >&2 "The standard file $KALDI_ROOT/tools/config/common_path.sh is not present -> Exit!" && exit 1
. $KALDI_ROOT/tools/config/common_path.sh
export LC_ALL=C

set -e
mfccdir=`pwd`/data/CN-Celeb/fbank
vaddir=`pwd`/data/CN-Celeb/vad

# The trials file is downloaded by local/make_voxceleb1_v2.pl.
#voxceleb1_trials=data/voxceleb1_test/trials
#voxceleb1_root=/export/corpora/VoxCeleb1
#voxceleb2_root=/export/corpora/VoxCeleb2

stage=0

if [ $stage -le 0 ]; then
#  local/make_voxceleb2.pl $voxceleb2_root dev data/voxceleb2_train
#  local/make_voxceleb2.pl $voxceleb2_root test data/voxceleb2_test
#  # This script creates data/voxceleb1_test and data/voxceleb1_train for latest version of VoxCeleb1.
#  # Our evaluation set is the test portion of VoxCeleb1.
#  local/make_voxceleb1_v2.pl $voxceleb1_root dev data/voxceleb1_train
#  local/make_voxceleb1_v2.pl $voxceleb1_root test data/voxceleb1_test
#  # if you downloaded the dataset soon after it was released, you will want to use the make_voxceleb1.pl script instead.
#  # local/make_voxceleb1.pl $voxceleb1_root data
#  # We'll train on all of VoxCeleb2, plus the training portion of VoxCeleb1.
#  # This should give 7,323 speakers and 1,276,888 utterances.
#  utils/combine_data.sh data/train data/voxceleb2_train data/voxceleb2_test data/voxceleb1_train
    utils/utt2spk_to_spk2utt.pl data/CN-Celeb/dev/utt2spk >data/CN-Celeb/dev/spk2utt
    utils/utt2spk_to_spk2utt.pl data/CN-Celeb/enroll/utt2spk >data/CN-Celeb/enroll/spk2utt
    utils/utt2spk_to_spk2utt.pl data/CN-Celeb/test/utt2spk >data/CN-Celeb/test/spk2utt
fi

if [ $stage -le 1 ]; then
    # Make MFCCs and compute the energy-based VAD for each dataset
#    steps/make_fbank.sh --write-utt2num-frames true --fbank_config conf/fbank.conf --nj 4 --cmd "$train_cmd" \
#        data/CN-Celeb/dev exp/make_fb40 $fbankdir
#    utils/fix_data_dir.sh data/CN-Celeb/dev
#
#    sid/compute_vad_decision.sh --nj 4 --cmd "$train_cmd" data/CN-Celeb/dev exp/make_fb40 $vaddir
#    utils/fix_data_dir.sh data/CN-Celeb/dev
#
#    steps/make_fbank.sh --write-utt2num-frames true --fbank_config conf/fbank.conf --nj 4 --cmd "$train_cmd" \
#        data/CN-Celeb/enroll exp/make_fb40 $fbankdir
#    utils/fix_data_dir.sh data/CN-Celeb/enroll
#
#    sid/compute_vad_decision.sh --nj 4 --cmd "$train_cmd" data/CN-Celeb/enroll exp/make_fb40 $vaddir
#    utils/fix_data_dir.sh data/CN-Celeb/enroll

    # steps/make_fbank.sh --write-utt2num-frames true --fbank_config conf/fbank.conf --nj 4 --cmd "$train_cmd" \
    #     data/CN-Celeb/test exp/make_fb40 $fbankdir
    # utils/fix_data_dir.sh data/CN-Celeb/test

    # sid/compute_vad_decision.sh --nj 4 --cmd "$train_cmd" data/CN-Celeb/test exp/make_fb40 $vaddir
    # utils/fix_data_dir.sh data/CN-Celeb/test
    echo 'skip'

fi

if [ $stage -le 2 ]; then
  echo "=====================================CMVN========================================"
  # This script applies CMVN and removes nonspeech frames.  Note that this is somewhat
  # wasteful, as it roughly doubles the amount of training data on disk.  After
  # creating training examples, this can be removed.

  local/nnet3/xvector/prepare_feats_for_egs.sh --nj 4 --cmd "$train_cmd" data/CN-Celeb/dev data/CN-Celeb/dev_no_sli data/CN-Celeb/dev/feats_no_sil
  utils/fix_data_dir.sh data/CN-Celeb/dev_no_sli

  # This script applies CMVN and removes nonspeech frames.  Note that this is somewhat
  # wasteful, as it roughly doubles the amount of training data on disk.  After
  # creating training examples, this can be removed.
  local/nnet3/xvector/prepare_feats_for_egs.sh --nj 4 --cmd "$train_cmd" data/CN-Celeb/test data/CN-Celeb/test_no_sli data/CN-Celeb/test/feats_no_sil
  utils/fix_data_dir.sh data/CN-Celeb/test_no_sli
fi



