import deeplabcut

# deeplabcut.export_model(r"E:\PycharmProjects\DeepLabCut\dlc\daisy910-HLF-2021-12-08\config.yaml", shuffle=1, trainingsetindex=0, snapshotindex=None, make_tar=False)

# Export an example DLC3 pytorch model (trained on cameras 1-R and 3-L)
deeplabcut.export_model(r"C:\SERVER\DeepLabCut\Projects\SNrAutoOpto-Emma-2026-07-13\config.yaml", make_tar=False)
# exported model can be found at:
# C:\SERVER\DeepLabCut\Projects\SNrAutoOpto-Emma-2026-07-13\exported-models-pytorch\DLC_SNrAutoOpto_NetType.RESNET_50_iteration-3_shuffle-1
