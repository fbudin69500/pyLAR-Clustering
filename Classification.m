#!/usr/bin/octave
arg_list = argv ();
if nargin ~= 1
  printf("Usage: ScriptName filename (e.g.: ~/pyLAR/Clustering/pyLARConfiguration/Healthy-20-29F.txt)\n")
  return
endif
% Run pyLAR once on all the data
result_dir = readConfig(arg_list{1},'result_dir');
% Create classification directory
[status, msg, msgid] = mkdir(result_dir);
if status != 1
  printf("Could not create result_dir %s. %s\n", result_dir, msg )
  return
end
printf("Successfully created directory %s\n",result_dir)
base=regexp(arg_list{1}, '\S*/', 'split','once');
printf("basename: %s\n",base{2})
copy_file_name = sprintf("%s/%s",result_dir,base{2});
printf("Copying %s to %s\n",arg_list{1},copy_file_name)
[status, msg, msgid] = copyfile(arg_list{1},copy_file_name);
if status != 1
  printf("Problem while copying %s. %s\n", arg_list{1}, msg )
  return
end
group = {1};
selection = readConfig(arg_list{1},'selection');
selection_range = size(str2num(selection),2);
printf("selection: %s\n",selection)
printf("selection range: %d\n",selection_range)
group_select{1}=str2num(selection);
#data_dir = readConfig(arg_list{1},'data_dir');
#file_list_file_name = readConfig(arg_list{1},'file_list_file_name');
iter = 0;
all=[1:selection_range]';
previous_groups=all; %initialization to a dummy value for the first loop test to be false
while true
  iter_images_to_cluster = sprintf("imagesToCluster%03d.txt",iter);
  output_file = sprintf("%s/%s",result_dir,iter_images_to_cluster);
  % Removes content of file listing output images
  fid = fopen(output_file, 'w');
  if fid ~= -1
    fclose(fid);
  end
  for i=group
    current=i{:};
    iter_result_dir = sprintf("%s/%02d_%02d",result_dir,iter,current)
    sed_result_dir = strrep(iter_result_dir,'/','\/');
    config = sprintf("%s/%s",result_dir,base{2});
    sed_cmd = sprintf("sed -i 's/result_dir.*/result_dir = \"%s\"/' %s\n",sed_result_dir,config)
    system(sed_cmd);
    str_selection=sprintf('%d,',group_select{current});
    str_selection=str_selection(1:size(str_selection,2)-1);
    sed_cmd = sprintf("sed -i 's/selection.*/selection = [%s]/' %s\n",str_selection,config)
    system(sed_cmd);
#    sed_data_dir = strrep(data_dir,'/','\/');
#    sed_cmd = sprintf("sed -i 's/data_dir.*/data_dir = \"%s\"/' %s\n",sed_data_dir,config)
#    system(sed_cmd);
#    sed_cmd = sprintf("sed -i 's/file_list_file_name.*/file_list_file_name = \"%s\"/' %s\n",file_list_file_name,config)
     system(sed_cmd);
    pyLAR_cmd = sprintf('/home/fbudin/Devel/pyLAR/run.py -a lr -s ~/pyLAR/ConfigFiles/Software.txt -c %s', config )
    system(pyLAR_cmd);
    % Create list containing name of images to cluster
    selection_range = size(str2num(str_selection),2);
    imFile = writeListImages(output_file,iter_result_dir,selection_range);
    % Update values for next iteration
  end
  % The two following lines could be done only once but need to be done after LR runs once
#  data_dir = result_dir;
#  file_list_file_name = iter_images_to_cluster;
  % Cluster result
  addpath('/home/fbudin/pyLAR/Clustering/Octave/loadedData');
  m=LoadNormalFiles(output_file);
  D=double(m);
  [u s v]=svd(D,false);
  addpath('/home/fbudin/pyLAR/Clustering/Octave/Classification/SSC_ADMM_v1.1');
  class=SSC(u'*D,0,false,20,false,1,2);
  % compare new groups with previous group and inverted previous group
  if isequal(class,previous_groups) || isequal(class,3-previous_groups)
    printf("class\n")
    class'
    printf("previous_groups\n")
    previous_groups'
    printf("invert previous group\n")
    [3-previous_groups]'
    printf("Stable results: same as previous iteration %d\n",iter)
    break;
  end
  group={1,2};
  for i=group
    current=i{:};
    # Create new configuration files for pyLAR
    group_select{current}=all(class==current).-1;
  end
  previous_groups = class;
  iter = iter + 1;
end
