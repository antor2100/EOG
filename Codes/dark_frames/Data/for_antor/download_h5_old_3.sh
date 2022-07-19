#!/bin/bash

filenames=("j01_d20191117_t0548420_e0550065_b10341"
"j01_d20191118_t0529469_e0531114_b10355"
)

for file in ${filenames[@]}; do
  sat_type=${file:0:3}
  month=${file:5:6}
  sat_month=$sat_type"_"$month  


  file_location=$(ssh eogdev find /eog/data/viirs/$sat_type/$sat_month/aggregate_dirs/$file/ -regex '.*SVDNB_j01.*\.*\.h5')
  echo $file_location
  # scp eogdev:$file_location h5_folder/
done

# %04LaBamba%
