#!/bin/bash 
#SBATCH --job-name=jkcv_all
#SBATCH --output=jkcv_all-%j.out
#SBATCH --partition=gpu
#SBATCH --nodes=1 
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=6
#SBATCH --gres=gpu:1
#SBATCH --mem-per-cpu=50G
#SBATCH --time=48:00:00
#SBATCH --mail-user=jkou@scu.edu
#SBATCH --mail-type=ALL

#!/usr/bin/env bash

module load Anaconda3
# module load PyTorch/20240506  # Load system-wide PyTorch version 2.3.0
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
start=42
end=42
start_gpu=1
gpu_nums_per_iter=1 # gpu_nums_per_iter >= 1
cpu_nums_per_item=1 #cpu_nums_per_item >= 1
scene_per_iter=1   #scene_per_iter={1,2,5,10,15,30}

export CUDA_VISIBLE_DEVICES=$[$1]


for ((j=0; j < ($end-$start+1) / $scene_per_iter; j++)); do
  # 使用for循环遍历场景
  for ((i = $start + $j * $scene_per_iter; i < $start + $j * $scene_per_iter + $scene_per_iter; i++)); do
      # # 计算当前场景所在的GPU编号
      # gpu_index=$((($i - $start - $j * $scene_per_iter) * $gpu_nums_per_iter / $scene_per_iter + $start_gpu))

      # taskset -c $[$cpu_nums_per_item*$[$i-$start]]-$[$cpu_nums_per_item*$[$i-$start]+$cpu_nums_per_item-1] python detection/get_detection.py --scene $i &
      python detection/get_detection.py --scene $i --output_path "$/WAVE/projects/dmlab-sd/MCPTJKCV/" &
  done
  wait
done
wait



# running pose estimation
cd mmpose

module load Anaconda3
# module load PyTorch/20240506  # Load system-wide PyTorch version 2.3.0
source ~/.bashrc
conda activate aic24

for ((j=0; j < ($end-$start+1) / $scene_per_iter; j++)); do
  # 使用for循环遍历场景
  for ((i = $start + $j * $scene_per_iter; i < $start + $j * $scene_per_iter + $scene_per_iter; i++)); do
      # 计算当前场景所在的GPU编号
      # gpu_index=$((($i - $start - $j * $scene_per_iter) * $gpu_nums_per_iter / $scene_per_iter + $start_gpu))
      
      python demo/save_pose_with_det_multiscene.py \
      demo/mmdetection_cfg/faster_rcnn_r50_fpn_coco.py \
      https://download.openxlab.org.cn/models/mmdetection/FasterR-CNN/weight/faster-rcnn_r50_fpn_1x_coco \
      configs/body_2d_keypoint/topdown_heatmap/coco/td-hm_hrnet-w32_8xb64-210e_coco-256x192.py \
      ../ckpt_weight/td-hm_hrnet-w32_8xb64-210e_coco-256x192-81c58e40_20220909.pth \
      --input examples/88.jpg \
      --output-root vis_results/ \
      --output_path "$/WAVE/projects/dmlab-sd/MCPTJKCV/"
      --draw-bbox \
      --show-kpt-idx \
      --start $[$i] \
      --end $[$i+1] &
  done
  wait
done

cd ..


# Running Re-ID infer script
cd fast-reid

module load Anaconda3
# module load PyTorch/20240506  # Load system-wide PyTorch version 2.3.0
source ~/.bashrc
conda activate aic24

for ((j=0; j < ($end-$start+1) / $scene_per_iter; j++)); do
  for ((i = $start + $j * $scene_per_iter; i < $start + $j * $scene_per_iter + $scene_per_iter; i++)); do
      # gpu_index=$((($i - $start - $j * $scene_per_iter) * $gpu_nums_per_iter / $scene_per_iter + $start_gpu))
      python tools/infer.py --start $[$i] --end $[$i+1] --output_path "$/WAVE/projects/dmlab-sd/MCPTJKCV/" &
  done
  wait
done

cd ..


# Running Tracking
for i in $(ls result/detection); do
# OMP_NUM_THREADS=1 
python track/run_tracking_batch.py $i  > /WAVE/projects/dmlab-sd/MCPTJKCV/result/track_log/$i.txt&
done
#
wait

# Final result file generation to be fed to eval script, result located in result/track.txt
python3 track/generate_submission.py