from flask import Flask, request, jsonify
from flask_executor import Executor
import subprocess
import os
import uuid

app = Flask(__name__)
executor = Executor(app)  # 初始化Executor
tasks = {}

@app.route('/start-pullRule', methods=['POST'])
def execute_python_script():
    data = request.json
    task_id = str(uuid.uuid4())
    future = executor.submit(long_running_task, data, task_id)
    tasks[task_id] = None  # 初始化任务状态
    future.add_done_callback(lambda future: tasks.update({task_id: future.result()}))
    return jsonify({"task_id": task_id}), 202

@app.route('/checkStage-pullRule/<task_id>', methods=['GET'])
def task_status(task_id):
    if task_id in tasks:
        if tasks[task_id] is None:
            return jsonify({"status": "running"}), 202
        else:
            return jsonify(tasks[task_id]), 200
    else:
        return jsonify({"error": "Invalid task ID"}), 404

@app.route('/update-pullRule', methods=['POST'])
def update_pull_rule():
    repo_url = "https://github.com/Motoyinc/gitRule.git"
    clone_path = "/Script/gitRule"

    if not os.path.exists(clone_path):
        subprocess.run(['git', 'clone', repo_url, clone_path], check=True)
    else:
        subprocess.run(['git', '-C', clone_path, 'pull'], check=True)

    return jsonify({"message": "Repository updated successfully"}), 200

def long_running_task(data, task_id):
    script_name = data.get("script_name", "default_script.py")
    script_path = f"/Script/gitRule/{script_name}"
    try:
        completed_process = subprocess.run(['python3', script_path], capture_output=True, text=True, check=True)
        output_data = completed_process.stdout
        is_successful = True
    except subprocess.CalledProcessError as e:
        output_data = {"error": "Execution failed", "details": str(e)}
        is_successful = False
    return {"is_successful": is_successful, "output_data": output_data}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)