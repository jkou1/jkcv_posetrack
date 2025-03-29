#!/usr/bin/env bash
#!/bin/bash 
# 
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


# Register a function to be called on exit
function cleanup {
  echo "Cleaning up..."
  pkill -P $$ # Kill all child processes of this script
}

trap cleanup EXIT

set -x

# 定义场景的起始和结束索引
start=61
end=90
start_gpu=1
gpu_nums_per_iter=1 # gpu_nums_per_iter >= 1
cpu_nums_per_item=6 #cpu_nums_per_item >= 1
scene_per_iter=1   #scene_per_iter={1,2,5,10,15,30}
export CUDA_VISIBLE_DEVICES=$[$2]

for ((j=0; j < ($end-$start+1) / $scene_per_iter; j++)); do
  # 使用for循环遍历场景
  for ((i = $start + $j * $scene_per_iter; i < $start + $j * $scene_per_iter + $scene_per_iter; i++)); do
      # 计算当前场景所在的GPU编号
      # gpu_index=$((($i - $start - $j * $scene_per_iter) * $gpu_nums_per_iter / $scene_per_iter + $start_gpu))
      
      python detection/get_detection.py --scene $i --output_path "$/WAVE/projects/dmlab-sd/MCPTJKCV/" --trt &
  done
  wait
done

wait