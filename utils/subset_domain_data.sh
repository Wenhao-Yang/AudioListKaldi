#!/bin/bash

if [ $# != 3 ]; then
  echo "Usage: $0 [options] <num-utt-per> <data-dir> <out-dir>"
  echo "e.g.:"
  echo " $0 1000 data/train"
  exit 1
fi

num_utt_per=$1
data_dir=$2
out_dir=$3

mkdir -p $out_dir || exit 1
#[ ! -e $out_dir ] && rm $data/utt.tmp

[ -f $data_dir/utt.tmp ] && rm $data_dir/utt.tmp
touch "$data_dir/utt.tmp"

if [ -f $data_dir/utt2dom ]; then

  echo "$0: getting domains of utterances from utt2dom files"
  domains=`cat $data_dir/utt2dom | sort -k 2 | awk '{print $2}' | uniq`
  for d in $domains ; do
    num_utt=`cat $data_dir/utt2dom | grep $d | wc -l `
    c=`echo $(echo "$num_utt*$num_utt_per"|bc) | awk '{print int($0)}'`

    cat $data_dir/utt2dom | grep $d | shuf | head -$c | awk '{print $1}' >> $data_dir/utt.tmp

  done

  utils/subset_data_dir.sh --utt-list $data_dir/utt.tmp $data_dir $out_dir
  utils/data/get_utt2dom.sh $out_dir
#  rm $data_dir/utt.tmp

fi

echo "$0: completed partition using $data_dir/utt2dom"
exit 0;