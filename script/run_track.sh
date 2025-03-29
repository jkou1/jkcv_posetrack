#!/bin/bash 

#SBATCH --job-name=run_track
#SBATCH --output=run_track-%j.out 
#SBATCH --partition=cond  
#SBATCH --nodes=1 
#SBATCH --ntasks=1 
#SBATCH --cpus-per-task=6
#SBATCH --gres=gpu:volta:1
#SBATCH --mem-per-cpu=50G
#SBATCH --time=48:00:00 
#SBATCH --mail-user=jkou@scu.edu
#SBATCH --mail-type=ALL

#!/usr/bin/env bash


module load Anaconda3
source ~/.bashrc
conda activate aic24

# Register a function to be called on exit
function cleanup {
  echo "Cleaning up..."
  pkill -P $$ # Kill all child processes of this script
}

trap cleanup EXIT

set -x

for i in $(ls result/detection); do
# OMP_NUM_THREADS=1 
python track/run_tracking_batch.py $i  > /WAVE/projects/dmlab-sd/MCPTJKCV/result/track_log/$i.txt&
done
#
wait
