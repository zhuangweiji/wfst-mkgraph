#!/usr/bin/env bash
# Copyright 2018 Xiaomi Weiji Zhuang
LC_ALL=

local/txt2fstjpg.sh data/xiaoaitongxue/corpus.txt 1 exp/LM/xiaoaitongxue/
local/txt2fstjpg.sh data/xiaoaitongxue/corpus.txt 2 exp/LM/xiaoaitongxue/
local/txt2fstjpg.sh data/command/corpus.txt 1 exp/LM/command/
local/txt2fstjpg.sh data/command/corpus.txt 2 exp/LM/command/

. path.sh
mkdir -p exp/LM/union
fstunion exp/LM/xiaoaitongxue/G-o1.fst exp/LM/command/G-o1.fst exp/LM/union/union-o1.fst
fstunion exp/LM/xiaoaitongxue/G-o2.fst exp/LM/command/G-o2.fst exp/LM/union/union-o2.fst

cat data/*/corpus.split | tr ' ' '\n' | grep -v ^$ | sort -u |awk '{print $1" "NR }END{print "<eps> 0";print "#0 "NR+1;print "<s> "NR+2;print "</s> "NR+3 }' > exp/LM/union/words.txt

for order in 1 2 ;do
  fstisstochastic exp/LM/union/union-o${order}.fst

  fstdraw --isymbols=exp/LM/union/words.txt --osymbols=exp/LM/union/words.txt exp/LM/union/union-o${order}.fst > exp/LM/union/union-o${order}.dot
  sed -i 's/fontsize = 14/fontname="simsun.ttc",fontsize = 20/g' exp/LM/union/union-o${order}.dot
  dot -Tjpg exp/LM/union/union-o${order}.dot > exp/LM/union/union-o${order}.jpg
done
