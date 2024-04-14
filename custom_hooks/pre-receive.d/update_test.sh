#!/bin/bash

GL_USERNAME="Motoyinc"
GL_PROJECT_PATH="devgroup/SRPJ"
L_ID="user-3"
GL_REPOSITORY="project-2"
JSON_DATA="{\"username\":\"$GL_USERNAME\", \"project_path\":\"$GL_PROJECT_PATH\", \"id\":\"$L_ID\", \"repository\":\"$GL_REPOSITORY\"}"
#
## 更新规则请求
#curl -X POST  http://127.0.0.1:5000/pullRule/update
#
## 发生数据请求
#curl -X POST -H "Content-Type: application/json" -d "$JSON_DATA" http://127.0.0.1:5000/pullRule/start
#curl -X POST -H "Content-Type: application/json" -d '{"key1":"value1", "key2":"value2"}' http://127.0.0.1:5000/pullRule/start

START_ENDPOINT="http://127.0.0.1:5000/pullRule/start"
CHECK_ENDPOINT="http://127.0.0.1:5000/pullRule/checkStage"
INTERVAL=2
TIMEOUT=20
elapsed=0
CHECK_COUNT=0
CHECK_MAX_COUNT=20
CHECK_INTERVAL=2

# 启动任务并获取任务ID
echo "正在向服务器汇报git-push信息"
response=$(curl -X POST -H "Content-Type: application/json" -d "$JSON_DATA" "$START_ENDPOINT")
task_id=$(echo $response | jq -r '.task_id')

echo "服务器正在查询用户权限"
echo "Response from server: $response"
echo "Task started with ID: $task_id"

echo "正在查询服务器权限，查询上限[$CHECK_MAX_COUNT],查询间隔[$CHECK_INTERVAL]s"

while [ $elapsed -lt $TIMEOUT ]; do
  CHECK_COUNT=$(($CHECK_COUNT + 1))
  echo "第[$CHECK_COUNT]次 查询权限"
    # 检查任务状态
    status_response=$(curl -s "$CHECK_ENDPOINT/$task_id")
    status=$(echo $status_response | jq -r '.status')
    echo $status_response
    if [ "$status" == "completed" ]; then
        echo "Task completed successfully."
#        exit 0
    elif [ "$status" == "running" ]; then
        echo "Task is still running..."
    else
        echo "Error or unknown status."
#        exit 1
    fi

    sleep $INTERVAL
    elapsed=$(($elapsed + $INTERVAL))
done