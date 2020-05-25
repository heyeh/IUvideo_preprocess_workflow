!/bin/bash
cwd=$( pwd )
subject=$1
bids_dir=$2
sess=$3
if [ -d ${bids_dir}/sub-${subject}/ses-${sess} ]; then
    cd ${bids_dir}/sub-${subject}/ses-${sess}/
    fname=`cut -f1 sub-${subject}_ses-${sess}_scans.tsv`
    fname_arr=( $fname )
    fname_num=${#fname_arr[@]}

    for (( i=1; i<$fname_num; i++ )); do
      curr_scan=${fname_arr[i]}

      if [ "fmap" = "${curr_scan:0:4}" ];then
         fmap_func=()
         #echo ${curr_scan}
         nn=1
         for ((j=${i}+1;j<${fname_num}; j++)); do
             follow_scan=${fname_arr[$j]}
             if ( [ "func" = "${follow_scan:0:4}" ] && [[ ${follow_scan} != *_sbref* ]] ); then
                echo ${follow_scan}
                fmap_func[$nn]=\"ses-${sess}/${follow_scan}\"
                ((nn++))
              fi
              if [[ "fmap" = ${fname_arr[(($j+1))]:0:4} ]]; then
                  break
              fi
          done
          echo [${fmap_func[@]}]
          this_intendedfor=`echo ${fmap_func[@]} | sed -e 's/ /\,/g'`
          thisjson=`echo $curr_scan | sed -e s/_epi.nii.gz/_epi.json/`
          #echo ${thisjson}
    			# update the .json file to add an IntendedFor line that lists the correct functional data for this scan
          sed -e 's%\"InstitutionAddress\"%\"IntendedFor\": ['${this_intendedfor}'], \'$'\n''  \"InstitutionAddress\"%' $thisjson > ${thisjson}_tmp
          mv -f ${thisjson}_tmp ${thisjson}
      fi
    done
fi

cd ${cwd}
