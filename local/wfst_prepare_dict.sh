#!/usr/bin/env bash
# Copyright 2018 Beijing Xiaomi Intelligent Technology Co.,Ltd  (Author: Weiji Zhuang)
echo "$0 $@"
# -e 'error', -u 'undefined variable', -o pipefail 'error in pipeline',
set -euo pipefail

if [ $# != 3 ];then
    echo "usage:$0 <word2phone-file> <words-file> <dict-dir>"
    echo "egs: $0 word2phone.txt words.txt data/dict"
    exit 1;
fi

source path.sh
lexicon_file=$1
words_file=$2
dict_dir=$3
mkdir -p $dict_dir
mkdir -p $dict_dir/lexicon

# in-vocabulary lexicon
awk 'NR==FNR{lexicon[$1]; next;} ($1 in lexicon)' \
  $words_file $lexicon_file | egrep -v '<.?s>' |\
  sort -u > $dict_dir/lexicon/lexicon-iv.txt || exit 1;

echo 1
# out-of-vocabulary words
awk 'NR==FNR{lexicon[$1]; next;} !($1 in lexicon)' \
  $words_file $lexicon_file | egrep -v '<.?s>' |\
  sort -u > $dict_dir/lexicon/words-oov.txt  ||echo no oov-words

# extract non-silence phones
cat $dict_dir/lexicon/lexicon-iv.txt |\
  awk '{ for(n=2;n<=NF;n++){ phones[$n] = 1; }} END{for (p in phones) print p;}'| \
    sort -u |perl -e '
    my %ph_cl;
    while (<STDIN>) {
      $phone = $_;
      chomp($phone);
      chomp($_);
      $phone =~ s:([A-Z]+)[0-9]:$1:;
      if (exists $ph_cl{$phone}) { push(@{$ph_cl{$phone}}, $_)  }
      else { $ph_cl{$phone} = [$_]; }
    }
    foreach $key ( keys %ph_cl ) {
       print "@{ $ph_cl{$key} }\n"
    }
    ' | sort -k1 > $dict_dir/nonsilence_phones.txt || exit 1;

# select silence phones manually.
(echo sil; echo unk;) > $dict_dir/silence_phones.txt

# select optional silence ,It's going to be inserted to Between the two words.
echo sil > $dict_dir/optional_silence.txt

# A few extra questions that will be added to those obtained by automatically clustering
# the "real" phones.  These ask about stress; there's also one for silence.
cat $dict_dir/silence_phones.txt| awk '{printf("%s ", $1);} END{printf "\n";}' > $dict_dir/extra_questions.txt || exit 1;
cat $dict_dir/nonsilence_phones.txt | perl -e 'while(<>){ foreach $p (split(" ", $_)) {
  $p =~ m:^([^\d]+)(\d*)$: || die "Bad phone $_"; $q{$2} .= "$p "; } } foreach $l (values %q) {print "$l\n";}' \
  >> $dict_dir/extra_questions.txt || exit 1;

# Add silences/spoken_noise/unknow_noise/noises to the lexicon.
# Some dictionaries contain silences/spoken_noise/unknow_noise/noises prons.
# the sort | uniq is to remove a duplicated pron.
(echo '!SIL sil'; echo '<UNK> unk'; ) | \
cat -  $dict_dir/lexicon/lexicon-iv.txt | sort | uniq > $dict_dir/lexicon.txt || exit 1;

echo $0 $@ : succeeded!
exit 0
