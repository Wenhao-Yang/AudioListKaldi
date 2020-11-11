#!/usr/bin/env bash


stage=15

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

#stage=10
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
#  steps/data/make_musan.sh --sampling-rate 16000 /home/storage/yangwenhao/dataset/musan data
  for d in vox1 aishell2 ; do
    steps/data/augment_data_dir.py --utt-suffix "musan" --bg-snrs "15:12:10" --num-bg-noises "1" --bg-noise-dir "data/musan_8k/musan" data/${d}/dev_8k data/${d}/dev_8k_musan
  done
fi


#python local/make_aishell.py --dataset-dir /home/yangwenhao/store20/dataset/aishell2_8k/iOS --output-dir data/aishell2/8k --suffix 8k --test-spk 40
#
#python local/make_aishell.py --dataset-dir /home/yangwenhao/store20/dataset/aishell2_8k_radio_wav_v2/iOS --output-dir data/aishell2/8k_radio_v2 --suffix 8k-radio-v2 --test-spk 40
#
#python local/make_aishell.py --dataset-dir /home/yangwenhao/store20/dataset/aishell2_8k_radio_wav_v3/iOS --output-dir data/aishell2/8k_radio_v3 --suffix 8k-radio-v3 --test-spk 40
#
#/home/yangwenhao/store20/dataset/vox1_ai2_musan_wav/aishell2_8k/iOS
#
#utils/combine_data.sh data/army/dev_8k data/vox1/spect/dev_8k_radio_v2_1w data/vox1/spect/dev_8k_radio_v3 data/vox1/spect/dev_8k data/aishell2/spect/dev_8k data/aishell2/spect/dev_8k_musan  data/aishell2/spect/dev_8k_radio_v3
#
#utils/combine_data.sh data/army/spect/test_8k data/vox1/spect/test_8k_radio_v3 data/vox1/spect/test_8k data/aishell2/spect/test_8k   data/aishell2/spect/test_8k_radio_v3
#
#cat data/vox1/spect/test_8k_radio_v3/trials data/vox1/spect/test_8k/trials data/aishell2/spect/test_8k/trials   data/aishell2/spect/test_8k_radio_v3/trials

if [ $stage -le 15 ]; then
  local/resample_data_scp.sh 8000 data/vox2/dev_7h data/vox2/dev_8k_7h
  prepare_data/aug2wav.py --dataset-dir /home/storage/yangwenhao/dataset/voxceleb2 \
                          --outset-dir /home/storage/yangwenhao/dataset/voxceleb2_%s \
                          --data-dir data/vox2 \
                          --set-name dev_8k_7h \
                          --suffix 8k \
                          --nj 12
fi