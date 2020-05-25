#!/bin/bash
sub_id=$1
raw_dir=$2
proc_dir=$3
sess=$4

echo " Processing session_${sess}"
docker run --rm -it -v ${raw_dir}:/base \
                    -v ${proc_dir}:/dataout \
                    nipy/heudiconv:latest \
                    -d /base/{subject}/*{session}*/*.dcm \
                    -o /dataout/Nifti/ \
                    -f /dataout/templates/heuristic.py \
                    -s ${sub_id} -ss ${sess} -c none -b --overwrite \
ln -s -f ${proc_dir}/Nifti/.heudiconv/${sub_id}/ses-${sess}/info/dicominfo_ses-${sess}.tsv ${proc_dir}/derivatives/dicominfo_sub-${sub_id}_ses-${sess}.tsv

