function cleanup_PNM4D(numevs, epiFile, covFolder)
% cleanup_PNM4D - Regress out physiological noise from fMRI data using PNM4D regressors.
%
% Usage: cleanup_PNM4D(numevs, epiFile, covFolder)
%
% Inputs:
%   numevs    - Number of EV (explanatory variable) files (physiological regressors) to process.
%   epiFile   - (Optional) Filename of the input EPI image (NIfTI) 
%               [Default: './sub-001_task-right-pain_bold.nii.gz']
%   covFolder - (Optional) Folder containing the PNM EV files (voxel covariates)
%               [Default: current directory appended with 'pnm_regressors']
%
% This function performs the following steps:
%   1. Reads the input EPI image.
%   2. Loads each of the specified PNM EV files from the covariate folder.
%   3. Uses GLMcleanup to regress out physiological noise from the 4D fMRI data.
%   4. Saves the cleaned 4D fMRI data to disk.
%
% Author: Yazhuo Kong, FMRIB, Oxford
% Modified by: Zhaoxing Wei, CAS
% Date: 04/11/2011 version 1.0; 01/30/2025 version 2.0
%
% Example:
%   cleanup_PNM4D(5, 'sub-001_task-example_bold.nii.gz', './pnm_regressors')
%

% Set default values if optional inputs are not provided
if nargin < 2 || isempty(epiFile)
    epiFile = './sub-001_task-right-pain_bold.nii.gz';
end
if nargin < 3 || isempty(covFolder)
    covFolder = fullfile(pwd, 'pnm_regressors');
end

% Get the current directory
currentPath = pwd;

% Display the selected EPI file information
disp(['User selected EPI file: ', fullfile(currentPath, epiFile)]);

% Construct the full path to the EPI file
epiFullFile = fullfile(currentPath, epiFile);

% Read the EPI image using read_avw (FSL function)
[all_images, all_images_dims, iscales, ibpp, iendian] = read_avw(epiFullFile);
numvols = all_images_dims(4);   % Number of volumes (timepoints)
numslices = all_images_dims(3);   % Number of slices

% Display the selected covariate folder (where EV files are stored)
disp(['Using covariate folder: ', covFolder]);

% Set the folder where the EV files are stored
savefolder = covFolder;

% Initialize a 3D matrix to store all EV regressors.
% Dimensions: [number of EVs x number of slices x number of volumes]
bigmat = zeros(numevs, numslices, numvols);

% Loop over each EV file and load the data
for ev = 1:numevs
    % Format the EV number with leading zeros (e.g., '001', '002', etc.)
    evFormatted = num2str(ev, '%03d');
    % Construct the filename for the EV file (e.g., 'pnmev001')
    evfilename = fullfile(savefolder, ['pnmev', evFormatted]);
    disp(['Loading EV file: ', evfilename]);
    % Read the EV file using read_avw
    tmp = read_avw(evfilename);
    % Remove singleton dimensions (if any)
    tmp = squeeze(tmp);
    % Store the EV data in the big matrix
    bigmat(ev, :, :) = tmp;
end

% Initialize a 4D matrix for the cleaned fMRI data.
% The dimensions are: x-dim, y-dim, z-dim, and time (volumes)
res4d = zeros([all_images_dims(1), all_images_dims(2), all_images_dims(3), numvols]);

% Use GLMcleanup to regress out the physiological noise using the EVs
res4d = GLMcleanup(all_images, bigmat);

% Construct the output filename for the cleaned 4D data
savename = fullfile(savefolder, 'res4d_new');
% Save the cleaned 4D fMRI data using save_avw (FSL function)
save_avw(res4d, savename, 'f', iscales(1:4));

disp(['New cleaned 4D fMRI data was saved as: ', savename]);

clear;