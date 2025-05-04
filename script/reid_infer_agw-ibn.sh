#!/bin/bash 

#SBATCH --job-name=reidagw
#SBATCH --output=reid_agw-%j.out 
#SBATCH --partition=condo
#SBATCH --nodes=1 
#SBATCH --ntasks=1 
#SBATCH --cpus-per-task=6
#SBATCH --gres=gpu:ada:1
#SBATCH --mem-per-cpu=20G
#SBATCH --time=48:00:00 
#SBATCH --mail-user=jkou@scu.edu
#SBATCH --mail-type=ALL

#!/usr/bin/env bash

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

cd fast-reid
set -x

start=61
end=62
start_gpu=0
gpu_nums_per_iter=1 # gpu_nums_per_iter >= 1
cpu_nums_per_item=6 #cpu_nums_per_item >= 1
scene_per_iter=1   #scene_per_iter={1,2,5,10,15,30}


# for ((j=0; j < ($end-$start+1) / $scene_per_iter; j++)); do
#   # 使用for循环遍历场景
#   for ((i = $start + $j * $scene_per_iter; i < $start + $j * $scene_per_iter + $scene_per_iter; i++)); do
#     # 计算当前场景所在的GPU编号
#     gpu_index=$((($i - $start - $j * $scene_per_iter) * $gpu_nums_per_iter / $scene_per_iter + $start_gpu))

#     # 设置CUDA_VISIBLE_DEVICES环境变量以限制使用特定的GPU
#     export CUDA_VISIBLE_DEVICES=$[$gpu_index]

#     python tools/infer-baseline-architectures.py --start $[$i] --end $[$i+1] --output_path "/WAVE/projects/dmlab-sd/MCPTJKCV/" &
#   done
#   wait
# done

export CUDA_VISIBLE_DEVICES=0
python tools/inferagw.py --start 61 --end 70 --output_path "/WAVE/projects/dmlab-sd/MCPTJKCV/" &
wait