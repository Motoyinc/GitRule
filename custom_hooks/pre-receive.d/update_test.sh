#!/bin/bash
# 查看当前locale设置
locale
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8


# 测试用，从Gitlab获取的信息
GL_USERNAME="Motoyinc"
GL_PROJECT_PATH="devgroup/SRPJ"
L_ID="user-3"
GL_REPOSITORY="project-2"
JSON_DATA="{\"username\":\"$GL_USERNAME\", \"project_path\":\"$GL_PROJECT_PATH\", \"id\":\"$L_ID\", \"repository\":\"$GL_REPOSITORY\"}"


## 更新规则请求
#curl -X POST  http://127.0.0.1:5000/pullRule/update
#
## 发生数据请求
#curl -X POST -H "Content-Type: application/json" -d "$JSON_DATA" http://127.0.0.1:5000/pullRule/start
#curl -X POST -H "Content-Type: application/json" -d '{"key1":"value1", "key2":"value2"}' http://127.0.0.1:5000/pullRule/start

# 基础参数
START_ENDPOINT="http://127.0.0.1:5000/pullRule/start"
CHECK_ENDPOINT="http://127.0.0.1:5000/pullRule/checkStage"


CHECK_COUNT=0
CHECK_MAX_COUNT=20
CHECK_INTERVAL=2

commit_message="#114514 Edit-Wip(Art): 角色模型"

# 正则表达式初步判断提交信息是否规范
pattern='^#[0-9]+ [A-Za-z]+-[A-Za-z]+\([A-Za-z]+\): .+$'
if ! [[ $commit_message =~ $pattern ]]; then
    echo "ERROR: "
    echo "ERROR: ！！！！！！规范化检查大失败！！！！！！"
    echo "ERROR: 请按以下规范化格式提交"
    echo "ERROR: "
    echo "ERROR: ======================"
    echo "ERROR: "
    echo "ERROR: 格式："
    echo "ERROR: #<单号><编辑类型>-<编辑状态>(<用户角色>): <描述>"
    echo "ERROR: "
    echo "ERROR: 示例："
    echo "ERROR: #114514 Edit-Wip(Art): 角色需求模型"
    echo "ERROR: "
    echo "ERROR: ======================"
    echo "ERROR: "
else
    echo "Massage: 规范化检查通过！！！"
fi

# 启动任务并获取任务ID
echo "正在向服务器汇报git-push信息"
response=$(curl -X POST -H "Content-Type: application/json" -d "$JSON_DATA" "$START_ENDPOINT")
task_id=$(echo "$response" | jq -r '.task_id')

echo "服务器正在查询用户权限"
echo "Response from server: $response"
echo "Task started with ID: $task_id"

echo "正在查询服务器权限，查询上限[$CHECK_MAX_COUNT],查询间隔[$CHECK_INTERVAL]s"

while [ $CHECK_COUNT -lt $CHECK_MAX_COUNT ]; do
    # 轮询计数
    # shellcheck disable=SC2004
    CHECK_COUNT=$(($CHECK_COUNT + 1))
    echo "第[$CHECK_COUNT]次 查询权限"

    # 检查任务状态
    status_response=$(curl -s "$CHECK_ENDPOINT/$task_id")
    status=$(echo "$status_response" | jq -r '.status')
    echo "$status_response"

    if [ "$status" == "completed" ]; then
        echo "Task completed successfully."
        break
    elif [ "$status" == "running" ]; then
        echo "Task is still running..."
    elif [ "$status" == "error" ]; then
        echo "Error Invalid task ID： $task_id"
        sleep 3
        exit 1
    else
        echo "Error or unknown status."
        sleep 3
        exit 1
    fi

    if [ $CHECK_COUNT == $CHECK_MAX_COUNT ];then
        echo "已达到查询次数上限[$CHECK_MAX_COUNT]，push终止。"
        sleep 3
        exit 1
    fi

    # 任务未完成时暂停，之后继续轮询
    sleep $CHECK_INTERVAL
done


# 解析 task 数组
sever_task=$(echo "$status_response" | jq -r '.task')

# 遍历 task 数组中的消息
echo "$sever_task" | jq -c -r '.[1:][]' | while IFS= read -r remote_message; do
    echo "$remote_message"
done

# 获取第一个元素来决定是否允许上传
allow_push=$(echo "$sever_task" | jq -r '.[0]')

# 判断是否允许上传
if [ "$allow_push" == "true" ]; then
    echo "允许上传"
    sleep 5
    exit 0
else
    echo "拒绝上传"
    sleep 5
    exit 1
fi