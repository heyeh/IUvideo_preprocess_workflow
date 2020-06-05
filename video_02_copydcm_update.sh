#!/bin/bash

if [ "$1" = "" ]; then echo "usage:video_02_copydcm_update.sh subj preprocdir rawdir session mapping" ; exit; fi

######
# this_copydcm
#
# this just copy dcm of interested
#
# UPDATE 09-26-2019
######

function this_copydcm() {
	if [ "$1" = "" ] ; then
		echo "usage: this_copydcm subjID destdir runname session series"
		exit
	fi

  subjID=$1
	destdir=$2
	runname=$3
	session=$4
	series=$5
	expectedlen=0 #$6

  
  # this identiies the source dcm directory corresponding to this session. sometimes denoted like _1, sometimes like _01.
	# basically it looks in the raw data dir and looks for the Video_1/2 directory for the current subject.
	# IMPORTANT NOTE: when the IRF makes a typo in the name of the directory, this code can fail. For instance if they type VIDeo instead of Video.
	sourcedir=`ls -d ${rawdir}/${subjID}/*Video**_{${session#?},${session}}* 2>/dev/null`
	
	# new 12/20/17 only take ODD dcms for composite T1 since psn dcms are combined/duplicated and lower quality
	# (this is according to instructions from Hu)
	#
	# in general, pad_series is going to take the series number (e.g. 23) and pad it to match the format in the filename (000023).
	# since T1 composite requires taking only odd images for IU special, we can encode that in the pad_series variable as well.
	if [ "$runname" = "9_T1_c" ] ; then
		pad_series=`printf %06d $series` # pad series to match filename format
		pad_series="${pad_series}_*[13579].dcm"
	else
		pad_series=`printf %06d $series` # pad series to match filename format
		pad_series="${pad_series}_*.dcm"
	fi

  # check how many matching .dcms exist and print a warning if it's not what we expected. all such warnings should be investigated!
	# sometimes they are okay and sometimes not but always need to be checked.
	#found_count=`ls ${sourcedir}/001_${pad_series} | wc -l`
	#if [ $found_count -ne $expectedlen ] ; then echo "WARNING: found $found_count dcms; expected $expectedlen";  fi

  # copy dcm now
	 echo "cp ${subjID}_${session}_$series for ${runname}"
   cp ${sourcedir}/001_${pad_series} ${destdir} #>${preprocdir}/tempDCM/copydcm_${subjID}.log 2>&1

}


######
# main routine
#
# for this subject (+run)
# read header names in subject mapping to find which fields correspond to which runs
#
# once know what column corresponds to each run/session
#
# create file hierarchy for subj if doesn't exist
#
# read that column for each subject to find out what series/session number corresponds to each run
# then copy the dicom
######

subjID=$1
preprocdir=$2
rawdir=$3
this_session=$4
subj_run_mapping=$5 #subj_run_mapping is looked for inside $templatedir
specSerie=$6
templatedir=${preprocdir}/templates
tempdicomdir=${preprocdir}/tempDCM


# script will try to build all these runs.
# to add extra runs,
# -- copy here exactly the name in the header of the mapping file, and also update all_run_names_arr and all_run_names_len_arr (in the same order)

declare -a all_run_names_arr=("1_rest1_fmPA" "1_rest1_fmAP" "2_rest1_sbref" "2_rest1" "3_movie1_fmPA" "3_movie1_fmAP" "4_movie1_sbref" "4_movie1" "5_ofc1_fmPA" "5_ofc1_fmAP" "6_ofc1_sbref" "6_ofc1" "7_rest2_fmPA" "7_rest2_fmAP" "8_rest2_sbref" "8_rest2" "9_T1_c" "10_T2" "11_DWI_a" "11_DWI_b" "alt_anat" "12_pix_fmPA" "12_pix_fmAP" "13_pix_sbref" "13_pix" "14_bang_fmPA" "14_bang_fmAP" "15_bang_sbref" "15_bang")

# declare -a all_run_names_len_arr=(1355 1130 1355 176 176 160 1355 1080 1355)
run_num=${#all_run_names_arr[@]} # length of all run names
# you can also run this code to process one specific run (instead of all of them) as the second argument after the subj_id
if [ ! -z "${6}" ] ; then
	do_run="${6}"
fi

####
# next parse log file to determine which dcms go where
# do this dynamically in case field locations need to change as we add more information
####

all_run_name_pos_arr=() # empty array to be populated by positions (e.g. col # in csv file); to avoid hard-coding
all_run_name_sess_arr=() # empty array to be populated by session #s

field_num=`head -1 ${templatedir}/${subj_run_mapping} | grep -o "," | wc -l` # headers # how many columns are there in file
field_num=$((${field_num}+1))

# this just checks that there is an entry for this subject in the mapping .csv file - abort with error if not.
this_entry=`grep $subjID ${templatedir}/${subj_run_mapping} | cut -d "," -f1`
if [ -z "${this_entry}" ] ; then echo "ERROR (${subjID}): cannot find $subjID in mapping file. Exiting..."; exit 1; fi

# loop over every single run in the all_run_names variable
# (this is done even when only need to process a single run -- the code expects a fully-populated array.)

for (( i=0; i<run_num; i++ )); do
	curr_run=${all_run_names_arr[$i]}

	# the purpose of this part is to find which field (column) matches the series # and session # matching the run name we are currently on.
	#
	# in more detail:
	# iterate over each field in header of subj_mapping (field_num is the number of columns in the mapping .csv file)
	# for each column NUMBER, find the corresponding column NAME (by reading the .csv header) and store it in curr_field
	# then if this field matchs the run we wanted to be processing right now, store the field NUMBER in the all_run_name_pos_arr
	# all_run_name_pos_arr is going to be a structure mapping between the run names (e.g. 2_rest1) and the field NUMBERS they are stored in in the .csv file (i.e. perhaps column # 4)

	# series first
	for (( j=1; j<=${field_num}; j++ )); do
		curr_field=`head -1 ${templatedir}/${subj_run_mapping} | cut -d, -f${j}`
		if [ "${curr_run}" = "${curr_field}" ] ; then all_run_name_pos_arr[$i]=${j};  break; fi # match
	done
# now there is a mapping between run names and where the corresponding series # and session #s are stored in the subj mapping.
# these are stored in all_run_name_pos_arr (for the main series#) and all_run_name_sess_arr (for the sessions)
done

###
# next, identify the appropriate dcm files for this subject (for all/relevant runs) 
###

# again iterate over all possible run names
for (( i=0; i<run_num; i++ )); do

	# if called for only specific run, then skip unless matches relevant run
	if [ -n "${do_run}" ] ; then if [ "${all_run_names_arr[$i]}" != "${do_run}" ] ; then continue  ; fi;  fi

	this_runname=${all_run_names_arr[$i]}

	# locate subj_run record for this subject and find which series correspond to that run name
	# also extract what the expected length of this session is
	# if series=0, skip it because it's missing.

	# this grabs the column number that was populated in the loop above (e.g. what column # is the info for 2_rest1 stored, if we are on 2_rest1)
	this_field=${all_run_name_pos_arr[$i]}

	# this looks at the mapping .csv file entry for the current subject and pulls out only that column # we just identified ($this_field)
	# so if column 4 is the column that stores the 2_rest1 series, and if for the current subject the number 23 is stored in that cell, $this_series is going to be set to 23.
	this_series=`grep $subjID ${templatedir}/${subj_run_mapping} | cut -d "," -f${this_field}`

	# sanity check - make sure you actually got data, otherwise abort with error.
	if [ -z "${this_series}" ] ; then echo "ERROR (${subjID}): cannot find $subjID in ${this_runname} mapping file. Exiting..."; exit 1; fi

  # Now start to copy the dicom
  #this_explen=${all_run_names_len_arr[$i]}
	echo "Ready to copy ${subjID} for ${all_run_names_arr[$i]} : session${this_session} series $this_series..."
	this_destdir=${tempdicomdir}/${subjID}/ses-${this_session}

        if ( [ ! -d ${this_destdir} ] && [ ! -z ${this_session} ] ) ; then
           mkdir -p ${this_destdir}
        fi

	# if we have 0 in the relevant cell in the mapping .csv, skip it -- that means we do not have data for this run for this subject.
	if [ "${this_series}" = "0" ] ; then
		echo "WARNING (${subjID} ${do_run}): skipping copyDCM for missing series=0 for ${all_run_names_arr[$i]}"
	else
		this_copydcm $subjID $this_destdir $this_runname $this_session $this_series #$expectedlen
	fi

done

exit 0
