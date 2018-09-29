#!/usr/bin/env bash
# Copyright 2018 Beijing Xiaomi Intelligent Technology Co.,Ltd Weiji Zhuang
echo "$0 $@"
# -e 'error', -u 'undefined variable', -o pipefail 'error in pipeline',
set -euo pipefail

if [ $# != 2 ];then
    echo "usage:$0 <L-fst> <out-dir>"
    echo "egs: $0 data/lang/L.fst data/lang"
    exit 1;
fi

dictionary=$1
out_dir=$2
mkdir -p ${out_dir}
source path.sh
dir=`dirname $dictionary`

fstdraw --isymbols=$dir/phones.txt --osymbols=$dir/words.txt  $dir/L.fst > ${out_dir}/L.dot
sed -i 's/fontsize = 14/fontname="simsun.ttc",fontsize = 20/g' ${out_dir}/L.dot
dot -Tjpg ${out_dir}/L.dot > ${out_dir}/L.jpg
convert ${out_dir}/L.jpg -rotate 90 ${out_dir}/L.jpg

echo $0 $@ : success!
exit 0
