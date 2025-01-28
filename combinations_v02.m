% element pairs
noElements = length(elWant);

% initialize index 
ii = 1;

% loop through each element 
for i = 1:noElements
    
    % get perms without repetitions
    matrix = nchoosek(1:noElements,i);
    
    % form combination cells 
    for j = 1:size(matrix,1)
    combination{ii}=matrix(j,:);
    ii = ii+1;
    end
    
end

if incUnranged
    noElements = noElements-1;
end