#!/usr/bin/env bash
# Copyright 2018 Beijing Xiaomi Intelligent Technology Co.,Ltd Weiji Zhuang
echo "$0 $@"
# -e 'error', -u 'undefined variable', -o pipefail 'error in pipeline',
set -euo pipefail

if [ $# != 1 ];then
    echo "usage:$0 <out-dir>"
    echo "egs: $0 exp/fsa/xiaoai"
    exit 1;
fi
out_dir=$1

source path.sh
mkdir -p ${out_dir}

cat <<EOF > $out_dir/fsa-xiaoai.dot
digraph FST {
rankdir = LR;
size = "8.5,11";
label = "";
center = 1;
orientation = Landscape;
ranksep = "0.4";
nodesep = "0.25";
0 [label = "0", shape = circle, style = bold, fontname="simsun.ttc",fontsize = 20]
	0 -> 1 [label = "小", fontname="simsun.ttc",fontsize = 20];
1 [label = "1", shape = circle, style = solid, fontname="simsun.ttc",fontsize = 20]
	1 -> 1 [label = "小", fontname="simsun.ttc",fontsize = 20];
	1 -> 2 [label = "爱", fontname="simsun.ttc",fontsize = 20];
2 [label = "2", shape = doublecircle, style = solid, fontname="simsun.ttc",fontsize = 20]
}
EOF

dot -Tjpg ${out_dir}/fsa-xiaoai.dot > ${out_dir}/fsa-xiaoai.jpg
convert ${out_dir}/fsa-xiaoai.jpg -rotate 90 ${out_dir}/fsa-xiaoai.jpg

echo $0 $@ : success!
exit 0
