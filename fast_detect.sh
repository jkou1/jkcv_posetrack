#!/bin/bash 

#SBATCH --job-name=fast_detect
#SBATCH --output=fast_detect-%j.out 
#SBATCH --partition=condo
#SBATCH --nodes=1 
#SBATCH --ntasks=1 
#SBATCH --cpus-per-task=6
#SBATCH --gres=gpu:2
#SBATCH --mem-per-cpu=50G
#SBATCH --time=48:00:00 
#SBATCH --mail-user=jkou@scu.edu
#SBATCH --mail-type=ALL


module load Anaconda3
source ~/.bashrc
conda activate aic24

# INCREDIBLY COMPLEX CODE
python ./detection/utils/trt.py
script/fast_detection.sh
