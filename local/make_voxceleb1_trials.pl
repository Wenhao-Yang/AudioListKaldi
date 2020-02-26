#!/usr/bin/env perl
#
# Copyright 2018  Ewald Enzinger
#           2018  David Snyder
#
# Usage: make_voxceleb1.pl /export/voxceleb1 data/

if (@ARGV != 2) {
  print STDERR "Usage: $0 <path-to-data-dir> <path-to-data-lst-dir>\n";
  print STDERR "e.g. $0 data/ data/lst/\n";
  exit(1);
}

my ($out_dir, $lst_dir) = @ARGV;

if (! -e $lst_dir) {
  system("mkdir $lst_dir");
}

if (! -e $out_dir) {
  system("mkdir $out_dir");
}

# http://www.robots.ox.ac.uk/~vgg/data/voxceleb/meta/veri_test.txt
if (! -e "$out_dir/veri_test.txt") {
  # print "$out_dir\n";
  system("wget -O $out_dir/veri_test.txt http://www.robots.ox.ac.uk/~vgg/data/voxceleb/meta/veri_test.txt");
}

if (! -e "$lst_dir/vox1_meta.csv") {
  system("wget -O $lst_dir/vox1_meta.csv http://www.openslr.org/resources/49/vox1_meta.csv");
}


open(TRIAL_IN, "<", "$out_dir/veri_test.txt") or die "Could not open the verification trials file $out_dir/veri_test.txt";
open(META_IN, "<", "$lst_dir/vox1_meta.csv") or die "Could not open the meta data file $out_dir/vox1_meta.csv";
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
  my $utt_id1 = "$spkr_id-$uid-$segment";
  my $utt_id2 = "$spkr_id-$rec_id-$segment";
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
