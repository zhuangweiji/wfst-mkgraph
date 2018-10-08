#!/usr/bin/env bash
# Copyright 2018 Beijing Xiaomi Intelligent Technology Co.,Ltd (Author: Weiji Zhuang)

#ref :https://blog.csdn.net/u013677156/article/details/77893661
# HCLG = asl(min(rds(det(H' o min(det(C o min(det(Lo G))))))))
# o表示组合，det表示确定化，min表示最小化，rds表示去除消岐符号，asl表示增加自环

. path.sh
LC_ALL=
#pip3 install jieba
#for cmd in xiaoai xideng ;do
#  python3 -m jieba -d ' ' data/$cmd/corpus.txt >data/$cmd/corpus.split
#done

rm -rf data/lang data/lang_tmp data/dict
mkdir -p data/lang
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

###L.FST###(Non-Deterministic FST, NFST)
fst_dir=exp/fst
mkdir -p $fst_dir
local/lfst2jpg.sh data/lang/L.fst $fst_dir/lang/L.jpg 
# L_disambig.fst也是FST形式的发音词典，不过它包含为了消歧(disambiguation)而引入的消歧符号(#1、#2)和为自环引入的#0。
# 分歧的情况如：
#   一个词是另一个词的前缀，cat 和 cats在同一个词典中，则需要"k ae t #1"
#   有同音的词，red: "r eh d #1", read: "r eh d #2"
# #0的作用是让消歧符号能够“通过”(pass through)G.fst,详见Mohri的文章
local/lfst2jpg.sh data/lang/L_disambig.fst $fst_dir/lang/L_disambig.jpg
###WFST###
wfst_dir=exp/wfst
mkdir -p $wfst_dir
for cmd in xiaoai xideng ;do
  for order in 1 2 ; do
    local/spt2wfstjpg.sh data/$cmd/corpus.split $order $wfst_dir/$cmd
  done
done

###union###
union_dir=exp/wfst/union
mkdir -p $union_dir

for order in 1 2 ; do
  fstunion exp/wfst/xiaoai/G-o$order.fst exp/wfst/xideng/G-o$order.fst $union_dir/union-o$order.fst
  fstisstochastic $union_dir/union-o${order}.fst

  fstdraw \
    --width=20 \
    --height=20 \
    --fontsize=20 \
    --title=union-o${order}.fst \
    --isymbols=data/lang/words.txt \
    --osymbols=data/lang/words.txt \
    $union_dir/union-o${order}.fst |\
    dot -Tjpg |\
    convert - -rotate 90 $union_dir/union-o${order}.jpg
done

###LG.fst###lexicon
# LG = min(det(L o G))
# fsttablecompose 实现 L o G
# fstdeterminizestar实现 det,同时去空边,选项-use-log = true要求程序首先将FST映射到log半环,从而保持stochasticity
# fstminimizeencoded 进行最小化,与OpenFst最小化实现大体相同,唯一变化是避免pushing weights,从而保持stochasticity
# fstpushspecial 类似于OpenFst的fstpush,但如果权重不等于1.
# 他可以确保所有状态“总计”为相同的值(可能与1不同),而不是尝试把 “额外”权重推到fst的开头或结尾.
# 这样程序不会失败,也更快(当FST“总和”太大,Fstpush可能失败或循环很长时间)
# fstarcsort 阶段对弧进行排序,以便后续组合操作更快
lg_dir=exp/wfst/LG
mkdir -p exp/wfst/LG
fsttablecompose data/lang/L_disambig.fst exp/wfst/xiaoai/G-o2.fst | \
fstdeterminizestar --use-log=true | \
fstminimizeencoded | fstpushspecial | \
fstarcsort --sort_type=ilabel > ${lg_dir}/LG.fst.$$ || exit 1;
mv ${lg_dir}/LG.fst.$$ ${lg_dir}/LG.fst
fstisstochastic ${lg_dir}/LG.fst || echo "[info]: LG not stochastic."

  fstdraw \
    --width=50 \
    --height=50 \
    --fontsize=20 \
    --title=LG.fst \
    --isymbols=data/lang/phones.txt \
    --osymbols=data/lang/words.txt \
    ${lg_dir}/LG.fst |\
    dot -Tjpg |\
    convert - -rotate 90 ${lg_dir}/LG.jpg


###C.fst###Context
#C.fst: 上下文环境（Context）模型，匹配三音素序列(triphone sequences)和单音素(monophones)，扩展音素成为上下文依赖的音素。Kaldi中的C.fst由于产生起来不方便，一般情况下不独立存在，直接与L_disambig.fst和G.fst，根据决策树的结果，产生CLG.fst。



###H.fst###HMM
#H.fst: HMM(Hidden Markov Models) 模型。这里值得注意的是，传统的FST中，H.fst是以声学状态为输入，上下文依赖的音素为输出，但Kaldi中进行了扩展——“In the conventional FST recipe, the H transducer is the transducer that has, on its output, context dependent phones, and on its input, symbols representing acoustic states. In our case, the symbol on the input of H (or HCLG) is not the acoustic state (in our terminology, the pdf-id) but instead something we call the transition-id”。



