clc;clear; 
ana_dir = 'XX/XX'; % where you put BIDs and other necessary files
rawdata_dir = 'XX/XX'; %
subject_list = [XX/XX '/subjects_XX.list'];
sess='02'; %% mannually change to 01, 02 or 03
fname= [ana_dir '/templates/initial_subs_runs_sess' sess '.csv']; % Your log mapping file
tmp = fopen(fname);
id = textscan(tmp,'%s %*[^\n]','HeaderLines',1,'Delimiter',',');
fclose(tmp);
tmp = fileread(fname);
tmp=regexp(tmp,'\n','split');
scanlabel =regexp(tmp{1},',','split');
dat = dlmread(fname,',',1,1);
if size(dat,2) ~= 30
   dat = padarray(dat,[0 30-size(dat,2)],'post'); 
end
subs = fopen(subject_list);
subs_id = textscan(subs,'%s');
fclose(subs);
subs_id = subs_id{1};
for i = 1:length(subs_id)
    sub = subs_id{i};
    
    fname = [ana_dir '/derivatives/dicominfo_sub-' sub  '_ses-' sess '.tsv'];
    if ~exist(fname, 'file')
       disp(['No ' sub ' for session_' num2str(sess)])
       continue
    end
    disp(sub)
    s = tdfread(fname);
    tmp = s.example_dcm_file;
    series_id = str2num(tmp(:,9:10));
    series_name=cellstr(s.series_description);
    dim4 = s.dim4;

    fldmpPA_curr = nan; fldmpAP_curr = nan;
    sum_sid = zeros(1,30); nrestsb = 8; nrest = 9; nrest_fldmpPA = 6; nrest_fldmpAP = 7;
    for nn = 1:length(series_id)
        if contains(series_name{nn},'FieldMap')
            if contains(series_name{nn},'AP')
               fldmpAP_curr = series_id(nn);
            else
               fldmpPA_curr = series_id(nn);
            end
         elseif contains(series_name{nn},'REST') && ~contains(series_name{nn},'Audiotest')
                if dim4(nn) >=1300                   
                   sum_sid(nrest) = series_id(nn);
                   nrest = nrest+12;
 
                    nrest_fldmpPA = nrest_fldmpPA+12;
                    nrest_fldmpAP = nrest_fldmpAP+12;
                  if contains(series_name{nn-1},'SBRef')
                     sum_sid(nrestsb) = series_id(nn-1);
                     nrestsb = nrestsb+12;   
                   end
                end
         elseif contains(series_name{nn},'TRAILER')
                if contains(series_name{nn},'SBRef')
                   sum_sid(12) = series_id(nn);
                else                   
                   sum_sid(13) = series_id(nn);
                   if contains(series_name{nn-2},'FieldMap')
                      sum_sid(10) = fldmpPA_curr;
                      sum_sid(11) = fldmpAP_curr;  
                   else 
                       sum_sid(10) = 0;
                       sum_sid(11) = 0;
                   end
                end
         elseif contains(series_name{nn},'OFFICE')
                if contains(series_name{nn},'SBRef')
                   sum_sid(16) = series_id(nn);
                else
                   sum_sid(17) = series_id(nn);
                   if contains(series_name{nn-2},'FieldMap')
                      sum_sid(14) = fldmpPA_curr;
                      sum_sid(15) = fldmpAP_curr; 
                    else 
                       sum_sid(14) = 0;
                       sum_sid(15) = 0;
                   end
                end 
         elseif contains(series_name{nn},'PIXAR')
                if contains(series_name{nn},'SBRef')
                    sum_sid(24) = series_id(nn);
                else
                   sum_sid(25) = series_id(nn);
                   if contains(series_name{nn-2},'FieldMap')
                      sum_sid(22) = fldmpPA_curr;
                      sum_sid(23) = fldmpAP_curr;  
                   else 
                      sum_sid(22) = 0;
                      sum_sid(23) = 0;
                   end
                end
         elseif contains(series_name{nn},'BANG')
                if contains(series_name{nn},'SBRef')
                   sum_sid(28) = series_id(nn);
                else
                   sum_sid(29) = series_id(nn);
                   if contains(series_name{nn-2},'FieldMap')
                      sum_sid(26) = fldmpPA_curr;
                      sum_sid(27) = fldmpAP_curr;  
                   else 
                      sum_sid(26) = 0;
                      sum_sid(27) = 0;
                   end  
                end  
          elseif contains(series_name{nn},'tfl_mgh_multiecho')
                sum_sid(1) = series_id(nn);            
          elseif contains(series_name{nn},'T2')
                sum_sid(2) = series_id(nn);  
          elseif contains(series_name{nn},'DWI')
               if contains(series_name{nn},'B0_only')
                  sum_sid(4) = series_id(nn);
               else
                  sum_sid(3) = series_id(nn);
               end
         end      
    end

    tmp_id =find(contains(id,sub));
    diff = dat(tmp_id,:)-sum_sid;
    if isempty(diff)
        disp(['empty for subject' sub ])
    elseif sum(diff,2) ~= 0 
       disp([ 'ERROR for subject ' sub  ])
       label_id = find(diff ~= 0);
       disp(scanlabel(label_id+1));
       disp([num2str(dat(tmp_id,label_id)), ' in csv'])
       disp([num2str(sum_sid(label_id)), ' in tsv'])
    end
end
