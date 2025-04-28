#!/bin/bash 

#SBATCH --job-name=jkreid
#SBATCH --output=jkreid_infer-%j.out 
#SBATCH --partition=gpu
#SBATCH --nodes=1 
#SBATCH --ntasks=1 
#SBATCH --cpus-per-task=6
#SBATCH --gres=gpu:2
#SBATCH --mem-per-cpu=20G
#SBATCH --time=48:00:00 
#SBATCH --mail-user=jkou@scu.edu
#SBATCH --mail-type=ALL

#!/usr/bin/env bash

module load Anaconda3
module load GCC/11.3.0
source ~/.bashrc
conda activate aic24


# Register a function to be called on exit
function cleanup {
  echo "Cleaning up..."
  pkill -P $$ # Kill all child processes of this script
}

trap cleanup EXIT

cd fast-reid
set -x


CUDA_VISIBLE_DEVICES=0 python tools/infer.py --start 79 --end 84 --output_path /WAVE/projects/dmlab-sd/MCPTJKCV/ &
CUDA_VISIBLE_DEVICES=1 python tools/infer.py --start 85 --end 90 --output_path /WAVE/projects/dmlab-sd/MCPTJKCV/ &

wait