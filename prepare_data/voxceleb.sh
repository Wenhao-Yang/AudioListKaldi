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

export KALDI_ROOT=/home/yangwenhao/local/project/kaldi
export PATH=$PWD/utils/:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/tools/sph2pipe_v2.5:$PWD:$PATH
[ ! -f $KALDI_ROOT/tools/config/common_path.sh ] && echo >&2 "The standard file $KALDI_ROOT/tools/config/common_path.sh is not present -> Exit!" && exit 1
. $KALDI_ROOT/tools/config/common_path.sh
export LC_ALL=C

set -e

# The trials file is downloaded by local/make_voxceleb1.pl.
vox1_root=/home/storage/yangwenhao/dataset/voxceleb1
vox2_root=/home/storage/yangwenhao/dataset/voxceleb2

# The trials file is downloaded by local/make_voxceleb1.pl.
musan_root=/home/yangwenhao/local/dataset/musan/musan
rirs_root=/home/yangwenhao/local/dataset/rirs/RIRS_NOISES
#nnet_dir=exp/xvector_nnet_1a
#res_dir=exp/resnt
#tdnn_dir=exp/tdnn

#musan_root=/export/corpora/JHU/musan
vox1_out_dir=data/vox1
musan_out_dir=data/musan

fbank_config=conf/fbank_24.conf
process_pitch_conf=conf/process_pitch.conf

vox1_train_dir=${vox1_out_dir}/dev
vox1_test_dir=${vox1_out_dir}/test
vox1_trials=${vox1_test_dir}/trials

vox1_vad_train_dir=${vox1_train_dir}_no_sil
vox1_vad_test_dir=${vox1_test_dir}_no_sil
vox1_rev_train_dir=${vox1_train_dir}_reverb

mfccdir=${vox1_out_dir}/mfcc
fbankdir=${vox1_out_dir}/fbank
vaddir=${vox1_out_dir}/vad

stage=61

if [ $stage -le 0 ]; then
  echo "===================================Data preparing=================================="
  # This script creates data/voxceleb1_test and data/voxceleb1_train.
  # Our evaluation set is the test portion of VoxCeleb1.
  local/make_voxceleb1_trials.pl ${vox1_root} ${vox1_out_dir}
  local/make_voxceleb1.py --dataset-dir ${vox1_root} --output-dir ${vox1_out_dir}

  utils/fix_data_dir.sh ${vox1_train_dir}
  utils/validate_data_dir.sh --no-text --no-feats $vox1_train_dir

  utils/fix_data_dir.pl ${vox1_test_dir}
  utils/validate_data_dir.sh --no-text --no-feats $vox1_test_dir

fi

#stage=100
if [ $stage -le 1 ]; then
  # Make MFCCs and compute the energy-based VAD for each dataset
  echo "==========================Making Fbank features and VAD============================"
  for name in ${vox1_train_dir} ${vox1_test_dir}; do
    steps/make_fbank.sh --write-utt2num-frames true --fbank_config ${fbank_config} --nj 12 --cmd "$train_cmd" \
        ${name} exp/make_fbank $fbankdir
    utils/fix_data_dir.sh ${name}

    # Todo: Is there any better VAD solutioin?
    sid/compute_vad_decision.sh --nj 12 --cmd "$train_cmd" ${name} exp/make_vad $vaddir
    utils/fix_data_dir.sh ${name}
  done


fi

if [ $stage -le 1 ]; then
  # Make MFCCs and compute the energy-based VAD for each dataset
  echo "==========================Making Fbank with Pitch features and VAD============================"
  dev_fb24_pitch_dir=data/vox1/pyfb/dev_fb24_pitch
  test_fb24_pitch_dir=data/vox1/pyfb/test_fb24_pitch
  utils/copy_data_dir.sh ${vox1_train_dir} $dev_fb24_pitch_dir
  utils/copy_data_dir.sh ${vox1_test_dir} $test_fb24_pitch_dir

  for name in ${dev_fb24_pitch_dir} ${test_fb24_pitch_dir}; do
    steps/make_fbank_pitch.sh --write-utt2num-frames true --fbank_config ${fbank_config} \
    --pitch_postprocess_config ${process_pitch_conf} --nj 12 --cmd "$train_cmd" \
        ${name}
    utils/fix_data_dir.sh ${name}

    # Todo: Is there any better VAD solutioin?
#    sid/compute_vad_decision.sh --nj 12 --cmd "$train_cmd" ${name} exp/make_vad $vaddir
#    utils/fix_data_dir.sh ${name}
  done
fi

if [ $stage -le 2 ]; then
  # Make MFCCs and compute the energy-based VAD for each dataset
  echo "==========================Making Fbank with Pitch features and VAD============================"
  dev_fb24_dir=data/vox1/pyfb/dev_fb24_kaldi
  test_fb24_dir=data/vox1/pyfb/test_fb24_kaldi
  utils/copy_data_dir.sh ${vox1_train_dir} $dev_fb24_dir
  utils/copy_data_dir.sh ${vox1_test_dir} $test_fb24_dir

  for name in ${dev_fb24_dir} ${test_fb24_dir}; do
    steps/make_fbank.sh --write-utt2num-frames true --fbank_config ${fbank_config} \
        --nj 12 --cmd "$train_cmd" \
        ${name}
    utils/fix_data_dir.sh ${name}

    # Todo: Is there any better VAD solutioin?
#    sid/compute_vad_decision.sh --nj 12 --cmd "$train_cmd" ${name} exp/make_vad $vaddir
#    utils/fix_data_dir.sh ${name}
  done
fi

#stage=100
if [ $stage -le 2 ]; then
  echo "===================================RIRS Reverb Aug=================================="

  frame_shift=0.01
  awk -v frame_shift=$frame_shift '{print $1, $2*frame_shift;}' ${vox1_train_dir}/utt2num_frames > ${vox1_train_dir}/reco2dur

  # Make a version with reverberated speech
  rvb_opts=()
  rvb_opts+=(--rir-set-parameters "0.5, ${rirs_root}/simulated_rirs/smallroom/zg_rir_list")
  rvb_opts+=(--rir-set-parameters "0.5, ${rirs_root}/simulated_rirs/mediumroom/zg_rir_list")

  # Make a reverberated version of the VoxCeleb2 list.  Note that we don't add any
  # additive noise here.
  steps/data/reverberate_data_dir.py \
    "${rvb_opts[@]}" \
    --speech-rvb-probability 1 \
    --pointsource-noise-addition-probability 0 \
    --isotropic-noise-addition-probability 0 \
    --num-replications 1 \
    --source-sampling-rate 16000 \
    ${vox1_train_dir} ${vox1_rev_train_dir}

  cp ${vox1_train_dir}/vad.scp ${vox1_rev_train_dir}/
  utils/copy_data_dir.sh --utt-suffix "-reverb" ${vox1_rev_train_dir} ${vox1_rev_train_dir}.new
  rm -rf ${vox1_rev_train_dir}
  mv ${vox1_rev_train_dir}.new ${vox1_rev_train_dir}

fi

if [ $stage -le 3 ]; then
  echo "===================================Musan Aug=================================="
    # Prepare the MUSAN corpus, which consists of music, speech, and noise
  # suitable for augmentation.
  steps/data/make_musan.sh --sampling-rate 16000 $musan_root ${musan_out_dir}

  # Get the duration of the MUSAN recordings.  This will be used by the
  # script augment_data_dir.py.
  for name in speech noise music; do
    utils/data/get_utt2dur.sh ${musan_out_dir}/musan_${name}
    mv ${musan_out_dir}/musan_${name}/utt2dur ${musan_out_dir}/musan_${name}/reco2dur
  done
  # Augment with musan_noise
  steps/data/augment_data_dir.py --utt-suffix "noise" --fg-interval 1 --fg-snrs "15:10:5:0" --fg-noise-dir "${musan_out_dir}/musan_noise" ${vox1_train_dir} ${vox1_train_dir}_noise
  # Augment with musan_music
  steps/data/augment_data_dir.py --utt-suffix "music" --bg-snrs "15:10:8:5" --num-bg-noises "1" --bg-noise-dir "${musan_out_dir}/musan_music" ${vox1_train_dir} ${vox1_train_dir}_music
  # Augment with musan_speech
  steps/data/augment_data_dir.py --utt-suffix "babble" --bg-snrs "20:17:15:13" --num-bg-noises "3:4:5:6:7" --bg-noise-dir "${musan_out_dir}/musan_speech" ${vox1_train_dir} ${vox1_train_dir}_babble

  # Combine reverb, noise, music, and babble into one directory.
  utils/combine_data.sh ${vox1_train_dir}_aug ${vox1_train_dir}_reverb ${vox1_train_dir}_noise ${vox1_train_dir}_music ${vox1_train_dir}_babble

fi

#stage=12
if [ $stage -le 4 ]; then
  echo "=====================================CMVN========================================"
  # This script applies CMVN and removes nonspeech frames.  Note that this is somewhat
  # wasteful, as it roughly doubles the amount of training data on disk.  After
  # creating training examples, this can be removed.

  local/nnet3/xvector/prepare_feats_for_egs.sh --nj 5 --cmd "$train_cmd" ${vox1_train_dir} ${vox1_vad_train_dir} ${vox1_train_dir}/feats_no_sil
  utils/fix_data_dir.sh ${vox1_vad_train_dir}

  local/nnet3/xvector/prepare_feats_for_egs.sh --nj 5 --cmd "$train_cmd" ${vox1_test_dir} ${vox1_vad_test_dir} ${vox1_test_dir}/feats_no_sil
  utils/fix_data_dir.sh ${vox1_vad_test_dir}

fi

if [ $stage -le 12 ]; then
  echo "=====================================CMVN========================================"
  # This script applies CMVN and removes nonspeech frames.  Note that this is somewhat
  # wasteful, as it roughly doubles the amount of training data on disk.  After
  # creating training examples, this can be removed.
  #  data/Vox1_spect/test_noc
  for name in test ; do
#    local/nnet3/xvector/prepare_feats_for_cmvn.sh --nj 16 --cmd "$train_cmd" data/Vox1_pyfb/${name}_fb40 data/Vox1_pyfb/${name}_fb40_no_sil  data/Vox1_pyfb/${name}_fb40_no_sil/feats_no_sil
#    utils/fix_data_dir.sh data/Vox1_pyfb/${name}_fb40_no_sil
# Vox1_pyfb/dev_dfb24
#    local/nnet3/xvector/prepare_feats_for_cmvn.sh --nj 16 --cmd "$train_cmd" \
#      data/Vox1_spect/${name}_257 \
#      data/Vox1_spect/${name}_257_wcmvn  \
#      data/Vox1_spect/${name}_257_wcmvn/feats_no_sil
#    utils/fix_data_dir.sh data/Vox1_spect/${name}_257_wcmvn
#
#    local/nnet3/xvector/prepare_feats_for_cmvn.sh --nj 16 --cmd "$train_cmd" \
#      data/Vox1_pyfb/${name}_dfb24 \
#      data/Vox1_pyfb/${name}_dfb24_wcmvn  \
#      data/Vox1_pyfb/${name}_dfb24_wcmvn/feats_no_sil
#    utils/fix_data_dir.sh data/Vox1_pyfb/${name}_dfb24_wcmvn
#    local/nnet3/xvector/prepare_feats_for_cmvn.sh --nj 16 --cmd "$train_cmd" \
#      data/Vox1_pyfb/${name}_fb40 \
#      data/Vox1_pyfb/${name}_fb40_wcmvn  \
#      data/Vox1_pyfb/${name}_fb40_wcmvn/feats_no_sil
#    utils/fix_data_dir.sh data/Vox1_pyfb/${name}_fb40_wcmvn

     local/nnet3/xvector/prepare_feats_for_cmvn.sh --nj 16 --cmd "$train_cmd" \
      data/Vox1_pyfb64/${name}_noc \
      data/Vox1_pyfb/${name}_fb64_wcmvn  \
      data/Vox1_pyfb/${name}_fb64_wcmvn/feats_no_sil
    utils/fix_data_dir.sh data/Vox1_pyfb/${name}_fb64_wcmvn
  done
fi

#stage=20
if [ $stage -le 20 ]; then
  echo "=====================================CMVN========================================"
  # This script applies CMVN and removes nonspeech frames.  Note that this is somewhat
  # wasteful, as it roughly doubles the amount of training data on disk.  After
  # creating training examples, this can be removed.

  local/nnet3/xvector/prepare_feats_for_cmvn.sh --nj 16 --cmd "$train_cmd" --cmvn true \
    data/Vox1_pyfb/dev_fb64 data/Vox1_pyfb/dev_fb64_cmvn data/Vox1_pyfb/dev_fb64_cmvn/feats_no_sil
  utils/fix_data_dir.sh data/Vox1_pyfb/dev_fb64_cmvn

  local/nnet3/xvector/prepare_feats_for_cmvn.sh --nj 16 --cmd "$train_cmd" --cmvn true \
    data/Vox1_pyfb/test_fb64 data/Vox1_pyfb/test_fb64_cmvn data/Vox1_pyfb/test_fb64_cmvn/feats_no_sil
  utils/fix_data_dir.sh data/Vox1_pyfb/test_fb64_cmvn

fi

#stage=30
if [ $stage -le 30 ]; then
  echo "=====================================CMVN========================================"
  # This script applies CMVN and removes nonspeech frames.  Note that this is somewhat
  # wasteful, as it roughly doubles the amount of training data on disk.  After
  # creating training examples, this can be removed.

  local/nnet3/xvector/prepare_feats_for_cmvn.sh --nj 16 --cmd "$train_cmd" \
    data/Vox1_spect/dev_reverb data/Vox1_spect/dev_reverb_kaldi \
    data/Vox1_spect/spectrogram/dev_reverb_kaldi

  utils/fix_data_dir.sh data/Vox1_spect/dev_reverb_kaldi

#  local/nnet3/xvector/prepare_feats_for_cmvn.sh --nj 16 --cmd "$train_cmd"  \
#    data/Vox1_pyfb/test_fb64 data/Vox1_pyfb/test_fb64_cmvn data/Vox1_pyfb/test_fb64_cmvn/feats_no_sil
#  utils/fix_data_dir.sh data/Vox1_pyfb/test_fb64_cmvn

fi

if [ $stage -le 40 ]; then
  name=fb40
  python local/split_trials_dir.py --data-dir data/vox1/pyfb/dev_${name} \
    --out-dir data/vox1/pyfb/dev_${name}/trials_dir \
    --trials trials_2w
fi

if [ $stage -le 50 ]; then
  python local/split_trials_dir.py --data-dir data/vox1/pyfb/dev_mel_fb24_bod \
      --out-dir data/vox1/pyfb/dev_mel_fb24_bod/trials_dir \
      --trials trials_2w

  python local/split_trials_dir.py --data-dir data/vox1/pyfb/dev_fb24 --out-dir data/vox1/pyfb/dev_fb24/trials_dir --trials trials_2w

  python local/split_trials_dir.py --data-dir data/vox1/klfb/dev_fb40 --out-dir data/vox1/klfb/dev_fb40/trials_dir --trials trials_2w

  python local/split_trials_dir.py --data-dir data/vox1/spect/dev_log --out-dir data/vox1/spect/dev_log/trials_dir --trials trials_2w


  sox -V1 /home/storage/yangwenhao/dataset/voxceleb1/voxceleb1_wav/vox1_dev_wav/wav/id10059/2iL0P9T7pYY/00010.wav -r 8000 /home/storage/yangwenhao/dataset/voxceleb1_8k/voxceleb1_wav/vox1_dev_wav/wav/id10059/2iL0P9T7pYY/00010.wav

  sox -V1 /home/storage/yangwenhao/dataset/voxceleb1/voxceleb1_wav/vox1_dev_wav/wav/id10059/Ez0-hbMQs28/00002.wav -r 8000 /home/storage/yangwenhao/dataset/voxceleb1_8k/voxceleb1_wav/vox1_dev_wav/wav/id10059/Ez0-hbMQs28/00002.wav

  sox -V1 /home/storage/yangwenhao/dataset/voxceleb1/voxceleb1_wav/vox1_dev_wav/wav/id10059/Kg8KZ0OvfBo/00006.wav -r 8000 /home/storage/yangwenhao/dataset/voxceleb1_8k/voxceleb1_wav/vox1_dev_wav/wav/id10059/Kg8KZ0OvfBo/00006.wav

  sox -V1 /home/storage/yangwenhao/dataset/voxceleb1/voxceleb1_wav/vox1_dev_wav/wav/id10059/Kg8KZ0OvfBo/00002.wav -r 8000 /home/storage/yangwenhao/dataset/voxceleb1_8k/voxceleb1_wav/vox1_dev_wav/wav/id10059/Kg8KZ0OvfBo/00002.wav
fi

if [ $stage -le 60 ]; then

  for name in dev_vol_fb40 ; do # dev_aug_fb40
    steps/make_fbank.sh --write-utt2num-frames true --fbank-config conf/fbank_40.conf \
      --nj 14 --cmd "$train_cmd" \
      data/vox1/klfb/${name} data/vox1/klfb/${name}/log data/vox1/klfb/fbank/${name}
    utils/fix_data_dir.sh data/vox1/klfb/${name}
  done
#  wav-reverberate --shift-output=true --additive-signals='wav-reverberate --duration=5.59 "/home/storage/yangwenhao/dataset/musan/music/jamendo/music-jamendo-0098.wav" - |' --start-times='0' --snrs='8' /home/yangwenhao/storage/dataset/voxceleb1/voxceleb1_wav/vox1_dev_wav/wav/id10001/1zcIwhmdeo4/00003.wav - |
#
#  wav-reverberate --shift-output=true --additive-signals='wav-reverberate --duration=5.59 "/home/yangwenhao/storage/dataset/voxceleb1/voxceleb1_wav/vox1_dev_wav/wav/id10002/0_laIeN-Q44/00001.wav" - |' --start-times='0' --snrs='0' /home/yangwenhao/storage/dataset/voxceleb1/voxceleb1_wav/vox1_dev_wav/wav/id10001/1zcIwhmdeo4/00003.wav /home/work2020/yangwenhao/project/lstm_speaker_verification/data/vox1/dev_aug_spk/wavs/id10001-1zcIwhmdeo4-00003-id10002-0_laIeN-Q44-00001.wav
#
#  wav-reverberate --shift-output=true --additive-signals='wav-reverberate --duration=5.59 "/home/yangwenhao/storage/dataset/voxceleb1/voxceleb1_wav/vox1_dev_wav/wav/id10003/5ablueV_1tw/00001.wav" - |' --start-times='0' --snrs='0' /home/yangwenhao/storage/dataset/voxceleb1/voxceleb1_wav/vox1_dev_wav/wav/id10001/1zcIwhmdeo4/00003.wav /home/work2020/yangwenhao/project/lstm_speaker_verification/data/vox1/dev_aug_spk/wavs/id10001-1zcIwhmdeo4-00003-id10003-5ablueV_1tw-00001.wav
#
#  id10001-id10002-001 /home/work2020/yangwenhao/project/lstm_speaker_verification/data/vox1/dev_aug_spk/wavs/id10001-1zcIwhmdeo4-00003-id10002-0_laIeN-Q44-00001.wav
#  id10001-id10003-001 /home/work2020/yangwenhao/project/lstm_speaker_verification/data/vox1/dev_aug_spk/wavs/id10001-1zcIwhmdeo4-00003-id10003-5ablueV_1tw-00001.wav
#
#  id10001-id10002-001 id10001-id10002
#  id10001-id10003-001 id10001-id10003
#
#  steps/make_fbank.sh --write-utt2num-frames true --fbank-config conf/fbank_40.conf \
#      --nj 1 data/vox1/dev_aug_spk data/vox1/dev_aug_spk/log data/vox1/dev_aug_spk/fbank

steps/make_fbank.sh --write-utt2num-frames true --fbank-config conf/fbank_40.conf \
      --nj 12 data/vox1/klfb/test_fb40 data/vox1/klfb/test_fb40/log data/vox1/klfb/fbank/test_fb40



fi
if [ $stage -le 61 ]; then

  for dim in 24 64; do # dev_aug_fb40
    name=dev_fb${dim}
    steps/make_fbank.sh --write-utt2num-frames true --fbank-config conf/fbank_${dim}.conf \
      --nj 14 --cmd "$train_cmd" \
      data/vox1/klfb/${name} data/vox1/klfb/${name}/log data/vox1/klfb/fbank/${name}
    utils/fix_data_dir.sh data/vox1/klfb/${name}
  done

  for dim in 24 64; do # dev_aug_fb40
    name=test_fb${dim}
    steps/make_fbank.sh --write-utt2num-frames true --fbank-config conf/fbank_${dim}.conf \
      --nj 14 --cmd "$train_cmd" \
      data/vox1/klfb/${name} data/vox1/klfb/${name}/log data/vox1/klfb/fbank/${name}
    utils/fix_data_dir.sh data/vox1/klfb/${name}
  done

# steps/make_fbank.sh --write-utt2num-frames true --fbank-config conf/fbank_40.conf \
#       --nj 12 data/vox1/klfb/test_fb40 data/vox1/klfb/test_fb40/log data/vox1/klfb/fbank/test_fb40



fi