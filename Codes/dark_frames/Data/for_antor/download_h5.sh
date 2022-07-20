#!/bin/bash

filenames=$(cat batch.txt)

rm -r h5_folder/*

for file in ${filenames[@]}; do
  sat_type=${file:0:3}
  month=${file:5:6}
  sat_month=$sat_type"_"$month
  echo $file
  file_location=$(sshpass -f "/Users/antor/Documents/EOG/Codes/dark_frames/Data/for_antor/password.txt" ssh eogdev find /eog/data/viirs/$sat_type/$sat_month/aggregate_dirs/$file/ -regex '.*SVDNB.*\.*\.h5')
#   file_location=$(ssh eogdev find /eog/data/viirs/j01/j01_202112/aggregate_dirs/$file/ -regex '.*SVDNB.*\.*\.h5')
  
  #echo $file_location
  sshpass -f "/Users/antor/Documents/EOG/Codes/dark_frames/Data/for_antor/password.txt" scp -r eogdev:$file_location h5_folder/
done

ls h5_folder > h5_names.txt

#rm -r h5_folder/antor_codes

# %04LaBamba%
