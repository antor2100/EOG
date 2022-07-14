#!/bin/bash

file="npp_d20210111_t1322068_e1323310_b47715"
file2=$(find . -regex '.*SVDNB_npp_d2013.*\.*\.h5')
file2=${file2:2}

echo $file2

pass="%04LaBamba%"
i=1
n=1

while [ $i -le $n ]
do
  #echo $file
  #scp eogdev:/eog/data/viirs/npp/npp_202101/aggregate_dirs/$file/SVDNB_npp_d20210111_t1322068_e1323310_b47715_c20210111145216205939_nobc_ops.h5 2021/jan_12/
  #read -s pass

  i=$[$i+1]
  echo $i
done

#echo file
