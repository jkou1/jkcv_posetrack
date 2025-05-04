#!/bin/bash 
# 
#SBATCH --job-name=pose_est85-90
#SBATCH --output=pose_est-%j.out 
#SBATCH --partition=gpu
#SBATCH --nodes=1 
#SBATCH --ntasks=1 
#SBATCH --cpus-per-task=6
#SBATCH --gres=gpu:2
#SBATCH --mem-per-cpu=32G
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

cd mmpose

set -x

start=41
end=42
start_gpu=0
gpu_nums_per_iter=1 # gpu_nums_per_iter >= 1
cpu_nums_per_item=6 #cpu_nums_per_item >= 1
scene_per_iter=1   #scene_per_iter={1,2,5,10,15,30}
export CUDA_VISIBLE_DEVICES=0

for ((j=0; j < ($end-$start+1) / $scene_per_iter; j++)); do
  # 使用for循环遍历场景
  for ((i = $start + $j * $scene_per_iter; i < $start + $j * $scene_per_iter + $scene_per_iter; i++)); do
      # 计算当前场景所在的GPU编号
      # gpu_index=$((($i - $start - $j * $scene_per_iter) * $gpu_nums_per_iter / $scene_per_iter + $start_gpu))
      

      python /WAVE/users/unix/jkou/PoseTrack/mmpose/demo/save_pose_with_det_multiscene.py \
      demo/mmdetection_cfg/faster_rcnn_r50_fpn_coco.py \
      https://download.openxlab.org.cn/models/mmdetection/FasterR-CNN/weight/faster-rcnn_r50_fpn_1x_coco \
      configs/body_2d_keypoint/topdown_heatmap/coco/td-hm_hrnet-w32_8xb64-210e_coco-256x192.py \
      /WAVE/users/unix/jkou/PoseTrack/ckpt_weight/td-hm_hrnet-w32_8xb64-210e_coco-256x192-81c58e40_20220909.pth \
      --input examples/88.jpg \
      --output-root vis_results/ \
      --output_path "/WAVE/projects/dmlab-sd/MCPTJKCV/" \
      --draw-bbox \
      --show-kpt-idx \
      --start $[$i] \
      --end $[$i+1] &
  done
  wait
done
