#!/usr/bin/env bash
# Copyright 2018 Beijing Xiaomi Intelligent Technology Co.,Ltd (Author: Weiji Zhuang)

#pip3 install jieba
. path.sh
LC_ALL=
#for cmd in xiaoai guandeng ;do
#  python3 -m jieba -d ' ' data/$cmd/corpus.txt >data/$cmd/corpus.split
#done

cat data/*/corpus.split | tr ' ' '\n' |\
  grep -v ^$ | sort -u |\
  awk '{print $1" "NR }END{print "<eps> 0";print "#0 "NR+1;print "<s> "NR+2;print "</s> "NR+3 }' \
  > data/lang/words.txt

local/wfst_prepare_dict.sh data/word2phone.txt data/lang/words.txt data/dict   || exit 1;
utils/validate_dict_dir.pl data/dict || exit 1;
utils/prepare_lang.sh --position-dependent-phones false data/dict "<UNK>" data/lang_tmp data/lang || exit 1;
utils/validate_lang.pl --skip-determinization-check data/lang || exit 1;

###G-xiaoai.FSA###
fsa_dir=exp/fsa
order=2
mkdir -p $fsa_dir
local/xiaoai2fsajpg.sh $fsa_dir/xiaoai

###G-xiaoai.WFSA###
wfsa_dir=exp/wfsa
mkdir -p $wfsa_dir
local/xiaoai2wfsajpg.sh $wfsa_dir/xiaoai

###L.FST###
fst_dir=exp/fst
mkdir -p $fst_dir
local/lfst2jpg.sh data/lang/L.fst data/lang 


exit 0;
###WFST###
wfst_dir=exp/wfst
mkdir -p $wfst_dir
for cmd in xiaoai guandeng ;do
  for order in 1 2 ; do
    local/spt2wfstjpg.sh data/$cmd/corpus.split $order $wfst_dir/$cmd
  done
done


###union###
union_dir=exp/wfst/union
mkdir -p $union_dir

for order in 1 2 ; do
  fstunion data/xiaoai/G-o$order.fst data/guandeng/G-o$order.fst $union_dir/union-o$order.fst
  fstisstochastic $union_dir/union-o${order}.fst
  fstdraw --isymbols=data/lang/words.txt --osymbols=data/lang/words.txt $union_dir/union-o${order}.fst > $union_dir/union-o${order}.dot
  sed -i 's/fontsize = 14/fontname="simsun.ttc",fontsize = 20/g' $union_dir/union-o${order}.dot
  dot -Tjpg $union_dir/union-o${order}.dot > $union_dir/union-o${order}.jpg
  convert $union_dir/union-o${order}.jpg -rotate 90 $union_dir/union-o${order}.jpg
done


