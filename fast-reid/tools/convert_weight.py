#!/usr/bin/env python
# encoding: utf-8
"""
@author:  sherlock
@contact: sherlockliao01@gmail.com
"""

import sys

sys.path.append('.')

from fastreid.config import get_cfg
from fastreid.engine import DefaultTrainer, default_argument_parser, default_setup, launch
from fastreid.utils.checkpoint import Checkpointer

import torch 
def setup(args):
    """
    Create configs and perform basic setups.
    """
    cfg = get_cfg()
    cfg.merge_from_file(args.config_file)
    cfg.merge_from_list(args.opts)
    cfg.freeze()
    default_setup(cfg, args)
    return cfg

# CHANGE THIS TO MATCH THE YML FILE OF THE CORRESPONDING EXPERIMENT!!!
# YMLS are in configs/jk_experiments (:
experiment_name = "agw-R101-ibn"

def main(args):
    cfg = setup(args)
    if args.eval_only:
        cfg.defrost()
        cfg.MODEL.BACKBONE.PRETRAIN = False
        model = DefaultTrainer.build_model(cfg)
        
        Checkpointer(model).load(f'logs/jk_experiments/{experiment_name}/model_best.pth')  # load trained model
        model.training=False
        model.eval()
        
        torch.save(model, f'../ckpt_weight/{experiment_name}.pkl')  
        return None

if __name__ == "__main__":
    args = default_argument_parser().parse_args()
    args.eval_only=True
    args.config_file = f'configs/jk_experiments/{experiment_name}.yml'
    print("Command Line Args:", args)
    launch(
        main,
        args.num_gpus,
        num_machines=args.num_machines,
        machine_rank=args.machine_rank,
        dist_url=args.dist_url,
        args=(args,),
    )
