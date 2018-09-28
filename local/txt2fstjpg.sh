#!/usr/bin/env bash
# Copyright 2018 Xiaomi Weiji Zhuang
echo "$0 $@"
if [ $# != 3 ];then
    echo "usage:$0 <corpus-split> <order> <out-dir>"
    echo "egs: $0 data/xiaoaitongxue/corpus.txt"
    exit 1;
fi


corpus_txt=$1
order=$2
out_dir=$3
in_dir=`dirname ${corpus_txt}`

source path.sh

mkdir -p ${out_dir}
ngram-count -text ${corpus_txt} -order ${order} -gt2max 0 -gt1max 0 -lm ${out_dir}/lm-o${order}.arpa

arpa2fst --disambig-symbol=#0 --max-arpa-warnings=-1 \
    --read-symbol-table=${in_dir}/words.txt \
    ${out_dir}/lm-o${order}.arpa   ${out_dir}/G-o${order}.fst

fstisstochastic ${out_dir}/G-o${order}.fst
#用于诊断FST是否拥有概率属性（stochastic）。
#他打印出两个数字，最小权重和最大权重，以告诉用户FST不随机的程度。
#egs:7.83407e-08 7.83407e-08
#第一个数字很小，它证实没有状态的弧的概率加上最终状态明显小于1。 
#第二个数字意味着有些状态具有“太多”的概率。 对于具有回退的语言模型的FST来说，有一些状态具有“太多”概率是正常的。
#有时，第二个值比较大，这是因为回退权重使得状态之和大于1

fstdraw --isymbols=${in_dir}/words.txt --osymbols=${in_dir}/words.txt ${out_dir}/G-o${order}.fst > ${out_dir}/fst-o${order}.dot
sed -i 's/fontsize = 14/fontname="simsun.ttc",fontsize = 20/g' ${out_dir}/fst-o${order}.dot
dot -Tjpg ${out_dir}/fst-o${order}.dot > ${out_dir}/fst-o${order}.jpg

echo $0 $@ : success!
exit 0
