#!/bin/bash
proc_dir=XX/BIDS #where you put BIDs data and other necessary files
scripts_dir=XX/scripts #where you put all your scripts
subject_list=$( cat ${scripts_dir}/subjects.list ) #a list of subjects id
rawdata_dir=XX/XX # your dicom directory
mappingfileName=XXX # input the content in { } as {initial_subs_runs}_sess01.csv --your log mapping file will be searched in $proc_dir/templates

# mkdir -p ${proc_dir}/{Nifti,derivatives,templates,logfiles,tempDCM}

## remember to save the log sheet of initial_subs_runs_xx.csv first in proc_dir/templates
## Run each step seperatly while comment off other steps
cwd=$( pwd )

cd ${scripts_dir}
#################################################
## Step 1. Change access right of DCM.         ##
## Be careful! It will change on raw data.     ##
## Remember to comment off after run this part.##
#################################################
# for subj in ${subject_list}
# do
#   echo ----------------------------
#   echo !!!! Be Careful sudo !!!!
#   echo ----------------------------
#   find ${rawdata_dir}/${subj} -type d -name "*Video*@dpk_*" -not -perm 755 -print0 | sudo xargs -0 chmod -R 755
#   find ${rawdata_dir}/${subj} -type f -name "*.dcm" -not -perm 755 -print0 | sudo xargs -0 chmod 755
#   find ${rawdata_dir}/${subj} -not -group PeggyAccess -and -name "*.dcm"  -print0 | sudo xargs -0 chgrp PeggyAccess
# done
##################################################
## Step 2. Run heudiconv to generate tsv file of## 
## scan info. for double check. After this step, ##
## remember to run doublecheck.m in MATLAB. Usually##
## the fieldmap series id might be different, which##
## need to be further check.                    ## 
################################################## 
# for subj in ${subject_list}
# do
#  echo --------------------------------
#  echo !!!Start to heudiconv ${subj}!!!
#  echo --------------------------------
#   if [ ! -d ${rawdata_dir}/${subj}/*Video* ]; then
#      echo " ERROR:${subj} NO raw dicom;Exit now...... " 
#      exit
#   fi
#   for sess in 01 02 #03
#   do
#      if [ ! -f ${proc_dir}/derivatives/dicominfo_sub-${subj}_ses-${sess}.tsv ]; then
#         ./video_01_generate_seriesID.sh ${subj} ${rawdata_dir} ${proc_dir} ${sess}
#      else
#         echo " dicominfo_sub-${subj}_ses-${sess}.tsv EXISTS "    
#      fi
#   done
# done
###########################################################
## Step 3. Copy dcm to a tempory dir ${proc_dir}/tempDCM ##
###########################################################
# for subj in ${subject_list}
# do
#   #  if [ -d ${proc_dir}/tempDCM/${subj} ]; then
#   #    echo  -----------------------------------------------------
#   #    echo  ${subj} exist in tempDCM; Exit now.....
#   #    echo  " You can decide if want to delete the existing dataset "
#   #    exit
#   # fi 
#  
#    for sess in 01 02 #03
#    do
#      if [ ! -d ${proc_dir}/tempDCM/${subj}/ses-${sess} ]; then
#          ./video_02_copydcm_update.sh ${subj} ${proc_dir} ${rawdata_dir} ${sess} ${mappingfileName}_sess${sess}.csv > ${proc_dir}/logfiles/copydcm_${subj}_sess-${sess}.log 2>&1
#      else
#           echo " ${subj} ses-${sess} EXISTS in tempDCM " >${proc_dir}/logfiles/copydcm_${subj}_sess-${sess}.log 2>&1
#      fi
#    done
# done
###################################
## Step 4. Convert data to BIDs  ##
###################################
#   echo ----------------------------
#   echo !!!! Running heudiconv !!!!
#   echo ----------------------------
#for subj in ${subject_list}
#do
#    # if [ -d ${proc_dir}/Nifti/sub-${subj} ]; then
#    #    echo " ${subj} exists in Nifti; Exit now...... "
#    #    exit
#    # fi
#    # if [ ! -d ${proc_dir}/tempDCM/${subj} ]; then
#    #    echo " ERROR: NO ${subj} in tempDCM; Exit now...... "
#    #    exit
#    # fi
#  for sess in 01 02 #03
#  do
#     if [ ! -d ${proc_dir}/Nifti/sub-${subj}/ses-${sess} ]; then
#        ./video_03_dcm2nii.sh ${subj} ${proc_dir} ${sess} > ${proc_dir}/logfiles/dcm2nii_${subj}_sess-${sess}.log 2>&1
#        ./video_04_assignFieldmap.sh ${subj} ${proc_dir}/Nifti ${sess} > ${proc_dir}/logfiles/assignfmp_${subj}_sess-${sess}.log 2>&1
#     else
#        echo " ${subj} ses-${sess} EXISTS in Nifti " > ${proc_dir}/logfiles/assignfmp_${subj}_sess-${sess}.log 2>&1
#  done
#done
### Run doublecheck.m again to see anything wrong. 
### and then mannually change IntendFor in the 
### fieldmap_AP/PA.json file for those don't follow the common logic

### validate BIDs
# docker run -ti --rm -v ${proc_dir}/Nifti:/data:ro bids/validator /data  > ${proc_dir}/derivatives/valid_report.txt 2>&1
################################
## Limit access to dcm again  ##
# for subj in ${subject_list}
# do
#   echo ----------------------------
#   echo !!!! Limit access back !!!!
#   echo ----------------------------
#   chmod 554 ${rawdata_dir}/${subj}/*
# done
cd ${cwd}
