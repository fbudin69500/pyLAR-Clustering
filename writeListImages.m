function [filename]=writeListImages(filename, iter_result_dir, my_range)
printf("Opening: %s\n",filename)
fid = fopen(filename, 'a');
for i =0:my_range-1
  fprintf(fid,"%s/L_LowRank_%d.nrrd\n",iter_result_dir,i)
end
fclose(fid)
