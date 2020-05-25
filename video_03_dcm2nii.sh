#!/bin/bash
sub_id=$1
ana_dir=$2
sess=$3
if [ -d ${ana_dir}/tempDCM/${sub_id}/sess_${sess} ] ; then
   echo " Processing sub_${sub_id} session_${sess}"
   rm -r ${ana_dir}/Nifti/.heudiconv/${sub_id}/ses-${sess}
   docker run --rm -it -v ${ana_dir}:/base \
                       nipy/heudiconv:latest \
                       -d /base/tempDCM/{subject}/ses-{session}/*.dcm \
                       -o /base/Nifti/ \
                       -f /base/templates/heuristic_update.py \
                       -s ${sub_id} -ss ${sess} -c dcm2niix -b --overwrite \
   ln -s -f ${ana_dir}/Nifti/.heudiconv/${sub_id}/ses-${sess}/info/dicominfo_ses-${sess}.tsv ${ana_dir}/derivatives/dicominfo_sub-${sub_id}_ses-${sess}.tsv
else
   echo " No session_${sess}"
fi
