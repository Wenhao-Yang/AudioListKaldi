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


if [ -f $data/utt2dom ]; then
  rm $data/utt2dom
fi

mkdir -p $out_dir || exit 1
#[ ! -e $out_dir ] && rm $data/utt.tmp

touch $data/utt2dom

[ -f $data/utt2dom ] && rm $data/utt.tmp
touch $data/utt.tmp

if [ -f $data/utt2dom ]; then

  echo "$0: getting domains of utterances from utt2dom files"
  domains=`cat $data/utt2dom | sort -k 2 | awk '{print $2}' | uniqe`
  for d in domains ; do
    num_utt=`cat $data/utt2dom | grep $d | wc -l `
    c=`echo $(echo "$num_utt*$num_utt_per"|bc) | awk '{print int($0)}'`

    cat $data/utt2dom | grep $d | shuf | head -$c | awk '{print $1}' >> $data/utt.tmp

  done

  utils/subset_data_dir.sh --utt-list $data/utt.tmp $data_dir $out_dir
  rm $data/utt.tmp

fi

echo "$0: completed partition using $data/utt2dom"
exit 0;