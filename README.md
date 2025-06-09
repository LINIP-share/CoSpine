The CoSpine repository provides a set of MATLAB scripts for preprocessing and analyzing data, specifically for Physiological Noise Modeling (PNM). PNM aims to identify and remove physiological noise, such as heartbeats, and respiration, that can interfere with primary data (e.g., brain or spinal signals). This repository includes tools to clean and normalize these physiological noise signals, improving data quality for analysis

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
