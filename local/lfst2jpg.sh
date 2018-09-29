#!/usr/bin/env bash
# Copyright 2018 Beijing Xiaomi Intelligent Technology Co.,Ltd Weiji Zhuang
echo "$0 $@"
# -e 'error', -u 'undefined variable', -o pipefail 'error in pipeline',
set -euo pipefail

if [ $# != 2 ];then
    echo "usage:$0 <L-fst> <out-dir>"
    echo "egs: $0 data/lang/L.fst data/lang/L.jpg"
    exit 1;
fi

dictionary=$1
out_file=$2
source path.sh
dir=`dirname $dictionary`
out_dir=`dirname $out_file`
mkdir -p ${out_dir}

fstdraw --isymbols=$dir/phones.txt --osymbols=$dir/words.txt  $dictionary > ${out_file}.dot
sed -i 's/fontsize = 14/fontname="simsun.ttc",fontsize = 20/g' ${out_file}.dot
dot -Tjpg ${out_file}.dot > ${out_file}
convert ${out_file} -rotate 90 ${out_file}

echo $0 $@ : success!
exit 0
