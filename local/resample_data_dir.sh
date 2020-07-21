#!/usr/bin/env bash

if [ $# != 3 ]; then
  echo "Usage: local/resample_data_dir.sh <sample_rate> <data-dir> <out-dir>"
  echo "e.g.: local/resample_data_dir.sh data/train"
  echo "This script helps create srp to resample wav in wav.scp"
  exit 1
fi

sample_rate=$1
data_dir=$2
out_dir=$3


[ ! -d $data_dir ] && echo "$0: no such directory $data_dir" && exit 1;
[ ! -d $out_dir ] && mkdir $out_dir

[ ! -f $data_dir/wav.scp ] && echo "$0: no such file $data_dir/wav.scp" && exit 1;

cat $data_dir/wav.scp | awk '{print $1 " sox " $2 "-r sample_rate -p - \|"}' > $out_dir/wav.scp

for f in utt2spk spk2utt utt2dur reco2dur utt2num_frames trials; do
  if [ -f $data/$f ]; then
    cp $data_dir/$f $out_dir/$f
  fi
done

utils/fix_data_dir.sh $out_dir
echo "resample_data_dir.sh: files are created in $out_dir"
