from dlclive import DLCLive, Processor
import cv2
import numpy as np

w, h = 640, 480
header_size = 4  # uint32, for frame index
frame_size = w * h * 3
pose_size = 3 * 4  # x, y, llh
total_size = header_size + frame_size + 2*pose_size
idx_hand = 7
idx_jaw = 0
filename = r"E:\MATLAB_MEMMAP\memmap_CameraConnection_1.dat"

import deeplabcut

# deeplabcut.export_model(r"E:\PycharmProjects\DeepLabCut\dlc\daisy910-HLF-2021-12-08\config.yaml", shuffle=1, trainingsetindex=0, snapshotindex=None, make_tar=False)

dlc_proc = Processor()
dlc_live = DLCLive(
    r"E:\PycharmProjects\DeepLabCut\dlc\daisy910-HLF-2021-12-08\exported-models\DLC_daisy910_resnet_101_iteration-0_shuffle-1",
    processor=dlc_proc)

dlc_live.init_inference()

mm = np.memmap(filename, dtype='uint8', mode='r+', shape=(total_size,))

last_idx = 0
while True:
    idx = mm[:header_size].view(np.uint32)[0]
    if idx != last_idx:
        last_idx = idx
        img = mm[header_size:header_size+frame_size]
        img = img.reshape((h, w, 3))
        pose = dlc_live.get_pose(img)

        pose_slice = mm[header_size+frame_size:]
        pose_slice.view(np.float32)[:] = pose[[idx_jaw, idx_hand], :].astype(np.float32).ravel('F')

        print(pose_slice.view(np.float32)[:])
