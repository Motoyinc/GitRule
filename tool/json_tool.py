import pickle
import json

data = {
    "CHECK_SEVER": True,
    "CHECK_COUNT": 0,
    "CHECK_MAX_COUNT": 20,
    "CHECK_INTERVAL": 2,
    "CHECK_SEVER_URL": "http://127.0.0.1:5000",
    "CHECK_SEVER_START": "pullRule/start",
    "CHECK_SEVER_CHECK_STAGE": "pullRule/checkStage"
}
filename = "../custom_hooks/pre-receive.d/config.json"
with open(filename, 'w') as f:
    json.dump(data, f, indent=4)

with open(filename, 'r') as f:
    data_loaded = json.load(f)

print(data_loaded)