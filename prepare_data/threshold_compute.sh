#!/usr/bin/env bash

# subset data dir

shuf data/aishell2/spect/dev_8k/spk2utt | head -25 | awk '{print $1}' > data/aishell2/spect/dev_8k/spk.25
utils/subset_data_dir.sh --spk-list data/aishell2/spect/dev_8k/spk.25 data/aishell2/spect/dev_8k data/aishell2/spect/dev_8k_25
utils/subset_data_dir.sh --spk-list data/aishell2/spect/dev_8k/spk.25 data/aishell2/spect/dev_8k_radio_v3 data/aishell2/spect/dev_8k_radio_v3_25


shuf data/aishell2/spect/test_8k/spk2utt | head -10 | awk '{print $1}' > data/aishell2/spect/test_8k/spk.10
utils/subset_data_dir.sh --spk-list data/aishell2/spect/test_8k/spk.10 data/aishell2/spect/test_8k data/aishell2/spect/test_8k_10
utils/subset_data_dir.sh --spk-list data/aishell2/spect/test_8k/spk.10 data/aishell2/spect/test_8k_radio_v3 data/aishell2/spect/test_8k_radio_v3_10


shuf data/vox1/spect/dev_8k/spk2utt | head -25 | awk '{print $1}' > data/vox1/spect/dev_8k/spk.25
utils/subset_data_dir.sh --spk-list data/vox1/spect/dev_8k/spk.25 data/vox1/spect/dev_8k data/vox1/spect/dev_8k_25
utils/subset_data_dir.sh --spk-list data/vox1/spect/dev_8k/spk.25 data/vox1/spect/dev_8k_radio_v3 data/vox1/spect/dev_8k_radio_v3_25


shuf data/vox1/spect/test_8k/spk2utt | head -10 | awk '{print $1}' > data/vox1/spect/test_8k/spk.10
utils/subset_data_dir.sh --spk-list data/vox1/spect/test_8k/spk.10 data/vox1/spect/test_8k data/vox1/spect/test_8k_10
utils/subset_data_dir.sh --spk-list data/vox1/spect/test_8k/spk.10 data/vox1/spect/test_8k_radio_v3 data/vox1/spect/test_8k_radio_v3_10


utils/combine_data.sh data/army/spect/aishell_dev_25 data/aishell2/spect/dev_8k_radio_v3_25 data/aishell2/spect/dev_8k_25
utils/combine_data.sh data/army/spect/aishell_test_10 data/aishell2/spect/test_8k_radio_v3_10 data/aishell2/spect/test_8k_10

utils/combine_data.sh data/army/spect/vox1_dev_25 data/vox1/spect/dev_8k_radio_v3_25 data/vox1/spect/dev_8k_25
utils/combine_data.sh data/army/spect/vox1_test_10 data/vox1/spect/test_8k_radio_v3_10 data/vox1/spect/test_8k_10

#aishell
shuf data/army/spect/aishell_dev_25/spk2utt | head -20 | awk '{print $1}' > data/army/spect/aishell_dev_25/spk.20
shuf data/army/spect/aishell_dev_25/spk2utt | tail -5 | awk '{print $1}' > data/army/spect/aishell_dev_25/spk.5

utils/subset_data_dir.sh --spk-list data/army/spect/aishell_dev_25/spk.20 data/army/spect/aishell_dev_25 data/army/spect/aishell_dev_20_devtrain
utils/subset_data_dir.sh --spk-list data/army/spect/aishell_dev_25/spk.5 data/army/spect/aishell_dev_25 data/army/spect/aishell_dev_5_devtest

shuf data/army/spect/aishell_test_10/spk2utt | head -5 | awk '{print $1}' > data/army/spect/aishell_test_10/spk.51
shuf data/army/spect/aishell_test_10/spk2utt | tail -5 | awk '{print $1}' > data/army/spect/aishell_test_10/spk.52

utils/subset_data_dir.sh --spk-list data/army/spect/aishell_test_10/spk.51 data/army/spect/aishell_test_10 data/army/spect/aishell_test_5_testtrain
utils/subset_data_dir.sh --spk-list data/army/spect/aishell_test_10/spk.52 data/army/spect/aishell_test_10 data/army/spect/aishell_dev_5_testtest

# vox1

shuf data/army/spect/vox1_dev_25/spk2utt | head -20 | awk '{print $1}' > data/army/spect/vox1_dev_25/spk.20
shuf data/army/spect/vox1_dev_25/spk2utt | tail -5 | awk '{print $1}' > data/army/spect/vox1_dev_25/spk.5

utils/subset_data_dir.sh --spk-list data/army/spect/vox1_dev_25/spk.20 data/army/spect/vox1_dev_25 data/army/spect/vox1_dev_20_devtrain
utils/subset_data_dir.sh --spk-list data/army/spect/vox1_dev_25/spk.5 data/army/spect/vox1_dev_25 data/army/spect/vox1_dev_5_devtest

shuf data/army/spect/vox1_test_10/spk2utt | head -5 | awk '{print $1}' > data/army/spect/vox1_test_10/spk.51
shuf data/army/spect/vox1_test_10/spk2utt | tail -5 | awk '{print $1}' > data/army/spect/vox1_test_10/spk.52

utils/subset_data_dir.sh --spk-list data/army/spect/vox1_test_10/spk.51 data/army/spect/vox1_test_10 data/army/spect/vox1_test_5_testtrain
utils/subset_data_dir.sh --spk-list data/army/spect/vox1_test_10/spk.52 data/army/spect/vox1_test_10 data/army/spect/vox1_dev_5_testtest


utils/combine_data.sh data/army/spect/thre_enrolled data/army/spect/aishell_dev_20_devtrain data/army/spect/vox1_dev_20_devtrain data/army/spect/aishell_test_5_testtrain data/army/spect/vox1_test_5_testtrain

utils/combine_data.sh data/army/spect/thre_notenrolled data/army/spect/aishell_dev_5_devtest data/army/spect/aishell_dev_5_testtest data/army/spect/vox1_dev_5_devtest data/army/spect/vox1_dev_5_testtest


