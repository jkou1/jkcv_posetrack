#!/bin/bash 
# 
#SBATCH --job-name=model_check
#SBATCH --output=model_check-%j.out 
# 
#SBATCH --partition=gpu
#SBATCH --nodes=1 
#SBATCH --ntasks=1 
#SBATCH --cpus-per-task=6 
#SBATCH --gres=gpu:1
#SBATCH --mem-per-cpu=50G
#SBATCH --time=48:00:00 
#
#SBATCH --mail-user=jkou@scu.edu
#SBATCH --mail-type=ALL


module load Anaconda3

source ~/.bashrc
conda activate aic24


# Register a function to be called on exit
function cleanup {
  echo "Cleaning up..."
  pkill -P $$ # Kill all child processes of this script
}

trap cleanup EXIT

python model_checker.py