#!/usr/bin/env bash

# """
# @Author: yangwenhao
# @Contact: 874681044@qq.com
# @Software: PyCharm
# @File: sitw.sh
# @Time: 2020/3/29 16:13 PM
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
# sitw_root=/work20/yangwenhao/dataset/sitw

#nnet_dir=exp/xvector_nnet_1a
#res_dir=exp/resnt
#tdnn_dir=exp/tdnn
#musan_root=/export/corpora/JHU/musan
libri_root=/data/librispeech/LibriSpeech/dev-clean
libri_out_dir=data/libri_fb64
fbank_config=conf/fbank_64.conf

dev=dev-clean
test=test-clean

# sitw_dev_enroll  sitw_dev_test  sitw_eval_enroll  sitw_eval_test
# sitw_test_dir=${sitw_out_dir}/test
# sitw_vad_dev_dir=${sitw_dev_dir}_no_sil

mfccdir=${libri_out_dir}/mfcc
fbankdir=${libri_out_dir}/fbank
vaddir=${libri_out_dir}/vad


if [ $stage -le 0 ]; then
    echo "===================================Data preparing=================================="
    # This script creates data/voxceleb1_test and data/voxceleb1_train.
    # Our evaluation set is the test portion of VoxCeleb1.
    for name in ${dev} ${test} ; do
        local/make_librispeech.sh ${libri_root}/${name} ${libri_out_dir}/${name}

        utils/utt2spk_to_spk2utt.pl ${libri_out_dir}/${name}/utt2spk >${libri_out_dir}/${name}/spk2utt
        utils/validate_data_dir.sh --no-text --no-feats ${libri_out_dir}/${name}

        echo "`wc -l ${libri_root}/${name}/spk2utt` speakers in set ${names}"
    done

fi

if [ $stage -le 1 ]; then
    # Make MFCCs and compute the energy-based VAD for each dataset
    echo "==========================Making Fbank features and VAD============================"
    for name in ${dev} ${test} ; do
        steps/make_fbank.sh --write-utt2num-frames true --fbank_config ${fbank_config} --nj 12 --cmd "$train_cmd" \
        ${libri_out_dir}/${name} exp/make_fbank $fbankdir
        utils/fix_data_dir.sh ${libri_out_dir}/${name}
    done
fi
#stage=4
#
#if [ $stage -le 2 ]; then
#    echo "=====================================CMVN========================================"
#    # This script applies CMVN and removes nonspeech frames.  Note that this is somewhat
#    # wasteful, as it roughly doubles the amount of training data on disk.  After
#    # creating training examples, this can be removed.
#    for name in sitw_dev_enroll sitw_dev_test sitw_eval_enroll sitw_eval_test ; do
#        local/nnet3/xvector/prepare_feats_for_egs.sh --nj 5 --cmd "$train_cmd" ${sitw_out_dir}/${name} ${sitw_out_dir}/${name}_no_sil ${sitw_out_dir}/${name}/feats_no_sil
#        utils/fix_data_dir.sh ${sitw_out_dir}/${name}_no_sil
#    done
#fi

if [ $stage -le 3 ]; then
    echo "=====================================VAD========================================"
    # This script applies CMVN and removes nonspeech frames.  Note that this is somewhat
    # wasteful, as it roughly doubles the amount of training data on disk.  After
    # creating training examples, this can be removed.
    for name in ${dev} ${test} ; do
        local/nnet3/xvector/prepare_feats_for_cmvn.sh --cmvns false --nj 8 --cmd "$train_cmd" ${libri_out_dir}/${name} ${libri_out_dir}/${name}_no_cmvn ${libri_out_dir}/${name}/feats_no_cmvn

        utils/fix_data_dir.sh ${libri_out_dir}/${name}_no_cmvn
    done
fi
