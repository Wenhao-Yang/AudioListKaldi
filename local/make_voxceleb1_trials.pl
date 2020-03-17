#!/usr/bin/env perl
#
# Copyright 2018  Ewald Enzinger
#           2018  David Snyder
#
# Usage: make_voxceleb1.pl /export/voxceleb1 data/

if (@ARGV != 2) {
  print STDERR "Usage: $0 <path-to-data-dir> <path-to-out-data-dir>\n";
  print STDERR "e.g. $0 data/ data/lst/\n";
  exit(1);
}

my ($vox1_root, $out_dir) = @ARGV;

if (! -e $out_dir) {
  system("mkdir $out_dir");
}

# http://www.robots.ox.ac.uk/~vgg/data/voxceleb/meta/veri_test.txt
if (! -e "$vox1_root/veri_test.txt") {
  # print "$out_dir\n";
  # system("wget -O $vox1_root/veri_test.txt http://www.robots.ox.ac.uk/~vgg/data/voxceleb/meta/veri_test.txt");
    system("cp /work20/yangwenhao/dataset/voxceleb1/veri_test.txt $vox1_root/veri_test.txt")
}

if (! -e "$vox1_root/vox1_meta.csv") {
  # system("wget -O $vox1_root/vox1_meta.csv http://www.openslr.org/resources/49/vox1_meta.csv");
    system("cp /work20/yangwenhao/dataset/voxceleb1/vox1_meta.csv $vox1_root/vox1_meta.csv")
}


open(TRIAL_IN, "<", "$vox1_root/veri_test.txt") or die "Could not open the verification trials file $vox1_root/veri_test.txt";
open(META_IN, "<", "$vox1_root/vox1_meta.csv") or die "Could not open the meta data file $vox1_root/vox1_meta.csv";
open(TRIAL_OUT, ">", "$out_dir/trials") or die "Could not open the output file $out_dir/trials";

my %id2spkr = ();
while (<META_IN>) {
  chomp;
  my ($vox_id, $spkr_id, $gender, $nation, $set) = split;
  $id2spkr{$vox_id} = $spkr_id;
}

my $test_spkrs = ();
while (<TRIAL_IN>) {
  chomp;
  # 0 Ezra_Miller/0cYFdtyWVds_0000005.wav Eric_McCormack/Y-qKARMSO7k_0000001.wav
  # 1 id10270/x6uYqmx31kE/00002.wav id10270/GWXujl-xAVM/00038.wav
  my ($tar_or_non, $path1, $path2) = split;

  # Create entry for left-hand side of trial
  # id10270/x6uYqmx31kE/00002.wav
  my ($spkr_id, $uid, $filename) = split('/', $path1);
  my $segment = substr($filename, 0, 5);
  my $utt_id1 = "$spkr_id-$uid-$segment";
  $test_spkrs{$spkr_id} = ();

  # Create entry for right-hand side of trial

  my ($spkr_id, $uid, $filename) = split('/', $path2);
  my $segment = substr($filename, 0, 5);
  my $utt_id2 = "$spkr_id-$uid-$segment";
  $test_spkrs{$spkr_id} = ();

  my $target = "nontarget";
  if ($tar_or_non eq "1") {
    $target = "target";
  }
  print TRIAL_OUT "$utt_id1 $utt_id2 $target\n";
}

close(TRIAL_OUT) or die;
close(TRIAL_IN) or die;
close(META_IN) or die;
