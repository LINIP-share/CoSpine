The CoSpine repository provides a set of MATLAB and Shell scripts for preprocessing the cortico-spinal fMRI data, specifically for Physiological Noise Modeling (PNM). PNM aims to identify and remove physiological noise, such as heartbeats, and respiration, that can interfere with primary data (e.g., brain or spinal signals). This repository includes tools to clean and normalize these physiological noise signals, improving data quality for analysis.

Which is associated with the paper (DOI: xxx)

File Descriptions

1.	01_Trigger.m: This script generates trigger sequences from PMU (pulse and respiration) data and corresponding DICOM files for fMRI analysis. After generating the sequences, the script also plots the results for visualization.
	
 2.	identifySignalsFromTrigger.m: This is a MATLAB function with the following features:
	•	Loads the “trigger.txt” file.
	•	Analyzes the first two columns (assumed to represent heartbeat or respiration signals).
	•	Computes the main frequency of each column.
	•	Classifies which column represents respiration and which represents heartbeat.
	
 3.	02_run_pnm_generic.sh: This shell script extracts physiological regressors (including brain and spinal cord signals) using PNM. It runs the entire preprocessing pipeline to clean and model the data.

 4.	03_clean_pnm/: This folder contains core functions for cleaning PNM data:
    
	•	cleanup_PNM4D.m: This script cleans and organizes the PNM data, identifying and removing physiological noise from the signal.

	•	demean.m: This function removes baseline offsets or means from the data for normalization, removing slow physiological drifts.

	•	GLMcleanup.m: This script applies General Linear Models (GLM) to further clean the data, removing any remaining physiological noise and improving signal quality.

How to Obtain Preliminary Results

Follow these steps to run the pipeline and obtain preliminary results or preprocessed data.
1. Clone the Repository
First, clone the repository to your local machine:

   git clone https://github.com/LINIP-share/CoSpine.git

   cd CoSpine


3. Execute 01_Trigger.m
Run the 01_Trigger.m script to generate the trigger sequences and DICOM files:

   matlab -r "run('01_Trigger.m')"


4. Execute identifySignalsFromTrigger.m
Run the identifySignalsFromTrigger.m function to identify and analyze the physiological signals (heartbeat and respiration) in the trigger data:

   matlab -r "identifySignalsFromTrigger()"


5. Run 02_run_pnm_generic.sh
Use the 02_run_pnm_generic.sh script to extract physiological regressors and apply the PNM preprocessing pipeline:

   bash 02_run_pnm_generic.sh

6. Execute cleanup_PNM4D.m

Run the cleanup_PNM4D.m script to regress out physiological noise from the fMRI data using PNM4D regressors. This step will clean the fMRI data by removing the physiological noise (e.g., heartbeat and respiration signals).

matlab -r "cleanup_PNM4D(32, 'sub-xxx_task-right-pain_bold.nii.gz', './pnm_regressors')"

 • 32 specifies the number of regressors (e.g., heartbeat, respiration).
 
 • 'sub-xxx_task-right-pain_bold.nii.gz' is the input EPI file.
 
 • './pnm_regressors' is the folder containing the physiological regressor files.

   

