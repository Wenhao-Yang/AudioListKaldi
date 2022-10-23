#!/usr/bin/env bash

# """
# @Author: yangwenhao
# @Contact: 874681044@qq.com
# @Software: PyCharm
# @File: sitw.sh
# @Time: 2020/3/13 16:13 PM
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
# sitw_root=/work20/yangwenhao/dataset/sitw

#nnet_dir=exp/xvector_nnet_1a
#res_dir=exp/resnt
#tdnn_dir=exp/tdnn
#musan_root=/export/corpora/JHU/musan

data_dir=/home/storage/yangwenhao/dataset/AISHELL-2/iOS
out_dir=data/aishell2
fbank_config=conf/fbank_64.conf

# sitw_dev_enroll  sitw_dev_test  sitw_eval_enroll  sitw_eval_test
dev_dir=${out_dir}/dev
test_dir=${out_dir}/test
# vad_dev_dir=${sitw_dev_dir}_no_sil

mfccdir=${out_dir}/mfcc
fbankdir=${out_dir}/fbank
vaddir=${out_dir}/vad

stage=10

waited=0
while [ `ps 113458 | wc -l` -eq 2 ]; do
  sleep 60
  waited=$(expr $waited + 1)
  echo -en "\033[1;4;31m Having waited for ${waited} minutes!\033[0m\r"
done

if [ $stage -le 0 ]; then
  echo "===================================Data preparing=================================="
  # This script creates data/voxceleb1_test and data/voxceleb1_train.
  # Our evaluation set is the test portion of VoxCeleb1.
  python local/make_aishell.py --dataset-dir ${data_dir} --output-dir ${out_dir}

#python local/make_aishell.py --dataset-dir /home/work2020/yangwenhao/dataset/aishell2_8k_radio_wav_v2/iOS --output-dir data/aishell2/8k_radio_v2
#python local/make_aishell.py --dataset-dir /home/storage/yangwenhao/dataset/aishell2_8k/iOS --output-dir data/aishell2/8k --suffix 8k
#python local/make_aishell.py --dataset-dir /home/storage/yangwenhao/dataset/AISHELL-2 --output-dir data/aishell2

  for name in all dev test ; do
    utils/fix_data_dir.sh ${out_dir}/${name}
    utils/validate_data_dir.sh --no-text --no-feats ${out_dir}/${name}
  done
fi

#stage=100
if [ $stage -le 5 ]; then
  echo "=====================================Copy Compress========================================"
  # This script applies CMVN and removes nonspeech frames.  Note that this is somewhat
  # wasteful, as it roughly doubles the amount of training data on disk.  After
  # creating training examples, this can be removed.
  for name in dev ; do
    local/nnet3/xvector/prepare_feats_for_cmvn.sh --nj 32 --cmd "$train_cmd" ${out_dir}/${name} ${out_dir}/${name}_com ${out_dir}/spectrogram/${name}/
    utils/fix_data_dir.sh ${out_dir}/${name}_com
  done
fi


if [ $stage -le 1 ]; then
  # Make MFCCs and compute the energy-based VAD for each dataset
  echo "==========================Making Fbank features and VAD============================"
  for name in sitw_eval_enroll sitw_eval_test ; do
    steps/make_fbank.sh --write-utt2num-frames true --fbank_config ${fbank_config} --nj 12 --cmd "$train_cmd" \
        ${sitw_out_dir}/${name} exp/make_fbank $fbankdir
    utils/fix_data_dir.sh ${sitw_out_dir}/${name}

    sid/compute_vad_decision.sh --nj 12 --cmd "$train_cmd" ${sitw_out_dir}/${name} exp/make_vad $vaddir
    utils/fix_data_dir.sh ${sitw_out_dir}/${name}
  done
fi

if [ $stage -le 2 ]; then
  echo "=====================================CMVN========================================"
  # This script applies CMVN and removes nonspeech frames.  Note that this is somewhat
  # wasteful, as it roughly doubles the amount of training data on disk.  After
  # creating training examples, this can be removed.
  for name in sitw_dev_enroll sitw_dev_test sitw_eval_enroll sitw_eval_test ; do
    local/nnet3/xvector/prepare_feats_for_egs.sh --nj 5 --cmd "$train_cmd" ${sitw_out_dir}/${name} ${sitw_out_dir}/${name}_no_sil ${sitw_out_dir}/${name}/feats_no_sil
    utils/fix_data_dir.sh ${sitw_out_dir}/${name}_no_sil
  done
fi

if [ $stage -le 3 ]; then
  echo "=====================================VAD========================================"
  # This script applies CMVN and removes nonspeech frames.  Note that this is somewhat
  # wasteful, as it roughly doubles the amount of training data on disk.  After
  # creating training examples, this can be removed.
  for name in sitw_dev_enroll sitw_dev_test sitw_eval_enroll sitw_eval_test ; do
    local/nnet3/xvector/prepare_feats_for_cmvn.sh --cmvns true --nj 12 --cmd "$train_cmd" ${sitw_out_dir}/${name} ${sitw_out_dir}/${name}_cmvn ${sitw_out_dir}/${name}/feats_cmvn

    utils/fix_data_dir.sh ${sitw_out_dir}/${name}_cmvn
  done
fi

if [ $stage -le 4 ]; then
  utils/combine_data.sh ${sitw_out_dir}/${name} ${vox1_train_dir}_reverb ${vox1_train_dir}_noise ${vox1_train_dir}_music ${vox1_train_dir}_babble
fi

if [ $stage -le 10 ]; then
  dataset=aishell2
#  for name in dev_fb40 test_fb40 ; do # dev_aug_fb40 test_fb40
  for dim in 40 ; do # dev_aug_fb40
    for sets in test ; do # dev_aug_fb40 test_fb40
      name=${sets}_fb${dim}
      if [ ! -d data/aidata/klfb/${name} ]; then
          utils/copy_data_dir.sh data/${dataset}/${sets} data/${dataset}/klfb/${name}
        fi

      steps/make_fbank.sh --write-utt2num-frames true --fbank-config conf/fbank_${dim}.conf \
        --nj 12 --cmd "$train_cmd" \
        data/${dataset}/klfb/${name} data/${dataset}/klfb/${name}/log data/${dataset}/klfb/fbank/${name}
      utils/fix_data_dir.sh data/${dataset}/klfb/${name}
    done
  done
  exit
fi

if [ $stage -le 11 ]; then
  name=fb40
  dataset=aishell2
  feat=klfb
  python local/split_trials_dir.py --data-dir data/${dataset}/${feat}/dev_${name} \
    --out-dir data/${dataset}/${feat}/dev_${name}/trials_dir \
    --trials trials_2w
fi

#
#cp utt2spk utt2spk.bcp && cat utt2spk.bcp | awk '{print $1 "-8k-radio-v3 " $2}' > utt2spk
#cp utt2num_frames utt2num_frames.bcp && cat utt2num_frames.bcp | awk '{print $1 "-8k-radio-v3 " $2}' > utt2num_frames
#cp utt2dur utt2dur.bcp && cat utt2dur.bcp | awk '{print $1 "-8k-radio-v3 " $2}' > utt2dur
#cp feats.scp feats.scp.bcp && cat feats.scp.bcp | awk '{print $1 "-8k-radio-v3 " $2}' > feats.scp
#cp wav.scp wav.scp.bcp && cat wav.scp.bcp | awk '{print $1 "-8k-radio-v3 " $2}' > wav.scp
#
#cp feats.scp feats.scp.bcp && cat feats.scp.bcp | awk '{print $1 "-8k-radio-v3 " $2}' > feats.scp
#
#cp trials trials.bcp && cat trials.bcp | awk '{print $1 "-8k-radio-v3 " $2 "-8k-radio-v3 " $3}' > trials