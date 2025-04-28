import pandas as pd 
import matplotlib.pyplot as plt
import json

train_data = pd.read_json("/WAVE/users2/unix/jkou/PoseTrack/fast-reid/logs/jk_experiments/agw-R101/metrics.json", lines=True)

x = train_data["iteration"]
y = train_data["total_loss"]
plt.xlabel("Iteration")  # add X-axis label
plt.ylabel("Loss")  # add Y-axis label
plt.title("AGW Loss per Iteration")  # add title
plt.plot(x, y)

plt.savefig("loss_agw.png")