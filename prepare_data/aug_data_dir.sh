#!/usr/bin/env bash


stage=5

if [ $stage -le 0 ]; then
  dataset=aishell2
  for name in test; do
    [ ! -f data/${dataset}/${name}_8k/reco2dur ] && utils/data/get_reco2dur.sh data/${dataset}/${name}_8k
    steps/data/augment_data_dir.py --utt-suffix "radio" --bg-snrs " -8:-10:-12" --num-bg-noises "1" --bg-noise-dir "data/radio/noise_8k" data/${dataset}/${name}_8k data/${dataset}/${name}_8k_radio

    prepare_data/aug2wav.py --dataset-dir /home/cca01/work2019/yangwenhao/mydataset/aishell2_8k --outset-dir /home/cca01/work2019/yangwenhao/mydataset/aishell2_8k_radio_%s --data-dir data/aishell2 --set-name ${name}_8k_radio

  done

fi

if [ $stage -le 5 ]; then
  for name in dev test ;do
    local/resample_data_scp.sh 8000 data/vox1/${name} data/vox1/${name}_8k
    prepare_data/aug2wav.py --dataset-dir /home/storage/yangwenhao/dataset/voxceleb1 \
                            --outset-dir /home/storage/yangwenhao/dataset/voxceleb1_%s \
                            --data-dir data/vox1 \
                            --set-name ${name} \
                            --suffix 8k
  done
fi


stage=10
if [ $stage -le 6 ]; then
  dataset=vox1
  for name in dev test; do
    [ ! -f data/${dataset}/${name}_8k/reco2dur ] && utils/data/get_reco2dur.sh data/${dataset}/${name}_8k
    steps/data/augment_data_dir.py --utt-suffix "radio" --bg-snrs " -8:-10:-12" --num-bg-noises "1" --bg-noise-dir "data/radio/noise_8k" data/vox1/${name}_8k data/vox1/${name}_8k_radio

    prepare_data/aug2wav.py --dataset-dir /home/cca01/work2019/yangwenhao/mydataset/voxceleb_8k --outset-dir /home/cca01/work2019/yangwenhao/mydataset/voxceleb_8k_radio_%s --data-dir data/vox1 --set-name ${name}_8k_radio
  done

fi

