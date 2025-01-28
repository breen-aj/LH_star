%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Authors: William John Davids, Andrew Breen
% 22/02/25
% The University of Sydney 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% funciton to read RRNG file format. 

% Outputs: 

% bands - cell strcuture giving the mass to charge state lower and
% upper limits for each element in the RRNG file. Each new element has its
% own cell in 'bands'. Cells are all matricies sized nx2 where n is the
% number of mass to charge state ranges for that particular element

% elNames - Element names, order corresponding to same order in bands 

% Inputs:

% elWant - optional input, specify which elements whithin the range file
% the user is unterested in. The output of the function will be only the
% mass to charge state ranges for those elements of interest

%molecular ions:
%Code assumes elemental ions and does not automatically process molecular ions. For molecular
%ions - manually split up the range in into single/elemental ion components using a text editor OR modify the below code to handle molecular ion species 
%e.g.
%Number=14 
%...
%Range8=30.9090 33.1000 Vol:0.04650 Ti:1 O:1 Color:FF0000
%Range9 = ...
%...

%would become
%Number=15 
%...
%Range8=30.9090 33.1000 Vol:0.01767 Ti:1 Color:FF0000
%Range9=30.9090 33.1000 Vol:0.02883 O:1 Color:FF0000
%Range10 = ...
%...



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [bands, allBands, elNames, file_name] = readrange_rrng_2024(elWant)

    % select the rrng file
    [file, path, ~] = uigetfile({'*.rrng'},'Select a rrng file');
    file_name = [path file];

    [data,~]=readtext(file_name,' ');
    % change this so it find numbers to right of = sign 
    nelementsText = data{2,1};
    % find '=' sign, take numbers to the right of it 
    logicEq = nelementsText == '=';
    idx = 1:length(logicEq);
    nelements = str2double(nelementsText(idx(logicEq)+1:end));
    nrangesText = data{nelements+5,1};
    % find '=' sign
    logicEq = nrangesText == '=';
    idx = 1:length(logicEq);
    nranges = str2double(nrangesText(idx(logicEq)+1:end));
    
    rangesStart = nelements+6;
    
    ranges = zeros(nranges,2);
    elNames = cell(nelements,1);
    elements = cell(nranges,1);
    bands = cell(1,nelements);
    % get element names 
    for ii = 1:nelements
        elText = data{ii+2,1};
        logicEq = elText == '=';
        idx = 1:length(logicEq);
        elNames{ii} = elText(idx(logicEq)+1:end);
       
    end
    
    for ii = 1:nranges
        % lower bound
        lowerText = data{ii+rangesStart-1,1};
        logicEq = lowerText == '=';
        idx = 1:length(logicEq);
        ranges(ii,1) = str2double(lowerText(idx(logicEq)+1:end));
        
        % upper bound 
        ranges(ii,2) = data{ii+rangesStart-1,2};
        
        elText = data{ii+rangesStart-1,4};
        logicEq = elText == ':';
        idx = 1:length(logicEq);
        elements{ii,1} = elText(1:idx(logicEq)-1);
    end
    
    % sort elements into bands 
    for ii = 1:nelements
    
        idxEl = strcmp(elements,elNames{ii});
        bands{ii} = ranges(idxEl,:);
        
    end
    
    % take only the elements the user wants, ditch the others 
    if exist('elWant','var')
        elWant = elWant';
        for ii = 1:length(elWant)
            if strcmp(elWant(ii),'X')
                break
            end
            idxEl = strcmp(elNames,elWant{ii});
            bandsWant{ii} = bands{idxEl};
            
        end
      elNames = elWant'; 
      allBands = bands;
      bands = bandsWant;
    end

    
    