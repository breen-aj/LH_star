# LH_star
Matlab code to perform LH_star analysis to statistically quantify solute non-randomness in atom probe tomography (APT) data.

Please refer to the following journal article for details on the LH* test statistic and its application to atom probe tomography data:

*Link will be provided once paper is published*

# How to use the code

Download the repository and add the code to your read path in MATLAB.
Have the .pos and .rrng range file of interest in your current folder (workind directory) in matlab. 
open LHstatCheckerboard_GITHUB.m in the editor.
adjust variables in top section to suit.

recommended usage:
run code to line 370. The LH checkerboard statistics will be outputted on screen. The data outputs from the calculations will be saved to a .mat file at this point. 
You can then 'run section' for the analysis of interest. Some sections need to be run before a subsequent section is run. e.g. 'Plotting G functions of specific pairs' calculates sig cell variables and needs to be run before sections which call these cell variables. 

It is set up this way so the simulations only have to be calculated once. On subsequent usage just load the .mat file and 'run section' for the analysis of interest. 

Read in-text comments for further details of code. 

# test data
The dataset used in figure 4 of the publication is provided at the following link:

[test data](https://unisyd-my.sharepoint.com/:f:/g/personal/andrew_breen_sydney_edu_au/EumOEhQ5e7xKh4w7EESb7qoBQgJnCzfB2OagDHLDvtpnKQ?e=zIJnuM)

It is an electron powder bed fusion produced Ti-6Al-4V (wt.%) dataset, collected on a CAMECA LEAP 4000 X Si atom probe at the University of Sydney. 
The default state of the code is set up to look at this data.


# Other information
The code has been built and tested on MATLAB R2020a, R2024b
The code can serve as a template for calculating LH* statistics for multicomponent APT data. We recommend running the test data first -which has been tested and works before trying to apply the code to your dataset of interst. 
For more information/help please email will.davids@infravue.com 











