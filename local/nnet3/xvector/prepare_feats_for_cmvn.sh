#!/bin/bash
#
# Copied from egs/sre16/v1/local/nnet3/xvector/prepare_feats_for_egs.sh (commit 3ea534070fd2cccd2e4ee21772132230033022ce).
#
# Apache 2.0.

# This script applies sliding window cmvn and removes silence frames.  This
# is performed on the raw features prior to generating examples for training
# the xvector system.

nj=40
cmd="run.pl"
stage=0
cmvns=false
cmvn=false
norm_vars=true
center=true
compress=true
cmn_window=300

echo "$0 $@"  # Print the command line for logging

if [ -f path.sh ]; then . ./path.sh; fi
. ./utils/parse_options.sh || exit 1;

if [ $# != 3 ]; then
  echo $#
  echo "Usage: $0 <in-data-dir> <out-data-dir> <feat-dir>"
  echo "e.g.: $0 data/train data/train_no_sil exp/make_xvector_features"
  echo "Options: "
  echo "  --nj <nj>                                        # number of parallel jobs"
  echo "  --cmd (utils/run.pl|utils/queue.pl <queue opts>) # how to run jobs."
  echo "  --norm-vars <true|false>                         # If true, normalize variances in the sliding window cmvn"
  exit 1;
fi

data_in=$1
data_out=$2
dir=$3

name=`basename $data_in`

#for f in $data_in/feats.scp $data_in/vad.scp ; do
for f in $data_in/feats.scp  ; do
  [ ! -f $f ] && echo "$0: No such file $f" && exit 1;
done

# Set various variables.
mkdir -p $dir/log
mkdir -p $data_out
featdir=$(utils/make_absolute.sh $dir)

for n in $(seq $nj); do
  # the next command does nothing unless $featdir/storage/ exists, see
  # utils/create_data_link.pl for more info.
  utils/create_data_link.pl $featdir/xvector_feats_${name}.${n}.ark
done

cp $data_in/utt2spk $data_out/utt2spk
cp $data_in/spk2utt $data_out/spk2utt
if [ -f $data_in/trials ]; then
    cp $data_in/trials $data_out/trials
fi
#cp $data_in/wav.scp $data_out/wav.scp

write_num_frames_opt="--write-num-frames=ark,t:$featdir/log/utt2num_frames.JOB"

sdata_in=$data_in/split$nj;
utils/split_data.sh $data_in $nj || exit 1;

# Apply sliding-window cepstral mean (and optionally variance)
if [ $cmvns = "true" ]; then
    echo "Window cmvn $cmvns"
    $cmd JOB=1:$nj $dir/log/create_xvector_feats_${name}.JOB.log \
      apply-cmvn-sliding --norm-vars=false --center=true --cmn-window=$cmn_window \
      scp:${sdata_in}/JOB/feats.scp ark:- \| \
      copy-feats --compress=$compress $write_num_frames_opt ark:- \
      ark,scp:$featdir/feats_${name}.JOB.ark,$featdir/xvector_feats_${name}.JOB.scp || exit 1;
elif [ $cmvn = 'true' ]; then
    echo "cmvn $cmvn"
    $cmd JOB=1:$nj $dir/log/create_xvector_feats_${name}.JOB.log \
      apply-cmvn --norm-means=true --norm-vars=true scp:${sdata_in}/JOB/feats.scp ark:- \| \
      copy-feats --compress=$compress $write_num_frames_opt ark:- \
      ark,scp:$featdir/feats_${name}.JOB.ark,$featdir/xvector_feats_${name}.JOB.scp || exit 1;
else
    echo "No cmvn"
    $cmd JOB=1:$nj $dir/log/create_xvector_feats_${name}.JOB.log \
      copy-feats --compress=$compress $write_num_frames_opt scp:${sdata_in}/JOB/feats.scp \
      ark,scp:$featdir/feats_${name}.JOB.ark,$featdir/xvector_feats_${name}.JOB.scp || exit 1;
fi

for n in $(seq $nj); do
  cat $featdir/xvector_feats_${name}.$n.scp || exit 1;
done > ${data_out}/feats.scp || exit 1

for n in $(seq $nj); do
  cat $featdir/log/utt2num_frames.$n || exit 1;
done > $data_out/utt2num_frames || exit 1
rm $featdir/log/utt2num_frames.*

echo "$0: Succeeded creating features for $name"
