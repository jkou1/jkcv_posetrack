#!/bin/bash 

#SBATCH --job-name=jkcvdet1
#SBATCH --output=jkcvdet1-%j.out 
#SBATCH --partition=condo
#SBATCH --nodes=1 
#SBATCH --ntasks=1 
#SBATCH --cpus-per-task=6
#SBATCH --gres=gpu:ada:2
#SBATCH --mem-per-cpu=100G
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

# 定义场景的起始和结束索引
start=61
end=70
start_gpu=1
# gpu_nums_per_iter=2 # gpu_nums_per_iter >= 1
# cpu_nums_per_item=6 #cpu_nums_per_item >= 1
scene_per_iter=1   #scene_per_iter={1,2,5,10,15,30}

# 设置CUDA_VISIBLE_DEVICES环境变量以限制使用特定的GPU
export CUDA_VISIBLE_DEVICES=$[$2]


for ((j=0; j < ($end-$start+1) / $scene_per_iter; j++)); do
  # 使用for循环遍历场景
  for ((i = $start + $j * $scene_per_iter; i < $start + $j * $scene_per_iter + $scene_per_iter; i++)); do
      # # 计算当前场景所在的GPU编号
      # gpu_index=$((($i - $start - $j * $scene_per_iter) * $gpu_nums_per_iter / $scene_per_iter + $start_gpu))

  
      # taskset -c $[$cpu_nums_per_item*$[$i-$start]]-$[$cpu_nums_per_item*$[$i-$start]+$cpu_nums_per_item-1] python detection/get_detection.py --scene $i &
      python detection/get_detection.py --scene $i --output_path "/WAVE/projects/dmlab-sd/MCPTJKCV/" &
  done
  wait
done

wait