#!/bin/bash 
# 
#SBATCH --job-name=reid_train_agw_ibn
#SBATCH --output=reid_train-%j.out 
#SBATCH --partition=gpu
#SBATCH --nodes=1 
#SBATCH --ntasks=1 
#SBATCH --cpus-per-task=6 
#SBATCH --gres=gpu:2
#SBATCH --mem-per-cpu=32G
#SBATCH --time=48:00:00 
#
#SBATCH --mail-user=jkou@scu.edu
#SBATCH --mail-type=ALL

module load Anaconda3
module load GCC/12.3.0
source ~/.bashrc
conda activate aic24

# Register a function to be called on exit
function cleanup {
  echo "Cleaning up..."
  pkill -P $$ # Kill all child processes of this script
}

trap cleanup EXIT

set -x

cd ../fast-reid
python3 tools/train_net.py --config-file ./configs/jk_experiments/agw-R101-ibn.yml --num-gpus 2
python3 tools/convert_weight.py