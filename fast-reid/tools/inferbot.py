import numpy as np
from collections import deque
import os
import os.path as osp
import copy
import torch
import torch.nn.functional as F
import argparse
import sys

import time
import cv2
import json
import torch
import yaml
import mmcv
from tqdm import tqdm
from torchvision.ops import roi_align,nms
from argparse import ArgumentParser

current_file_path = os.path.abspath(__file__)
path_arr = current_file_path.split('/')[:-3]
root_path = '/'.join(path_arr)
sys.path.append(os.path.join(root_path,'fast-reid'))

class reid_inferencer():
    def __init__(self,reid):
        self.reid = reid
        self.mean =torch.Tensor([0.485, 0.456, 0.406]).view(3,1,1)
        self.std = torch.Tensor([0.229, 0.224, 0.225]).view(3,1,1)
        self.device=self.reid.device

    def model_fpass(self,crops):
        features = self.reid.backbone(crops)  # (bs, 2048, 16, 8)
        outputs = self.reid.heads(features)
        return outputs
    
    def process_frame(self,frame,bboxes):
        frame=torch.from_numpy(frame[:,:,::-1].copy()).permute(2,0,1)
        frame=frame/255.0
        paddingframe=torch.ones((3,2160,3840))
        paddingframe[0]=0.485
        paddingframe[1]=0.456
        paddingframe[2]=0.406

        paddingframe[:,540:1620,960:2880]=frame
        paddingframe.sub_(self.mean).div_(self.std)
        frame=paddingframe.unsqueeze(0)
        cbboxes=bboxes.copy()
        cbboxes[:,[1,3]]+=540
        cbboxes[:,[0,2]]+=960
        cbboxes=cbboxes.astype(np.float32)
        #print(cbboxes)
        #print(frame.dtype)
        #print(torch.cat([torch.zeros(len(cbboxes),1),torch.from_numpy(cbboxes)],1).dtype)
        newcrops=roi_align(frame,torch.cat([torch.zeros(len(cbboxes),1),torch.from_numpy(cbboxes)],1),(384,128)).to(self.device)
        newfeats=(self.model_fpass(newcrops)+self.model_fpass(newcrops.flip(3))).detach().cpu().numpy()/2

        return newfeats

    def process_frame_simplified(self,frame,bboxes):
        frame=torch.from_numpy(frame[:,:,::-1].copy()).permute(2,0,1)
        frame=frame/255.0
        #print(frame.shape)
        
        frame.sub_(self.mean).div_(self.std)
        frame=frame.unsqueeze(0)
        cbboxes=bboxes.copy()
        #cbboxes[:,[1,3]]+=540
        #cbboxes[:,[0,2]]+=960
        cbboxes=cbboxes.astype(np.float32)
        #print(cbboxes)
        #print(frame.dtype)
        #print(torch.cat([torch.zeros(len(cbboxes),1),torch.from_numpy(cbboxes)],1).dtype)
        newcrops=roi_align(frame,torch.cat([torch.zeros(len(cbboxes),1),torch.from_numpy(cbboxes)],1),(384,128)).to(self.device)
        newfeats=(self.model_fpass(newcrops)+self.model_fpass(newcrops.flip(3))).detach().cpu().numpy()/2

        return newfeats

def main():
    parser = ArgumentParser()
    parser.add_argument(
        '--start', type=int,default=0)
    parser.add_argument(
        '--end', type=int,default=-1)
    parser.add_argument(
        '--output_path',
        type=str,
        default=None,
        help='Custom output directory to save results'
    )
    args = parser.parse_args()


    det_root = os.path.join(root_path,"result/detection")
    print("det root is ", det_root)
    vid_root = os.path.join(root_path,"dataset/test")
    # Specifying the output path from user input at runtime
    if args.output_path:
        save_root = os.path.join(args.output_path, "result/reidbot")
    else:
        save_root = os.path.join(root_path, "result/reidbot")
    
    scenes = sorted(os.listdir(det_root))
    scenes = [s for s in scenes if s[0]=="s"]
    scenes = scenes[args.start-61:args.end-61]

    reid=torch.load('../ckpt_weight/bot-aic24.pkl',map_location='cpu').cuda().eval()
    print("loaded the weights correctly")
    reid_model = reid_inferencer(reid)

    print(scenes)
    for scene in tqdm(scenes):
        print(scene)
        det_dir = os.path.join(det_root, scene)
        vid_dir = os.path.join(vid_root, scene)
        save_dir = os.path.join(save_root, scene)
        print("save dir is ", save_dir)
        cams = os.listdir(vid_dir)
        cams = sorted([c for c in cams if c[0]=="c"])

        if not os.path.exists(save_dir):
            os.mkdir(save_dir)

        print(len(cams))
        for cam in tqdm(cams):
            print(cam)
            det_path = os.path.join(det_dir,cam)+".txt"
            vid_path = os.path.join(vid_dir,cam)+"/video.mp4"
            save_path = os.path.join(save_dir,cam+".npy")
            if os.path.exists(save_path):
                continue
            det_annot = np.ascontiguousarray(np.loadtxt(det_path,delimiter=","))
            if len(det_annot)==0:
                all_results = np.array([])
                np.save(save_path, all_results)
                continue
            #print(det_annot[0])

            #cap=cv2.VideoCapture(vid_path)
            video = mmcv.VideoReader(vid_path)
            #all_results = np.zeros((0,2048))
            all_results = []
            line_idx = 0
            det_len = len(det_annot)

            for frame_id, frame in enumerate(tqdm(video)):
                #print(frame_id)
                dets = det_annot[det_annot[:,0]==frame_id]
                # num_det=0
                # while det_annot[line_idx,0]<frame_id:
                #     line_idx += 1
                # while line_idx + num_det < det_len and det_annot[line_idx + num_det,0]==frame_id:
                #     num_det += 1

                # if det_annot[line_idx,0]>frame_id:
                #     continue

                # dets = det_annot[line_idx:line_idx+num_det]
                bboxes_s = dets[:,2:7] #x1y1x2y2s
                #preprocess detection
                screen_width = 1920
                screen_height = 1080

                x1 = bboxes_s[:, 0]
                y1 = bboxes_s[:, 1]
                x2 = bboxes_s[:, 2]
                y2 = bboxes_s[:, 3]
                
                x1 = np.maximum(0, x1)
                y1 = np.maximum(0, y1)
                x2 = np.minimum(screen_width, x2)
                y2 = np.minimum(screen_height, y2)

                bboxes_s[:, 0] = x1
                bboxes_s[:, 1] = y1
                bboxes_s[:, 2] = x2
                bboxes_s[:, 3] = y2
                
                if len(bboxes_s)==0:
                    continue
                with torch.no_grad():
                    #feat = reid_model.process_frame(frame,bboxes_s[:,:-1]) #(b,2048)
                    feat_sim = reid_model.process_frame_simplified(frame,bboxes_s[:,:-1])
                #print("error: ",np.sum(np.abs(feat_sim-feat))," ",np.sum(np.abs(feat_sim)))
                #all_results = np.concatenate((all_results,feat_sim))
                all_results.append(feat_sim)
            all_results = np.concatenate(all_results)
                #print(all_results.shape)

            np.save(save_path, all_results)


if __name__ == '__main__':
    main()