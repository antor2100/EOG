#!/bin/bash

filenames=("npp_d20210111_t1322068_e1323310_b47715" 
           "npp_d20210111_t1323322_e1324564_b47715"
 	   "npp_d20210112_t1123364_e1125006_b47728"
       	   "npp_d20210112_t1303112_e1304354_b47729"
	   "npp_d20210113_t1104426_e1106068_b47742"
	   "npp_d20210113_t1244156_e1245398_b47743")

for file in ${filenames[@]}; do
  file_location=$(ssh eogdev find /eog/data/viirs/npp/npp_202101/aggregate_dirs/$file/ -regex '.*SVDNB_npp.*\.*\.h5')

  scp eogdev:$file_location 2021/jan_12/
done

# %04LaBamba%
