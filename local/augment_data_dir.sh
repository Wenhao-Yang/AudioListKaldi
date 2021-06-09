#!/usr/bin/env bash

# author: yangwenhao
# contact: 874681044@qq.com
# file: augment_data_dir.sh
# time: 2021/6/9 20:23
# Description:
#   Augmentation of data from kaldi/egs/vox2 v2
#

stage=0
frame_shift=0.01
sample_rate=16000
data_dir=$1

subet_utt=`wc -l ${data_dir}/wav.scp | awk '{print $1}'`
subet_utt=`expr ${subet_utt} \* 4 / 5`
suffix=`expr ${subet_utt} / 1000`k

if [ $# -ne 1 ]; then
  echo "Usage: $0 <data-dir>"
  echo "By default, wav.scp, utt2num_frames, utt2spk are expected to be exists. "
  echo "Augmentatio data with riris and musan, combining all data together, but"
  echo "only 20% of all augmented data will be kept in the end."
  echo "e.g.: $0 data/train"
  exit 1;
fi

rirs_dir=/home/storage/yangwenhao/dataset/RIRS_NOISES
if [ ! -d "${rirs_dir}" ]; then
  # Download the package that includes the real RIRs, simulated RIRs, isotropic noises and point-source noises
  wget --no-check-certificate http://www.openslr.org/resources/28/rirs_noises.zip /home/storage/yangwenhao/dataset/
  unzip /home/storage/yangwenhao/dataset/rirs_noises.zip
fi

if [ $stage -le 1 ]; then
  if [ ! -f "${data_dir}/utt2num_frames" ]; then
    utils/data/get_num_frames.sh $data_dir
  fi
  if [ ! -f "${data_dir}/vad.scp" ]; then
    sid/compute_vad_decision.sh $data_dir
  fi

  awk -v frame_shift=$frame_shift '{print $1, $2*frame_shift;}' ${data_dir}/utt2num_frames > ${data_dir}/reco2dur
  # Make a version with reverberated speech
  rvb_opts=()
  rvb_opts+=(--rir-set-parameters "0.5, ${rirs_dir}/simulated_rirs/smallroom/rir_list")
  rvb_opts+=(--rir-set-parameters "0.5, ${rirs_dir}/simulated_rirs/mediumroom/rir_list")

  # Make a reverberated version of the data list.  Note that we don't add any
  # additive noise here.
  steps/data/reverberate_data_dir.py \
    "${rvb_opts[@]}" \
    --speech-rvb-probability 1 \
    --pointsource-noise-addition-probability 0 \
    --isotropic-noise-addition-probability 0 \
    --num-replications 1 \
    --source-sampling-rate $sample_rate \
    ${data_dir} ${data_dir}_reverb

  cp ${data_dir}/vad.scp ${data_dir}_reverb/

  utils/copy_data_dir.sh --utt-suffix "-reverb" ${data_dir}_reverb ${data_dir}_reverb.new
  rm -rf ${data_dir}_reverb
  mv ${data_dir}_reverb.new ${data_dir}_reverb
fi

if [ $stage -le 2 ]; then
  # Prepare the MUSAN corpus, which consists of music, speech, and noise
  # suitable for augmentation.
  # steps/data/make_musan.sh --sampling-rate 16000 $musan_root data

  # Get the duration of the MUSAN recordings.  This will be used by the
  # script augment_data_dir.py.
  for name in speech noise music; do
    if [ ! -f "data/musan_${name}/reco2dur" ]; then
      utils/data/get_utt2dur.sh data/musan_${name}
      mv data/musan_${name}/utt2dur data/musan_${name}/reco2dur
    fi
  done

  # Augment with musan_noise
  steps/data/augment_data_dir.py --utt-suffix "noise" --fg-interval 1 --fg-snrs "15:10:5:0" --fg-noise-dir "data/musan_noise" ${data_dir} ${data_dir}_noise
  # Augment with musan_music
  steps/data/augment_data_dir.py --utt-suffix "music" --bg-snrs "15:10:8:5" --num-bg-noises "1" --bg-noise-dir "data/musan_music" ${data_dir} ${data_dir}_music
  # Augment with musan_speech
  steps/data/augment_data_dir.py --utt-suffix "babble" --bg-snrs "20:17:15:13" --num-bg-noises "3:4:5:6:7" --bg-noise-dir "data/musan_speech" ${data_dir} ${data_dir}_babble

  # Combine reverb, noise, music, and babble into one directory.
  utils/combine_data.sh ${data_dir}_aug ${data_dir}_reverb ${data_dir}_noise ${data_dir}_music ${data_dir}_babble
  rm -r ${data_dir}_reverb ${data_dir}_noise ${data_dir}_music ${data_dir}_babble

  utils/subset_data_dir.sh ${data_dir}_aug $subet_utt ${data_dir}_aug_${suffix}
  utils/fix_data_dir.sh ${data_dir}_aug_${suffix}

fi