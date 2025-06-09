#!/bin/bash
##############################################################################
# Step 1: Extract physiological regressors (brain & spinal cord) using pnm.
#
# Author: Zhaoxing Wei
# Date: 2020-1-1 version 1.0; 2025-1-30 version 2.0
#
# Inputs:
#   - EPI image (e.g., sub-XXX_task-YYY_bold.nii.gz)
#   - Physiology trigger file (e.g., condition_physio_trigger.txt)
#
# This script performs:
#   1. Fixing text formatting of the trigger file.
#   2. Running pnm_stage1 to process the input.
#   3. Optionally running popp if additional arguments are provided.
#   4. Running pnm_evs to extract EV files from the EPI image.
#   5. Listing the generated EV files.
#
# Adjustable parameters are defined as variables at the top.
#
# Note on slicetime.txt:
#   - The slicetime.txt file is generated from the JSON sidecar of the functional
#     MRI image. In a BIDS dataset, each functional image (e.g.,
#     sub-XXX_task-YYY_bold.nii.gz) typically has a corresponding JSON file that
#     contains scanning parameters including "SliceTiming".
#   - slicetime.txt records the relative acquisition time of each slice within each
#     TR. This information is critical for slice timing correction during
#     preprocessing, as it allows software to adjust for the time differences in
#     slice acquisition.
##############################################################################

# Directories (update these paths to your setup)
DATADIR="/path/to/your/data"
FUNC_FOLDER="$DATADIR/BIDS/func"
PHYSIO_FOLDER="$DATADIR/analysis/processed_physio/your_condition"
SCRIPT_FOLDER="$DATADIR/scripts/brain-spinal_scripts"

# General processing parameters (set these to match your dataset)
SAMPLING_RATE="YOUR_SAMPLING_RATE"   # e.g., 400 (Hz)
TR_VALUE="YOUR_TR_VALUE"             # e.g., 2.68 (seconds)
SMOOTH_CARD="YOUR_SMOOTH_CARD"       # e.g., 0.1
SMOOTH_RESP="YOUR_SMOOTH_RESP"       # e.g., 0.1
RESP_CHANNEL="YOUR_RESP_CHANNEL"     # e.g., 2
CARDIAC_CHANNEL="YOUR_CARDIAC_CHANNEL"  # e.g., 1
TRIGGER_CODE="YOUR_TRIGGER_CODE"     # e.g., 3

# Define input filenames (update these names as needed)
PHYSIO_TRIGGER="your_condition_physio_trigger.txt"
EPI_FILE="$FUNC_FOLDER/sub-XXX_task-your_condition_bold.nii.gz"

# slicetime.txt explanation:
#   The slicetime.txt file is extracted from the JSON sidecar of the functional MRI
#   image. In BIDS, the JSON file accompanying each functional image contains a
#   "SliceTiming" field, which details the relative acquisition times for each slice
#   within a TR. This file is used during preprocessing for slice timing correction,
#   allowing adjustments for the differences in acquisition time across slices.
SLICE_TIMING_FILE="$SCRIPT_FOLDER/whole/slicetime.txt"

# Change to the physiology folder
cd "$PHYSIO_FOLDER" || { echo "Cannot change directory to $PHYSIO_FOLDER"; exit 1; }

# Fix text formatting using FSL's fslFixText to create a standardized input file.
$FSLDIR/bin/fslFixText "$PHYSIO_TRIGGER" pnm_input.txt

# Run pnm_stage1 to process the input trigger file.
$FSLDIR/bin/pnm_stage1 -i pnm_input.txt -o pnm -s "$SAMPLING_RATE" --tr="$TR_VALUE" \
  --smoothcard="$SMOOTH_CARD" --smoothresp="$SMOOTH_RESP" --resp="$RESP_CHANNEL" \
  --cardiac="$CARDIAC_CHANNEL" --trigger="$TRIGGER_CODE"

# Set output base directory variable for further processing.
obase="$(pwd)/pnm"
export obase

# Optionally, run popp if extra command-line arguments are provided.
if [ $# -gt 0 ]; then
    $FSLDIR/bin/popp -i pnm_input.txt -o pnm -s "$SAMPLING_RATE" --tr="$TR_VALUE" \
      --smoothcard="$SMOOTH_CARD" --smoothresp="$SMOOTH_RESP" --resp="$RESP_CHANNEL" \
      --cardiac="$CARDIAC_CHANNEL" --trigger="$TRIGGER_CODE" "$@"
fi

# Run pnm_evs to extract EV files using the EPI image.
$FSLDIR/bin/pnm_evs -i "$EPI_FILE" -c pnm_card.txt -r pnm_resp.txt -o pnm \
  --tr="$TR_VALUE" --oc=YOUR_OC --or=YOUR_OR --multc=YOUR_MULTC --multr=YOUR_MULTR \
  --slicetiming="$SLICE_TIMING_FILE"

# List the generated EV files into pnm_evlist.txt.
$FSLDIR/bin/imglob -extensions "${obase}ev0*" | ls -1 > pnm_evlist.txt
