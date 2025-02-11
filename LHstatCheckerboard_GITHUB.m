%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Author: Will Davids, Andrew Breen
% The University of Sydney
% 28/01/2025

% Code to create LH stat checkerboard 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function [RDF, edges, RDFR, edgesR] = elSpecific3dSDM(kNN, elSolute, nBins, lc)
clear all; close all

kNN = 1; %select which kNN distribution to perform analysis - typically 1 is selected

elSolute = {'Al','V','Fe','O'}; %select the solute species of interest

runPairsOnly = true;
saveOutput = true; 
filename = 'testSLM_1NN_100sims'; %filename to save output to - update NN and number of sims to suite

chopData = true; %do you want to crop the dataset - see chopData section for dim inputs.

LELH = true; % Leading-Edge LH* (true/false)
NLH = true; % Normalised LH* (true/false)
R = 100; % number of simulations - typically above 100 simulations are used

%% read pos 
if ~exist('inFloats', 'var')
    
   inFloats = readpos; % read in non-randomised POS first

end
%% function start
%function output = LHstat(inFloats,kNN)
nBins = kNN/100 * 2000;
XYZ = inFloats(:,1:3); % (X,Y,Z) atomic positions
m2c = inFloats(:,4);   % mass-to-charge state ratio
nBins = 100;

%% Chop data

if chopData
    offset = (max(XYZ(:,1))+min(XYZ(:,1)))/2;
    x = XYZ(:,1); y = XYZ(:,2); z = XYZ(:,3);
    box = 60; %nm 60 for 58131
chop = x <= box/2 + offset & x >= -box/2 + offset & y <= box/2 + offset & y >= -box/2 + offset & z <= mean(z)+box/2 & z >= mean(z)-box/2;
XYZ = XYZ(chop,:);
m2c = m2c(chop);
end
%%

% read rrng in
[bands, ~,elNames] = readrange_rrng_2024(elSolute);

%% establish combinations 
elWant = elSolute; incUnranged = false;
combinations_v02
if runPairsOnly
    combination = combination(1:length(elSolute));
end

%% IDX of solute atoms in xyz
idxSolute = zeros(length(XYZ),length(elNames));
for jj = 1:length(elNames)
[rows,~] = size(bands{jj});
for ii = 1:rows
    idxSoluteT(:,ii) = m2c >= bands{jj}(ii,1) & m2c <= bands{jj}(ii,2);
end
idxSolute(:,jj) = logical(sum(idxSoluteT,2)); % indexs of all solute atoms in the POS file for each element (jj)
clear idxSoluteT 
end
idxSolute = logical(idxSolute);




m2cR = m2c;



for ii = 1:R

%% randomise m2c column
%m2cR = m2cR(randperm(length(XYZ))');
r_sample = randsample(1:length(m2c),length(m2c));
m2cR = m2c(r_sample);

%% find which atoms are solute in this simulation 
idxSoluteR = zeros(length(XYZ),length(elNames));
for jj = 1:length(elNames)
[rows,~] = size(bands{jj});
for ix = 1:rows
    idxSoluteRT(:,ix) = m2cR >= bands{jj}(ix,1) & m2cR <= bands{jj}(ix,2);
end
idxSoluteR(:,jj) = logical(sum(idxSoluteRT,2));
clear idxSoluteRT
end
idxSoluteR = logical(idxSoluteR);

%% find NNs
for iComR = 1:length(combination)
    idxR = logical(sum(idxSoluteR(:,combination{iComR}),2));
    
    if ii==1
        idxR_obs = logical(sum(idxSolute(:,combination{iComR}),2));
    end
    
    for iComNN = 1:length(combination)
        idxNN = logical(sum(idxSoluteR(:,combination{iComNN}),2));
        
        [~,dists_soluteR] = knnsearch(XYZ(idxNN,1:3),XYZ(idxR,1:3),'k',kNN+1);
        dists_soluteR(:,1) = [];
        %clear idxSoluteR
        ik=kNN;
        %% Calculate Gi(w)
        if ii==1 % set edges from first simulation
            [~,edgesT]=histcounts(dists_soluteR(:),nBins);
            edges{iComNN,iComR}=edgesT;
            
         
            idxNN_obs = logical(sum(idxSolute(:,combination{iComNN}),2));
            
            
            % calculate histogram for observed so we can tell where the leading edge is
            [~,dists_solute] = knnsearch(XYZ(idxNN_obs,1:3),XYZ(idxR_obs,1:3),'k',kNN+1);
            dists_solute(:,1) = [];
            dE = dists_solute(:,ik);
            n = histcounts(dE,edges{iComNN,iComR});
            [~,idx] = max(n);
            edgeLEt = edges{iComNN,iComR}(idx+1);
            edgeLE{iComNN,iComR} = edges{iComNN,iComR} <= edgeLEt;
            edgeLE{iComNN,iComR} = edgeLE{iComNN,iComR}';
            
            % calc intensity for NLH*
            if NLH
                
                    [~,V]=convhull(XYZ(logical(sum([idxNN_obs, idxR_obs],2)),:)); % volume of study area
                    int(iComNN,iComR) = sum(sum([idxNN_obs, idxR_obs],2))/V; % intensity
               
            end
        end


dR = dists_soluteR(:,ik);
nR=histcounts(dR,edges{iComNN,iComR});
nRsave{iComNN,iComR,ii} = nR';
Giw{iComNN,iComR,ii} = cumsum(nR);


Giw{iComNN,iComR,ii} = Giw{iComNN,iComR,ii} ./ max(Giw{iComNN,iComR,ii});
Giw{iComNN,iComR,ii} = Giw{iComNN,iComR,ii}';
if ik>1
dRC = dists_soluteR(:,1:ik);
nRC = histcounts(dRC(:),edges{iComNN,iComR});
GiwC{iComNN,iComR,ii} = cumsum(nRC);
GiwC{iComNN,iComR,ii} = GiwC{iComNN,iComR,ii} ./ max(GiwC{iComNN,iComR,ii});
GiwC{iComNN,iComR,ii} = GiwC{iComNN,iComR,ii}';
end
end

end
disp(['Simulations complete: ', num2str(ii)]);
% end of simulations
end

%% Calculating the average G function for random curves

for iComR = 1:length(combination)
    for iComNN = 1:length(combination)
        for iSim = 1:R
            if iSim == 1
                total{iComNN,iComR} = Giw{iComNN,iComR,iSim};
                if kNN> 1
                    totalC{iComNN,iComR} = GiwC{iComNN,iComR,iSim};
                end
            else
                total{iComNN,iComR} = total{iComNN,iComR} + Giw{iComNN,iComR,iSim};
                if kNN>1
                    totalC{iComNN,iComR} = totalC{iComNN,iComR} + GiwC{iComNN,iComR,iSim};
                end
            end

        end
        Gbar{iComNN,iComR} = total{iComNN,iComR} ./ R;
        if kNN>1
            GbarC{iComNN,iComR} = totalC{iComNN,iComR} ./ R;
        end
    end
end


%% Monte Carlo simulation approach to calculate p-value
% calc LH test statistic for each random vs mean G function
for iComR = 1:length(combination)
    for iComNN = 1:length(combination)
        for ii = 1:R
            % intergrate: sum up absolute differences in curves
            LH_star(iComNN,iComR,ii) = sum(abs((Giw{iComNN,iComR,ii} - Gbar{iComNN,iComR}) .* (edges{iComNN,iComR}(2) - edges{iComNN,iComR}(1))));
            
            
            if LELH
                diff = Giw{iComNN,iComR,ii}(edgeLE{iComNN,iComR}) - Gbar{iComNN,iComR}(edgeLE{iComNN,iComR});
                LELH_area(iComNN,iComR,ii) = sum((Giw{iComNN,iComR,ii}(edgeLE{iComNN,iComR}) - Gbar{iComNN,iComR}(edgeLE{iComNN,iComR})) .* (edges{iComNN,iComR}(2) - edges{iComNN,iComR}(1)));
                % only take possitive differences
                LELHu_star(iComNN,iComR,ii) = sum((diff(diff > 0).* (edges{iComNN,iComR}(2) - edges{iComNN,iComR}(1))));
                LELHl_star(iComNN,iComR,ii) = abs(sum((diff(diff < 0).* (edges{iComNN,iComR}(2) - edges{iComNN,iComR}(1)))));
            end
            
            if NLH
                GiwDash{iComNN,iComR,ii} = Giw{iComNN,iComR,ii}.*2*int(iComNN,iComR)^(0.5);
                NLH_star(iComNN,iComR,ii) = sum(abs((GiwDash{iComNN,iComR,ii} - (Gbar{iComNN,iComR}.*2*int(iComNN,iComR)^(0.5))) .* (edges{iComNN,iComR}(2) - edges{iComNN,iComR}(1))));
            end
            
            
            if kNN>1
                LH_starC(iComNN,iComR,ii) = sum(abs((GiwC{iComNN,iComR,ii} - GbarC{iComNN,iComR}) .* (edges{iComNN,iComR}(2) - edges{iComNN,iComR}(1))));
            end
        end
    end
end

%% calc LH_star for obs value
for iComR = 1:length(combination)
    idxR = logical(sum(idxSolute(:,combination{iComR}),2));
    
    for iComNN = 1:length(combination)
        idxNN = logical(sum(idxSolute(:,combination{iComNN}),2));
        
        [~,dists_solute] = knnsearch(XYZ(idxNN,1:3),XYZ(idxR,1:3),'k',kNN+1);
        dists_solute(:,1) = [];


dE = dists_solute(:,kNN);
n = histcounts(dE,edges{iComNN,iComR});
nSave{iComNN,iComR} = n;
Ghat{iComNN,iComR} = cumsum(n); % observed G function 
Ghat{iComNN,iComR} = Ghat{iComNN,iComR}';
Ghat{iComNN,iComR} = Ghat{iComNN,iComR} ./ max(Ghat{iComNN,iComR});
LH_star_obvs(iComNN,iComR) = sum(abs((Ghat{iComNN,iComR} - Gbar{iComNN,iComR}) .* (edges{iComNN,iComR}(2) - edges{iComNN,iComR}(1)))); 

% p value
pLH(iComNN,iComR) = (1+sum(LH_star(iComNN,iComR,:) >= LH_star_obvs(iComNN,iComR)))/(1+R); 

if LELH
diff = Ghat{iComNN,iComR}(edgeLE{iComNN,iComR}) - Gbar{iComNN,iComR}(edgeLE{iComNN,iComR});
LELHu_star_obvs{iComNN,iComR} = sum((diff(diff > 0).* (edges{iComNN,iComR}(2) - edges{iComNN,iComR}(1)))); 
LELHl_star_obvs{iComNN,iComR} = abs(sum((diff(diff < 0).* (edges{iComNN,iComR}(2) - edges{iComNN,iComR}(1))))); 
pLELHu(iComNN,iComR) = (1+sum(LELHu_star(iComNN,iComR,:) >= LELHu_star_obvs{iComNN,iComR}))/(1+R); 
pLELHl(iComNN,iComR) = (1+sum(LELHl_star(iComNN,iComR,:) >= LELHl_star_obvs{iComNN,iComR}))/(1+R);
end
if NLH
    GhatDash{iComNN,iComR} = Ghat{iComNN,iComR}.*2*int(iComNN,iComR)^(0.5);
    NLH_star_obvs{iComNN,iComR} = sum(abs((GhatDash{iComNN,iComR} - (Gbar{iComNN,iComR}.*2*int(iComNN,iComR)^(0.5))) .* (edges{iComNN,iComR}(2) - edges{iComNN,iComR}(1))));
    pNLH(iComNN,iComR) = (1+sum(NLH_star(iComNN,iComR,:) >= NLH_star_obvs{iComNN,iComR}))/(1+R); 
end

if kNN>1
    dEC = dists_solute(:,1:kNN);
    nC=histcounts(dEC(:),edges{iComNN,iComR});
    GhatC{iComNN,iComR} = cumsum(nC);
    GhatC{iComNN,iComR} = GhatC{iComNN,iComR}';
    GhatC{iComNN,iComR} = GhatC{iComNN,iComR} ./ max(GhatC{iComNN,iComR});
    LH_star_obvsC(iComNN,iComR) = sum(abs((GhatC{iComNN,iComR} - GbarC{iComNN,iComR}) .* (edges{iComNN,iComR}(2) - edges{iComNN,iComR}(1)))); 
    pValueC(iComNN,iComR)  = (1+sum(LH_starC(iComNN,iComR,:) >= LH_star_obvsC(iComNN,iComR)))/(1+R); 
end

    end
end





%% plot checkerboard 
dataMat(:,:,1) = pLH;
dataMat(:,:,2) = pLELHu;
dataMat(:,:,3) = pLELHl;
dataMat(:,:,4) = pNLH;

titleNames = {'LH','LELHp','LELHn','NLH'};
marker = {'x','o','o','x'};
for jj = 1:length(titleNames)
figure

data=dataMat(:,:,jj); % pLH/pLELHu/pLELHl/pNLH
ALPHA=0.05;
names = cell(length(combination),1);
for ii = 1:length(combination)
    indexSelect = combination{ii}; 
    
    names(ii) = cellstr([elNames{indexSelect}]);
end

h(ii)=imagesc(data);
xticks(1:length(names))
xticklabels(names)
xtickangle(0)
set(gca,'XAxisLocation','top')
yticks(1:length(names))
yticklabels(names)
colormap('hot')
h1=colorbar;
title(h1,'p-Value')
caxis([0 1])
xlabel('Reference atom type')
ylabel('NN atom type')
set(gca,'fontsize',12)
set(gca, 'FontName', 'Arial')
title(titleNames{jj})

[rowC,colC]=find(data<=ALPHA);  % ordered


hold on;
if jj==2
plot(colC,rowC,[marker{jj},'w'],'markersize',6,'markerfacecolor','w')
else
    plot(colC,rowC,[marker{jj},'w'],'markersize',6)
end
end

%% Plotting combined figure
figure

data=pLH; % pLH/pLELHu/pLELHl/pNLH
ALPHA=0.05;
names = cell(length(combination),1);
for ii = 1:length(combination)
    indexSelect = combination{ii}; 
    
    names(ii) = cellstr([elNames{indexSelect}]);
end

h(ii)=imagesc(data);
xticks(1:length(names))
xticklabels(names)
xtickangle(0)
set(gca,'XAxisLocation','top')
yticks(1:length(names))
yticklabels(names)
colormap('hot')
h1=colorbar;
title(h1,'p-Value')
caxis([0 1])
xlabel('Reference atom type')
ylabel('NN atom type')
set(gca,'fontsize',12)
set(gca, 'FontName', 'Arial')
%title(titleNames{jj})
clear dataMat
dataMat(:,:,1) = (pLELHu < ALPHA) .* (pLELHl > ALPHA); % reject pos but accept neg
dataMat(:,:,2) = (pLELHl < ALPHA) .* (pLELHu > ALPHA); % reject neg and accept pos
dataMat(:,:,3) = (pLELHu < ALPHA) .* (pLELHl < ALPHA); % reject pos and rejct neg
dataMat(:,:,4) = (pLH < ALPHA) - (pLELHu < ALPHA) - (pLELHl < ALPHA); % reject LH and accept pos and neg
marker = {'^','v','o','p'};
for jj = 1:4

   [rowC,colC]=find(dataMat(:,:,jj)==1);  
hold on;
if jj==2
plot(colC,rowC,[marker{jj},'w'],'markersize',6,'markerfacecolor','w')
else
plot(colC,rowC,[marker{jj},'w'],'markersize',6)
end
end

%% Save data 
if saveOutput 
   save(filename,'idxSolute','names','pLH','pLELHu','pLELHl','pNLH','edges','Giw','Gbar','Ghat','edgeLE','nRsave','nSave','R') 
end

%% Plotting G functions of specific pairs 
figure;hold on
%inAll=[1,2,3];
%irAll=[1,2,3];
inAll=[1];
irAll=[1];
for in_i = 1:length(inAll)
    nRbar_temp = [];
    in = inAll(in_i);
    ir = irAll(in_i);
for ii=1:R
plot(edges{in,ir}(2:end),Giw{in,ir,ii},'.-r');
nRbar_temp = [nRbar_temp, Giw{in,ir,ii}];
end
sig{in,ir} = std(nRbar_temp,[],2);
plot(edges{in,ir}(2:end),Gbar{in,ir},'.-g')
plot(edges{in,ir}(2:end),Ghat{in,ir},'.-k')
end
% the leading edge cut off:
leCut=edges{in,ir}(edgeLE{in,ir});
leCut = leCut(end);
xlabel('d [nm]'); ylabel('CDF')

%% (E-R)/sig plot for G functions 
figure;hold on
%inAll=[1,2,3];
%irAll=[1,2,3];
inAll=[1];
irAll=[1];
idxc = {'k','r','b'};
for in_i = 1:length(inAll) 
in = inAll(in_i);
ir = irAll(in_i);
plot(edges{in,ir}(2:end),(Ghat{in,ir}-Gbar{in,ir})./sig{in,ir},['.-',idxc{in_i}])
end

%% Plotting NN dists 
nRbar = cell(3);
figure;hold on
%inAll=[1,2,3];
%irAll=[1,2,3];
inAll=[1];
irAll=[1];
for in_i = 1:length(inAll)
    nRbar_temp = [];
    in = inAll(in_i);
    ir = irAll(in_i);
for ii=1:R
plot(edges{in,ir}(2:end),nRsave{in,ir,ii},'.-r');
nRbar_temp = [nRbar_temp, nRsave{in,ir,ii}];
end
nRbar{in,ir} = mean(nRbar_temp,2);
sig{in,ir} = std(nRbar_temp,[],2);
plot(edges{in,ir}(2:end),nRbar{in,ir},'.-b');
plot(edges{in,ir}(2:end),nSave{in,ir},'.-k')
end
% the leading edge cut off:
leCut=edges{in,ir}(edgeLE{in,ir});
leCut = leCut(end);
xlabel('d [nm]'); ylabel('Frequency')

%% (E-R)/sig plot for NN distributions  
figure;hold on
%inAll=[1,2,3];
%irAll=[1,2,3];
inAll=[1];
irAll=[1];
idxc = {'k','r','b'};
for in_i = 1:length(inAll) 
in = inAll(in_i);
ir = irAll(in_i);
plot(edges{in,ir}(2:end),(nSave{in,ir}'-nRbar{in,ir})./sig{in,ir},['.-',idxc{in_i}])
end


