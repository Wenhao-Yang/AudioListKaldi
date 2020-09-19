#!/usr/bin/env bash


stage=10

if [ $stage -le 0 ]; then
  dataset=aishell2
  for name in test; do
    [ ! -f data/${dataset}/${name}_8k/reco2dur ] && utils/data/get_reco2dur.sh data/${dataset}/${name}_8k
    steps/data/augment_data_dir.py --utt-suffix "radio" --bg-snrs " -8:-10:-12" --num-bg-noises "1" --bg-noise-dir "data/radio/noise_8k" data/${dataset}/${name}_8k data/${dataset}/${name}_8k_radio

    prepare_data/aug2wav.py --dataset-dir /home/cca01/work2019/yangwenhao/mydataset/aishell2_8k --outset-dir /home/cca01/work2019/yangwenhao/mydataset/aishell2_8k_radio_%s --data-dir data/aishell2 --set-name ${name}_8k_radio

  done

fi

if [ $stage -le 5 ]; then
  for name in test ;do
    local/resample_data_scp.sh 8000 data/vox1/${name} data/vox1/${name}_8k
    prepare_data/aug2wav.py --dataset-dir /home/storage/yangwenhao/dataset/voxceleb1 \
                            --outset-dir /home/storage/yangwenhao/dataset/voxceleb1_%s \
                            --data-dir data/vox1 \
                            --set-name ${name}_8k \
                            --suffix 8k
  done
fi

#if [ $stage -le 6 ]; then
#  dataset=vox1
#  for name in test ; do
#    [ ! -f data/${dataset}/${name}_8k_wav/reco2dur ] && utils/data/get_reco2dur.sh data/vox1/${name}_8k_wav
#    steps/data/augment_data_dir.py --utt-suffix "radio" --bg-snrs " -15:-20:-25:-30" --num-bg-noises "1" --bg-noise-dir "data/radio/noise_8k" data/vox1/${name}_8k_wav data/vox1/${name}_8k_radio
#
#    prepare_data/aug2wav.py --dataset-dir /home/storage/yangwenhao/dataset/voxceleb_8k --outset-dir /home/storage/yangwenhao/dataset/voxceleb_8k_radio_%s --data-dir data/vox1 --set-name ${name}_8k_radio
#  done
#
#fi

stage=10
if [ $stage -le 7 ]; then
  dataset=vox1
  for name in dev test; do
    [ ! -f data/${dataset}/${name}_8k/reco2dur ] && utils/data/get_reco2dur.sh data/${dataset}/${name}_8k
    steps/data/augment_data_dir.py --utt-suffix "radio" --bg-snrs " -8:-10:-12" --num-bg-noises "1" --bg-noise-dir "data/radio/noise_8k" data/vox1/${name}_8k data/vox1/${name}_8k_radio

    prepare_data/aug2wav.py --dataset-dir /home/cca01/work2019/yangwenhao/mydataset/voxceleb_8k --outset-dir /home/cca01/work2019/yangwenhao/mydataset/voxceleb_8k_radio_%s --data-dir data/vox1 --set-name ${name}_8k_radio
  done

fi

if [ $stage -le 8 ]; then
  for name in dev test ; do
    utils/combine_data.sh data/army/spect/vox1_${name}_clear_radio data/vox1/spect/${name}_8k_radio_v2 data/vox1/spect/${name}_8k
  done
fi

#utils/combine_data.sh data/army/spect/dev_v1 data/vox1/spect/dev_8k_radio_v2_2w data/vox1/spect/dev_8k data/vox1/spect/dev_8k_radio_v3 data/aishell2/spect/dev_8k data/aishell2/spect/dev_8k_radio_v3
if [ $stage -le 9 ]; then

utils/combine_data.sh data/army/spect/test_v1 data/vox1/spect/test_8k data/vox1/spect/test_8k_radio_v3 data/aishell2/spect/test_8k data/aishell2/spect/test_8k_radio_v3
fi

if [ $stage -le 10 ]; then
  steps/data/make_musan.sh --sampling-rate 16000 /home/storage/yangwenhao/dataset/musan data
fi