#!/bin/bash

# """
# @Author: yangwenhao
# @Contact: 874681044@qq.com
# @Software: PyCharm
# @File: voxceleb.sh
# @Time: 2020/2/22 4:33 PM
# @Overview:
# """

export train_cmd="run.pl --mem 4G"

export KALDI_ROOT=/work20/yangwenhao/project/kaldi
export PATH=$PWD/utils/:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/tools/sph2pipe_v2.5:$PWD:$PATH
[ ! -f $KALDI_ROOT/tools/config/common_path.sh ] && echo >&2 "The standard file $KALDI_ROOT/tools/config/common_path.sh is not present -> Exit!" && exit 1
. $KALDI_ROOT/tools/config/common_path.sh
export LC_ALL=C

set -e

# The trials file is downloaded by local/make_voxceleb1.pl.
vox1_root=/work20/yangwenhao/dataset/voxceleb1
vox2_root=/export/corpora/VoxCeleb2
#nnet_dir=exp/xvector_nnet_1a
#res_dir=exp/resnt
#tdnn_dir=exp/tdnn

#musan_root=/export/corpora/JHU/musan
vox1_out_dir=data/Vox1
vox1_test_dir=data/Vox1/test
vox1_train_dir=data/Vox1/dev
vox1_trials=${vox1_test_dir}/trials

mfccdir=${vox1_out_dir}/mfcc
fbankdir=${vox1_out_dir}/fbank
vaddir=${vox1_out_dir}/vad

stage=0

if [ $stage -le 0 ]; then
  echo "===================================Data preparing=================================="
  # This script creates data/voxceleb1_test and data/voxceleb1_train.
  # Our evaluation set is the test portion of VoxCeleb1.
  local/make_voxceleb1_trials.pl ${vox1_test_dir}
  local/make_voxceleb1.py ${vox1_root} ${vox1_train_dir} ${vox1_test_dir}

  utils/utt2spk_to_spk2utt.pl $vox1_train_dir/utt2spk >$vox1_train_dir/spk2utt
  utils/validate_data_dir.sh --no-text --no-feats $vox1_train_dir

  utils/utt2spk_to_spk2utt.pl $vox1_test_dir/utt2spk >$vox1_test_dir/spk2utt
  utils/validate_data_dir.sh --no-text --no-feats $vox1_test_dir


fi

if [ $stage -le 1 ]; then
  # Make MFCCs and compute the energy-based VAD for each dataset
  echo "==========================Making Fbank features and VAD============================"
  for name in ${vox1_train_dir} ${vox1_test_dir}; do
    steps/make_fbank.sh --write-utt2num-frames true --fbank_config conf/fbank.conf --nj 10 --cmd "$train_cmd" \
        ${name} exp/make_fbank $fbankdir
    utils/fix_data_dir.sh ${name}

    # Todo: Is there any better VAD solutioin?
    sid/compute_vad_decision.sh --nj 10 --cmd "$train_cmd" ${name} exp/make_vad $vaddir
    utils/fix_data_dir.sh ${name}
  done
fi