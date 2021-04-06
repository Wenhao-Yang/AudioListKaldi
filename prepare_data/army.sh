#!/usr/bin/env bash

# """
# @Author: yangwenhao
# @Contact: 874681044@qq.com
# @Software: PyCharm
# @File: sitw.sh
# @Time: 2020/3/13 16:13 PM
# @Overview:
# """

stage=0
if [ $stage -le 0 ]; then

  for s in dev test ; do
    mv data/vox1/spect/${s}_8k_radio_v3_log data/vox1/spect/${s}_8k_radio_v3_log_tmp
    utils/copy_data_dir.sh --utt-suffix  -8k-radio-v3 data/vox1/spect/${s}_8k_radio_v3_log_tmp data/vox1/spect/${s}_8k_radio_v3_log
    rm -r data/vox1/spect/${s}_8k_radio_v3_log_tmp
  done

#  mv data/vox1/spect/test_8k_radio_v3_log data/vox1/spect/test_8k_radio_v3_log_tmp
#  utils/copy_data_dir.sh --utt-suffix  -8k-radio-v3 data/vox1/spect/test_8k_radio_v3_log_tmp data/vox1/spect/test_8k_radio_v3_log
#  rm -r data/vox1/spect/test_8k_radio_v3_log_tmp

fi

if [ $stage -le 10 ]; then
  for s in dev test ; do
    mv data/vox1/spect/${s}_8k_radio_v3_log data/vox1/spect/${s}_8k_radio_v3_log_tmp
    utils/copy_data_dir.sh --utt-suffix  -8k-radio-v3 data/vox1/spect/${s}_8k_radio_v3_log_tmp data/vox1/spect/${s}_8k_radio_v3_log
    rm -r data/vox1/spect/${s}_8k_radio_v3_log_tmp
  done
fi

if [ $stage -le 20 ]; then
  utils/combine_data.sh data/army/spect/dev_8k_v5_log data/aidata/spect/train_8k_log data/vox1/spect/dev_8k_log data/vox1/spect/dev_8k_radio_v3_log data/aishell2/spect/dev_8k_log data/aishell2/spect/dev_8k_radio_v3_log


  for s in dev test ; do
    mv data/vox1/spect/${s}_8k_radio_v3_log data/vox1/spect/${s}_8k_radio_v3_log_tmp
    utils/copy_data_dir.sh --utt-suffix  -8k-radio-v3 data/vox1/spect/${s}_8k_radio_v3_log_tmp data/vox1/spect/${s}_8k_radio_v3_log
    rm -r data/vox1/spect/${s}_8k_radio_v3_log_tmp
  done

if [ $stage -le 21 ]; then
  for s in dev test ; do
    mv data/vox1/spect/${s}_8k_log data/vox1/spect/${s}_8k_log_tmp
    utils/copy_data_dir.sh --utt-suffix  -8k data/vox1/spect/${s}_8k_radio_v3_log_tmp data/vox1/spect/${s}_8k_radio_v3_log
    rm -r data/vox1/spect/${s}_8k_radio_v3_log_tmp
  done
fi

utils/combine_data.sh data/army/spect/dev_8k_v5_log data/aidata/spect/train_8k_log data/vox1/spect/dev_8k_log data/vox1/spect/dev_8k_radio_v3_log data/aishell2/spect/dev_8k_log data/aishell2/spect/dev_8k_radio_v3_log

cat data/aidata/spect/train_8k_log/trials data/vox1/spect/dev_8k_log/trials data/vox1/spect/dev_8k_radio_v3_log/trials data/aishell2/spect/dev_8k_log/trials data/aishell2/spect/dev_8k_radio_v3_log/trials | shuf > data/army/spect/dev_8k_v5_log/trials

cat data/aidata/spect/dev_8k_log/trials data/vox1/spect/test_8k_log/trials data/vox1/spect/test_8k_radio_v3_log/trials data/aishell2/spect/test_8k_log/trials data/aishell2/spect/test_8k_radio_v3_log/trials | shuf > data/army/spect/test_8k_v5_log/trials


python local/split_trials_dir.py --data-dir data/army/spect/dev_8k_v5_log --out-dir data/army/spect/dev_8k_v5_log/trials_dir --trials trials_4w

utils/combine_data.sh data/vox1/spect/test_8k_v5_log data/vox1/spect/test_8k_log data/vox1/spect/test_8k_radio_v3_log
python local/make_trials.py 60000 data/vox1/spect/test_8k_v5_log

utils/combine_data.sh data/aishell2/spect/test_8k_v5_log data/aishell2/spect/test_8k_log data/aishell2/spect/test_8k_radio_v3_log
python local/make_trials.py 60000 data/aishell2/spect/test_8k_v5_log