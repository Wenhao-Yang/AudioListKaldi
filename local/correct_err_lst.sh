#!/usr/bin/env bash

all_job=4
sample_rate=8000
nj=0
cat data/err.lst | \
    while read line; do
        l=$line
        orig_path=${l} #/home/cca01/work2019/yangwenhao/mydataset/wav_test/noise/CHN01/D01-U000000.wav
        new_path=${orig_path/"voxceleb2"/"voxceleb2_8k"}
        # echo $orig_path $new_path

        [ ! -d ${new_path%/*} ] && mkdir -p ${new_path%/*}
        sox -V1 ${orig_path} -r $sample_rate ${new_path} &
#        echo -e "${l[-2]} ${new_path}\n" >> $out_dir/wav.scp

        nj=`expr $nj + 1`
        if [ $(( $nj % $all_job ))} = 0 ]; then
          wait
        fi
    done
wait