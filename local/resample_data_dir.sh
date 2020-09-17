#!/usr/bin/env bash

if [ $# != 4 ]; then
  echo "Usage: local/resample_data_dir.sh <data-path> <sample_rate> <data-dir> <out-dir>"
  echo "e.g.: local/resample_data_dir.sh data/train"
  echo "This script helps create srp to resample wav in wav.scp"
  exit 1
fi

org_data=$1
sample_rate=$2
data_dir=$3
out_dir=$4

suffix=`expr ${sample_rate} / 1000`k
out_data=${org_data}_${suffix}

[ ! -d $data_dir ] && echo "$0: no such directory $data_dir" && exit 1;
[ ! -d $out_dir ] && mkdir $out_dir
[ ! -d $out_data ] && mkdir $out_data
[ ! -f $data_dir/wav.scp ] && echo "$0: no such file $data_dir/wav.scp" && exit 1;

nj=0
#[ ! -f $out_dir/wav.scp ] && touch $out_dir/wav.scp

cat $data_dir/wav.scp | \
    while read line; do
        l=($line)

        # echo ${#l[@]}
        orig_path=`echo ${l[-1]}` #/home/cca01/work2019/yangwenhao/mydataset/wav_test/noise/CHN01/D01-U000000.wav
        new_path=${orig_path/$org_data/$out_data}
        echo $new_path

        [ ! -d ${new_path%/*} ] && mkdir -p ${new_path%/*}
        sox ${orig_path} -r $sample_rate ${new_path} &
        echo -e "${l[-2]} ${new_path}\n" >> $out_dir/wav.scp

        nj=`expr $nj + 1`
        if [ $(( $nj % 10 ))} = 0 ]; then
          wait
        fi
    done
wait
#cat $data_dir/wav.scp | awk '{print $1 " sox " $2 " -r " "'$sample_rate'" " -p |"}' > $out_dir/wav.scp

for f in utt2spk spk2utt utt2dur reco2dur utt2num_frames trials; do
  if [ -f $data_dir/$f ]; then
    cp $data_dir/$f $out_dir
  fi
done

utils/fix_data_dir.sh $out_dir
echo "resample_data_dir.sh: files are created in $out_dir"
