import pandas as pd 
import matplotlib.pyplot as plt
import json

train_data = pd.read_json("/WAVE/users2/unix/jkou/PoseTrack/fast-reid/logs/AIC24/mgn_R101_reprod/metrics.json", lines=True)

x = train_data["iteration"]
y = train_data["cls_accuracy"]
plt.xlabel("Iteration")  # add X-axis label
plt.ylabel("Accuracy")  # add Y-axis label
plt.title("AGW Accuracy per Iteration")  # add title
plt.plot(x, y)

plt.savefig("acc_baseline.png")