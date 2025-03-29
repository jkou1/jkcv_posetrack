#!/bin/bash 
# 
#SBATCH --job-name=reid_train
#SBATCH --output=reid_train-%j.out 
# 
#SBATCH --partition=gpu
#SBATCH --nodes=1 
#SBATCH --ntasks=1 
#SBATCH --cpus-per-task=6 
#SBATCH --gres=gpu:1
#SBATCH --mem-per-cpu=32G
#SBATCH --time=48:00:00 
#
#SBATCH --mail-user=jkou@scu.edu
#SBATCH --mail-type=ALL

# Register a function to be called on exit
function cleanup {
  echo "Cleaning up..."
  pkill -P $$ # Kill all child processes of this script
}

trap cleanup EXIT

set -x

cd fast-reid
python3 tools/train_net.py --config-file ./configs/AIC24/mgn_R101_reprod.yml --num-gpus 1
python3 tools/convert_weight.py