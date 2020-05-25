import os

def create_key(template, outtype=('nii.gz',), annotation_classes=None):
    if template is None or not template:
        raise ValueError('Template must be a valid format string')
    return template, outtype, annotation_classes


def infotodict(seqinfo):
    """Heuristic evaluator for determining which runs belong where

    allowed template fields - follow python string module:

    item: index within category
    subject: participant id
    seqitem: run number during scanning
    subindex: sub index within group
    """

    # anat
    t1 = create_key('sub-{subject}/{session}/anat/sub-{subject}_{session}_T1w')
    t1alter = create_key('sub-{subject}/{session}/anat/sub-{subject}_{session}_acq-alter_T1w')
    t2 = create_key('sub-{subject}/{session}/anat/sub-{subject}_{session}_T2w')

    # func
    rest = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-rest_run-{item:01d}_bold')
    trailer = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-trailer_run-{item:01d}_bold')
    office = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-office_run-{item:01d}_bold')
    pixar = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-pixar_run-{item:01d}_bold')
    bang = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-bang_run-{item:01d}_bold')

    # dwi -- *** THIS IS NOT QUITE RIGHT YET BUT NOT IMPORTANT RIGHT NOW ***
    dwi80ap = create_key('sub-{subject}/{session}/dwi/sub-{subject}_{session}_acq-dir80ap_dwi')
    dwi80pab0 = create_key('sub-{subject}/{session}/dwi/sub-{subject}_{session}_acq-dir80pab0_dwi')

    # sbref
    restsb = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-rest_run-{item:01d}_sbref')
    trailersb = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-trailer_run-{item:01d}_sbref')
    officesb = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-office_run-{item:01d}_sbref')
    pixarsb = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-pixar_run-{item:01d}_sbref')
    bangsb = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-bang_run-{item:01d}_sbref')

    # fieldmap - NOTE these will need further processing; need extra script to add IntendedFor to .json
    fmap_ap = create_key('sub-{subject}/{session}/fmap/sub-{subject}_{session}_dir-AP_run-{item:01d}_epi')
    fmap_pa = create_key('sub-{subject}/{session}/fmap/sub-{subject}_{session}_dir-PA_run-{item:01d}_epi')

    info = {t1: [], t2: [], t1alter: [],
            rest: [], trailer: [], office: [], pixar: [], bang: [], dwi80ap: [], dwi80pab0: [],
            restsb: [], trailersb: [], officesb: [], pixarsb: [], bangsb: [],
            fmap_ap: [], fmap_pa: []
    }

#    for s in seqinfo:
#        """
#        The namedtuple `s` contains the following fields:
#
#        * total_files_till_now
#        * example_dcm_file
#        * series_id
#        * dcm_dir_name
#        * unspecified2
#        * unspecified3
#        * dim1
#        * dim2
#        * dim3
#        * dim4
#        * TR
#        * TE
#        * protocol_name
#        * is_motion_corrected
#        * is_derived
#        * patient_id
#        * study_description
#        * referring_physician_name
#        * series_description
#        * image_type
#        """
#
#        info[data].append(s.series_id)

    for idx, s in enumerate(seqinfo):

      is_sbref = 'SBRef' in s.series_description

      # ignore audiotest and scout
      if 'Scout' in s.series_description:
         pass
      elif 'Audiotest' in s.series_description:
         pass

      # t1
      elif 'tfl_mgh_multiecho' in s.series_description:
         if (s.dim3 > 170) and (s.dim4 ==1):
            if info[t1] is not None:
               info[t1]=[s.series_id]
     # another t1
      elif 'tfl3d_nsIR_sag' in s.series_description:
         info[t1alter] = [s.series_id]
         
      # t2
      elif 'T2w_SPC' in s.series_description:
         info[t2] = [s.series_id]

      elif 'SpinEchoFieldMap' in s.series_description:
         if 'AP' in s.series_description:
           info[fmap_ap].append(s.series_id)
         else:
           info[fmap_pa].append(s.series_id)

      # diffusion
      elif 'DWI' in s.series_description:
         if 'B0_only' in s.series_description:
            info[dwi80pab0] = [ s.series_id ]
         else:
            info[dwi80ap] = [ s.series_id ]

      # func
      elif 'rfMRI_REST' in s.series_description:
         if is_sbref:
            info[restsb].append(s.series_id)
         else:
            info[rest].append(s.series_id)

      elif 'rfMRI_TRAILER' in s.series_description:
         if is_sbref:
            info[trailersb].append(s.series_id)
         else:
            info[trailer].append(s.series_id)

      elif 'rfMRI_OFFICE' in s.series_description:
         if is_sbref:
            info[officesb].append(s.series_id)
         else:
            info[office].append(s.series_id)

      elif 'rfMRI_PIXAR' in s.series_description:
         if is_sbref:
            info[pixarsb].append(s.series_id)
         else:
            info[pixar].append(s.series_id)

      elif 'rfMRI_BANG' in s.series_description:
         if is_sbref:
            info[bangsb].append(s.series_id)
         else:
            info[bang].append(s.series_id)

    return info
