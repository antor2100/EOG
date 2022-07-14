#!/bin/bash

file="npp_d20210111_t1322068_e1323310_b47715"

i=1
n=1

while [ $i -le $n ]
do
  file_location=$(ssh eogdev find /eog/data/viirs/npp/npp_202101/aggregate_dirs/$file/ -regex '.*SVDNB_npp.*\.*\.h5')

  scp eogdev:$file_location 2021/jan_12/

  i=$[$i+1]
done
