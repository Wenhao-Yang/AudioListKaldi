#!/usr/bin/env bash -x
date

nj=0

head -2 data/Vox1/dev_reverb/wav.scp | \
    while read line; do
        l=($line)

        echo ${#l[@]}
        echo ${l[-2]}
        l_len=${#l[@]}

        l[-2]=${l[2]//voxceleb1/voxceleb1_reverb}

        `echo ${l[*]:1:$((l_len-2))}`
        wait
        exit
    done
exit


for i in `seq 1 15`; do
    {
        echo "sleep 5"
        sleep 5
    } &
    nj=$nj+1
    if [ $((nj % 5)) -eq 0 ]; then
        wait
        echo ''
    fi
done
  ##等待所有子后台进程结束
date