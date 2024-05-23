## Audio List Processing for Speaker Verification 

<p align="center">
  <a href="">
    <img src="https://img.shields.io/badge/python-3.x-blue"
         alt="Gitter">
  </a>
  <!-- <a href="https://badge.fury.io/js/electron-markdownify">
    <img src="https://badge.fury.io/js/electron-markdownify.svg"
         alt="Gitter">
  </a> -->
  <a href="https://github.com/ryanvolz/radioconda"><img src="https://img.shields.io/badge/kaldi-2023.07.26-blue"></a>

  <!-- <a href="https://www.paypal.me/AmitMerchant">
    <img src="https://img.shields.io/badge/$-donate-ff69b4.svg?maxAge=2592000&amp;style=flat"> -->
  </a>
</p>

## Overview

Preparing audio list for Speaker Verificaton in Pytorch using kaldi and python scripts. Most of scripts are borrowed from [Kaldi](https://github.com/kaldi-asr/kaldi).


## Dataset


VoxCeleb1&2, SITW, Aishell, Hi-Mia, ...

## Directorys

```shell
├── root
│   ├── conf            # Config files for features, etc.
│   ├── local           # Preparing wav.scp, utt2spk, etc.
│   ├── prepare_data    # Making features in dataset dirs.
│   ├── sid             # copied from kaldi
│   ├── steps           #  ...
│   ├── utils           #  ...
```

## Verification Trials Generation

```shell
python local/make_trials.py --data-dir <dir_with_wav.scp> --num-pair <num_of_pairs> --ignore-gender <cross_gender> --gender <specific_gender> --trials <trials_name>

```