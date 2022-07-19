#!/bin/bash

#filenames=("j01_d20211205_t1143449_e1145094_b20971")
filenames=("npp_d20220716_t1111529_e1113171_b55531"
)
for file in ${filenames[@]}; do
  echo $file
  file_location=$(ssh eogdev find /eog/data/viirs/npp/npp_202207/aggregate_dirs/$file/ -regex '.*SVDNB_npp.*\.*\.h5')
  echo $file_location
  scp eogdev:$file_location h5_folder/
done

# %04LaBamba%
