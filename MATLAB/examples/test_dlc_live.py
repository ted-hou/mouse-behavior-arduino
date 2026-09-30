from dlclive import DLCLive, Processor
import numpy as np
import matplotlib.pyplot as plt
import time

w, h = 640, 480
header_size = 4  # uint32, for frame index
frame_size = w * h * 3
pose_size = 3 * 4  # x, y, llh
total_size = header_size + frame_size + 3 * pose_size
idx_jaw = 4  #0
idx_handl = 0  #11
idx_handr = 1  #7
filename = r"E:\MATLAB_MEMMAP\memmap_var.dat"

print("Initializing DeepLabCut-live...")
dlc_proc = Processor()
# dlc_live = DLCLive(
#     r"E:\PycharmProjects\DeepLabCut\dlc\daisy910-HLF-2021-12-08\exported-models\DLC_daisy910_resnet_101_iteration-0_shuffle-1",
#     processor=dlc_proc)
dlc_live = DLCLive(
    r"E:\PycharmProjects\DeepLabCut3\exported-models-pytorch\DLC_SNrAutoOpto_NetType.RESNET_50_iteration-3_shuffle-1\DLC_SNrAutoOpto_NetType.RESNET_50_iteration-3_shuffle-1_snapshot-best-30.pt",
    model_type='pytorch',
    processor=dlc_proc, single_animal=True)

mm = np.memmap(filename, dtype='uint8', mode='r+', shape=(total_size,))

img = mm[header_size:header_size + frame_size]
img = img.reshape((h, w, 3), order='F')
dlc_live.init_inference(img)

print("Up and running!")

# plt.ion()
# fig, ax = plt.subplots()

last_idx = 0
while True:
    time.sleep(1/15)
    idx = mm[:header_size].view(np.uint32)[0]
    # print("Waiting for next frame...")
    if idx != last_idx:
        if idx - last_idx > 1:
            print(f"skipped {idx - last_idx - 1} frames, now at {idx}...")
        last_idx = idx
        img = mm[header_size:header_size + frame_size]
        img = img.reshape((h, w, 3), order='F')
        pose = dlc_live.get_pose(img)

        pose_slice = mm[header_size + frame_size:]
        pose_slice.view(np.float32)[:] = pose[[idx_jaw, idx_handl, idx_handr], :].astype(np.float32).ravel('F')

        # ax.clear()
        # ax.imshow(img)
        # ax.axis("off")
        # plt.draw()

        # print(pose_slice.view(np.float32)[:])
