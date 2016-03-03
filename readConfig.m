function [v]=readConfig(filename,search_field)

fid = fopen(filename, 'rb');

while (true)

  theLine = fgetl(fid);
  
  if (isempty(theLine) || feof(fid))
    % End of the header.
    break;
  end
  
  if (isequal(theLine(1), '#'))
      % Comment line.
      continue;
  end
  
  % "fieldname= value"
  parsedLine = regexp(theLine, '=?\s*', 'split','once');
  if(size(parsedLine,2) ~= 2)
    % not a line we care about
    continue;
  end
  field = lower(parsedLine{1});
  value = parsedLine{2};
  field(isspace(field)) = '';
  value=strrep(value,'=','');
  value=strrep(value,"'",'');
  value(isspace(value)) = '';
  if(strcmp(field,search_field))
    v = value;
    return
  end
end
