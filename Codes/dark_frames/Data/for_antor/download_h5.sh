#!/bin/bash

filenames=("j01_d20211103_t1141521_e1143166_b20517"
"j01_d20211104_t1122570_e1124215_b20531"
"j01_d20211104_t1305211_e1306456_b20532"
)

for file in ${filenames[@]}; do
  file_location=$(ssh eogdev find /eog/data/viirs/j01/j01_202111/aggregate_dirs/$file/ -regex '.*SVDNB_j01.*\.*\.h5')

  scp eogdev:$file_location h5_folder/
done

# %04LaBamba%
