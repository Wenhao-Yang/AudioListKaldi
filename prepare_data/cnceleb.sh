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

export KALDI_ROOT=/home/yangwenhao/local/project/kaldi
export PATH=$PWD/utils/:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/tools/sph2pipe_v2.5:$PWD:$PATH
[ ! -f $KALDI_ROOT/tools/config/common_path.sh ] && echo >&2 "The standard file $KALDI_ROOT/tools/config/common_path.sh is not present -> Exit!" && exit 1
. $KALDI_ROOT/tools/config/common_path.sh
export LC_ALL=C

set -e

# The trials file is downloaded by local/make_voxceleb1.pl.
cnceleb_root=/home/storage/yangwenhao/dataset/CN-Celeb
out_dir=data/cnceleb

dev_dir=${out_dir}/dev
test_dir=${out_dir}/test
fbank_config=conf/fbank_64.conf

# cnceleb_dev_enroll  cnceleb_dev_test  cnceleb_eval_enroll  cnceleb_eval_test
# cnceleb_test_dir=${cnceleb_out_dir}/test
# cnceleb_vad_dev_dir=${cnceleb_dev_dir}_no_sil

mfccdir=${out_dir}/mfcc
fbankdir=${out_dir}/fbank
vaddir=${out_dir}/vad

stage=0

if [ $stage -le 0 ]; then
  echo "===================================Data preparing=================================="
  # This script creates data/voxceleb1_test and data/voxceleb1_train.
  # Our evaluation set is the test portion of VoxCeleb1.
  local/make_cnceleb.py --dataset-dir ${cnceleb_root} --output-dir ${out_dir}
  cat ${out_dir}/dev/utt2dom | awk '{print $2}' | sort | uniq >${out_dir}/dev/domain

  utils/combine_data.sh ${test_dir} ${out_dir}/enroll ${out_dir}/eval

  for name in dev test ; do
    utils/fix_data_dir.sh ${out_dir}/${name}
    utils/validate_data_dir.sh --no-text --no-feats ${out_dir}/${name}
  done

  exit
fi

#stage=100
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

if [ $stage -le 4 ]; then
  echo "===============================Fix Dir========================================"
  # This script applies CMVN and removes nonspeech frames.  Note that this is somewhat
  # wasteful, as it roughly doubles the amount of training data on disk.  After
  # creating training examples, this can be removed.
  mv ${cnceleb_out_dir}/test_cmvn ${cnceleb_out_dir}/test_cmvn.back
  utils/combine_data.sh ${cnceleb_out_dir}/test_cmvn ${cnceleb_out_dir}/enroll_cmvn ${cnceleb_out_dir}/test_cmvn.back

  utils/fix_data_dir.sh ${cnceleb_out_dir}/test_cmvn
#  local/make_trials.py ${cnceleb_out_dir}/test_cmvn
fi

if [ $stage -le 5 ]; then
  echo "===============================Split trials feat in train set========================================"
  python local/split_trials_dir.py \
    --data-dir data/cnceleb/pyfb/dev_fb40_ws25 \
    --out-dir data/cnceleb/pyfb/dev_fb40_ws25/trials_dir \
    --trials trials_2w
fi

if [ $stage -le 6 ]; then
  data_dir=data/cnceleb/dev
  org_data=moives
  out_data=movie
  cat $data_dir/wav.scp | grep moives | \
    while read line; do
      l=($line)
      if [ ${#l[@]} = 2 ]; then
        # echo ${#l[@]}
        # /home/storage/yangwenhao/dataset/voxceleb2/dev/aac/id00012/21Uxsk56VDQ/00010.wav
        orig_path=${l[-1]} #/home/cca01/work2019/yangwenhao/mydataset/wav_test/noise/CHN01/D01-U000000.wav

        if [ -s ${orig_path} ]; then
          new_path=${orig_path/"$org_data"/"$out_data"}
          [ ! -d ${new_path%/*} ] && mkdir -p ${new_path%/*}
          mv ${orig_path} ${new_path}
        fi
      fi

    done
fi
if [ $stage -le 7 ]; then
  # Make Spectrogram for aug set
  dataset=cnceleb
  echo "===================              Spectrogram               ========================"
  for name in dev ; do
    steps/make_spect.sh --write-utt2num-frames true --spect-config conf/spect_161.conf \
      --nj 14 --cmd "$train_cmd" \
      data/${dataset}/klsp/${name} data/${dataset}/klsp/${name}/log data/${dataset}/klsp/spect/${name}
    utils/fix_data_dir.sh data/${dataset}/klsp/${name}
  done

  echo "===============================Split trials feat in train set========================================"
  python local/split_trials_dir.py \
    --data-dir data/${dataset}/klsp/dev \
    --out-dir data/${dataset}/klsp/dev/trials_dir \
    --trials trials_2w
    # Todo: Is there any better VAD solutioin?
#  sid/compute_vad_decision.sh --nj 12 --cmd "$train_cmd" ${vox1_org_dir}/test exp/make_vad ${vox1_org_dir}/vad
#  utils/fix_data_dir.sh ${vox1_org_dir}/test

fi