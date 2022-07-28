#!/bin/bash

# ./run_granule_analysis granule_name smi degree

filenames=$(cat batch.txt)
cp batch.txt granule_names.txt

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

echo 'filename', 'granule_name', 'YMD', 'start_time', 'end_time', 'id', 'degree', 'coeff', 'ltrim', 'rtrim', 'SMI', 'null' > granule_summary.csv

if [ $sat_type = "npp" ];
then
	sat_type=1
elif [ $sat_type = "j01" ];
then
	sat_type=2
fi

/Applications/MATLAB_R2021a.app/bin/matlab -nodesktop -nosplash -r "individual_matlab_code($sat_type,$2,$3); exit"

/Applications/MATLAB_R2021a.app/bin/matlab -nodesktop -nosplash -r "concat_matlab_code_new($sat_type,$2,$3); exit"

python3 save_to_excel.py $1 $sat_type
