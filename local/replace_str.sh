#!/usr/bin/env bash

if [ $# != 3 ]; then
  echo "Usage: local/replace_str.sh <file> <str-a> <str-b>"
  echo "e.g.: local/replace_str.sh data/train/wav.scp data data_tmp "
  echo "This script helps create srp to resample wav in wav.scp"
  exit 1
fi

in_file=$1
org_str=$2
rep_str=$3

mv $in_file ${in_file}.bcp
cat ${in_file}.bcp  | \
  while read line; do
    new_line=${line/"$org_str"/"$rep_str"}
    echo -e "${new_line}\n" >> $in_file
  done
wait

#org_lines=`wc -l ${in_file}.bcp | awk '{print $1}'`
#new_lines=`wc -l ${in_file} | awk '{print $1}'`
#cat wav.scp.bcp  | \
#  while read line; do
#    new_line=${line/"$org_str"/"$rep_str"}
#    echo -e "${new_line}" >> wav.scp
#  done
#wait