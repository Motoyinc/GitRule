import subprocess
import os
import uuid
import json
import time

from flask import Flask, request, jsonify
from flask_executor import Executor

app = Flask(__name__)
executor = Executor(app)  # 初始化Executor
tasks = {}
new_url = "https://github.com/Motoyinc/GitRule.git"
remote_name = 'origin'


@app.route('/pullRule/start', methods=['POST'])
def start_push_rush():
    data = request.json
    print(data)
    task_id = str(uuid.uuid4())
    future = executor.submit(task_push_rush, data, task_id)
    tasks[task_id] = None  # 初始化任务状态
    future.add_done_callback(lambda future: tasks.update({task_id: future.result()}))
    return jsonify({"task_id": task_id}), 202


def task_push_rush(data, task_id):
    print("获取到数据", data)
    time.sleep(6)
    return 112233


@app.route('/pullRule/checkStage/<task_id>', methods=['GET'])
def task_status(task_id):
    print(tasks[task_id])
    if task_id in tasks:
        if tasks[task_id] is None:
            print("任务进行中")
            return jsonify({"status": "running"}), 202
        else:
            print("任务完成")
            return jsonify(tasks[task_id]), 200
    else:
        print("任务不存在")
        return jsonify({"error": "Invalid task ID"}), 404


def get_git_repo_path():
    try:
        # 使用git命令获取顶层仓库路径
        repo_path = subprocess.check_output(['git', 'rev-parse', '--show-toplevel']).decode().strip()
        return repo_path
    except subprocess.CalledProcessError:
        # 如果当前目录不在git仓库中，返回错误
        return "当前目录不在Git仓库中。"


# 当前路径 /app/app.py
@app.route('/pullRule/update', methods=['POST'])
def update_pull_rule():
    # 获取当前脚本的绝对路径
    script_dir = os.path.dirname(os.path.abspath(__file__))
    git_rule_path = os.path.join(script_dir, '../GitRule')  # 生成GitRule目录的绝对路径
    os.makedirs(git_rule_path, exist_ok=True)  # 确保目录存在，如果不存在则创建
    try:
        # 切换到gitRule目录
        os.chdir(git_rule_path)
        # 更新远端URL
        subprocess.check_output(['git', 'remote', 'set-url', remote_name, new_url], stderr=subprocess.STDOUT)
        print(f"远端 '{remote_name}' 的 URL 已更新为: {new_url}")
        try:
            # 拉取远程仓库的最新内容
            subprocess.check_output(['git', 'pull', remote_name, 'master'], stderr=subprocess.STDOUT)  # 指定远端名称和分支
            print("仓库已成功更新。")
        except subprocess.CalledProcessError as e:
            print(f"更新仓库时出错：{e.output.decode()}")

            return jsonify({"error": "Error pulling repository"}), 500
    except subprocess.CalledProcessError as e:
        print(f"操作时出错: {e.output.decode()}")
        try:
            subprocess.run(['git', 'clone', new_url, git_rule_path], check=True)
        except subprocess.CalledProcessError as e:
            print(f"克隆仓库时出错：{e.output.decode()}")
        return jsonify({"error": "Operation failed"}), 500
    finally:
        # 无论操作成功与否，都切换回脚本所在的原始目录
        os.chdir(script_dir)

    return jsonify({"message": "gitRuleApp update succeed"}), 200


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


def get_config() -> dict:
    filename = 'config.json'
    data = dict()
    with open(filename, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return data


if __name__ == '__main__':
    current_file_path = os.path.abspath(__file__)
    current_dir = os.path.dirname(current_file_path)
    os.chdir(current_dir)

    # print("Current working directory:", os.getcwd())
    app.run(host='0.0.0.0', port=5000)
