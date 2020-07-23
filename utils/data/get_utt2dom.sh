#!/bin/bash

# get utterance domain from wav.scp files and write it to utt2chn

if [ $# != 1 ]; then
  echo "Usage: $0 [options] <datadir>"
  echo "e.g.:"
  echo " $0 data/train"
  exit 1
fi

data=$1

if [ -s $data/utt2dom ] && \
  [ $(wc -l < $data/utt2spk) -eq $(wc -l < $data/utt2dur) ]; then
  echo "$0: $data/utt2dom already exists in the expected path.  We won't regenerate it."
  exit 0;
fi

if [ -f $data/utt2dom ]; then
  rm $data/utt2dom
fi

touch $data/utt2dom

if [ -f $data/wav.scp ]; then
  echo "$0: getting chnnels of utterances from wav.scp files"
  cat $data/wav.scp | \
    while read line; do
          arr=(${line})
          uid_arr=(${arr[0]//\-/ })
          dom=${uid_arr[1]}

          [ $dom = "moives" ] && dom="movie"

          echo ${arr[0]} $dom >> $data/utt2dom
    done

fi

echo "$0: completed $data/utt2dom"

exit 0;