#!/usr/bin/env bash
# Copyright 2018 Beijing Xiaomi Intelligent Technology Co.,Ltd Weiji Zhuang

#pip3 install jieba
. path.sh
LC_ALL=

for cmd in xiaoaitongxue command ;do
  python3 -m jieba -d ' ' data/$cmd/corpus.txt >data/$cmd/corpus.split
done

cat data/*/corpus.split | tr ' ' '\n' |\
  grep -v ^$ | sort -u |\
  awk '{print $1" "NR }END{print "<eps> 0";print "#0 "NR+1;print "<s> "NR+2;print "</s> "NR+3 }' \
  > data/lang/words.txt

for cmd in xiaoaitongxue command ;do
  for order in 1 2 ; do
    local/spt2fstjpg.sh data/$cmd/corpus.split $order data/$cmd
  done
done

union_dir=exp/fst/union
mkdir -p $union_dir

for order in 1 2 ; do
  fstunion data/xiaoaitongxue/G-o$order.fst data/command/G-o$order.fst $union_dir/union-o$order.fst
  fstisstochastic $union_dir/union-o${order}.fst
  fstdraw --isymbols=data/lang/words.txt --osymbols=data/lang/words.txt $union_dir/union-o${order}.fst > $union_dir/union-o${order}.dot
  sed -i 's/fontsize = 14/fontname="simsun.ttc",fontsize = 20/g' $union_dir/union-o${order}.dot
  dot -Tjpg $union_dir/union-o${order}.dot > $union_dir/union-o${order}.jpg
  convert $union_dir/union-o${order}.jpg -rotate 90 $union_dir/union-o${order}.jpg
done
