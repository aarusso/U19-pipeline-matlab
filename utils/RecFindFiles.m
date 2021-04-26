function filelist = RecFindFiles(path, pattern, filelist, depth, verbose)
    % Lists all files in the repository path, that contains the string pattern.
    % The results are appended to 'Filelist', and depth in decreased.
    if nargin < 5
        verbose = 1;
    end
    
    [listdir, listfile] = FindFiles(path, pattern); % Lists content of this hirarchy
    for file = listfile
        filelist{end+1} = file;
    end
    if depth>0
        for dir = listdir
            if verbose
                disp(['Looking at ', dir{1}, ' ... and continuing.'])
            end
            filelist = RecFindFiles(dir{1}, pattern, filelist, depth-1, verbose);
        end
    end
end





function [listdir, listfile] = FindFiles(reper, stc)
    % Helperfunction to list local files in directory reper
    % constrained by the string "stc"
    S=dir(reper);
    %separate sub-folders of reper and files
    n=size(S,1);
    listdir=cell(1,n);      % list of sub-folders
    listfile=cell(1,n);     % list of files
    nd=0;
    nf=0;
    for i=1:n
        name=S(i).name;
        if S(i).isdir
            if strcmp(name,'.')  % remove current folder (.)
                continue;
            end
            if strcmp(name,'..') % remove parent folder (..)
                continue;
            end
            nd=nd+1;
            listdir{nd}=fullfile(reper,S(i).name);
        else
            ii=strfind(name,stc);
            if isempty(ii)
                continue;
            end
            %disp(['Found: ', name, ' ... and continuing.']);
            nf=nf+1;
            listfile{nf}=fullfile(reper,S(i).name);
        end
    end
    %reorder results
    listdir(nd+1:end)=[];
    listfile(nf+1:end)=[];
end