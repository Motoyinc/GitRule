#!/bin/bash
locale
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8


# 加载配置文件
config_file="config.json"


# 检查是否启用脚本
CHECK_SEVER_ENABLE=$(jq -r '.CHECK_SEVER_ENABLE' $config_file)
if [[ $CHECK_SEVER_ENABLE == true ]]; then
  ehco "检查服务已启用"
else
  ehco "检查服务已关闭"
  exit 0
fi


# 基础参数
CHECK_SEVER_URL=$(jq -r '.CHECK_SEVER_URL' $config_file)
CHECK_SEVER_START=$(jq -r '.CHECK_SEVER_START' $config_file)
CHECK_SEVER_CHECK_STAGE=$(jq -r '.CHECK_SEVER_CHECK_STAGE' $config_file)
START_ENDPOINT="$CHECK_SEVER_URL/$CHECK_SEVER_START"
CHECK_ENDPOINT="$CHECK_SEVER_URL/$CHECK_SEVER_CHECK_STAGE"


# 脚本最大运行次数、时长
CHECK_COUNT=0
CHECK_MAX_COUNT=$(jq -r '.CHECK_MAX_COUNT' $config_file)
CHECK_INTERVAL=$(jq -r '.CHECK_INTERVAL' $config_file)


# push信息预处理
commit_message="#114514  Edit-Wip(Art) NONE : 角色模型"
commit_message_format=false
pattern='^#([0-9]+)[[:space:]]+([A-Za-z]+)-([A-Za-z]+)\(([A-Za-z]+)\)[[:space:]]+([A-Za-z,]+)[[:space:]]*:[[:space:]]*(.+)$'
if [[ $commit_message =~ $pattern ]]; then
    commit_message_format=true
    issue_id="${BASH_REMATCH[1]}"
    edit_type="${BASH_REMATCH[2]}"
    edit_status="${BASH_REMATCH[3]}"
    user_role="${BASH_REMATCH[4]}"
    push_cmd="${BASH_REMATCH[5]}"
    description="${BASH_REMATCH[6]}"
    echo "Message: "
    echo "Message: ！！！！！！规范化检查通过！！！！！！"
    echo "Message: "
    echo "Message: ======================"
    echo "Message: "
    echo "Message: 单号 Issue id: $issue_id"
    echo "Message: 编辑类型 Edit Type: $edit_type"
    echo "Message: 编辑状态 Edit Status: $edit_status"
    echo "Message: 用户角色 User Role: $user_role"
    echo "Message: 上传命令 Push cmd: $push_cmd"   # 【上传命令 Push cmd】 用于在上传后由CICD根据上传的文件哈希值创建一个时间戳证书
    echo "Message: 描述 Description: $description"
    echo "Message: "
    echo "Message: ======================"
    echo "Message: "
else
    echo "ERROR: "
    echo "ERROR: ！！！！！！规范化检查大失败！！！！！！"
    echo "ERROR: 请按以下规范化格式提交"
    echo "ERROR: "
    echo "ERROR: ======================"
    echo "ERROR: "
    echo "ERROR: 格式："
    echo "ERROR: #<单号> <编辑类型>-<编辑状态>(<用户角色>) <上传命令>: <描述>"
    echo "ERROR: "
    echo "ERROR: 示例："
    echo "ERROR: #114514 Edit-Wip(Art) NONE: 角色需求模型"
    echo "ERROR: "
    echo "ERROR: ======================"
    echo "ERROR: "
    commit_message_format=false
fi

### 常用的<编辑类型>
## 美术需求
#Edit-Wip
#Edit-Done
#Fix-Wip
#Fix-Done

## 代码需求
#Feat-Wip
#Feat-Done
#Refactor-Wip
#Refactor-Done
#Fix-Wip
#Fix-Done

## 通用需求
#Edit-Wip
#Edit-Done


# 打包检查服务器的所需的信息
# 测试用，从Gitlab获取的信息
GL_USERNAME="Motoyinc"
GL_PROJECT_PATH="devgroup/SRPJ"
L_ID="user-3"
GL_REPOSITORY="project-2"
JSON_DATA="{\"username\":\"$GL_USERNAME\", \"project_path\":\"$GL_PROJECT_PATH\", \"id\":\"$L_ID\", \"repository\":\"$GL_REPOSITORY\"}"


# 启动检查服务器应用
echo "正在向服务器汇报git-push信息"
response=$(curl -X POST -H "Content-Type: application/json" -d "$JSON_DATA" "$START_ENDPOINT")
task_id=$(echo "$response" | jq -r '.task_id')


# 轮询检查服务器应用
echo "服务器正在查询用户权限"
echo "Response from server: $response"
echo "Task started with ID: $task_id"
echo "正在查询服务器权限，查询上限[$CHECK_MAX_COUNT],查询间隔[$CHECK_INTERVAL]s"
while [ $CHECK_COUNT -lt $CHECK_MAX_COUNT ]; do

    # 轮询计数
    CHECK_COUNT=$(($CHECK_COUNT + 1))
    echo "第[$CHECK_COUNT]次 查询权限"

    # 触发轮询
    status_response=$(curl -s "$CHECK_ENDPOINT/$task_id")
    status=$(echo "$status_response" | jq -r '.status')
    echo "$status_response"

    # 检查轮询状态
    if [ "$status" == "completed" ]; then
        echo "Task completed successfully."
        break
    elif [ "$status" == "running" ]; then
        echo "Task is still running..."
    elif [ "$status" == "error" ]; then
        echo "Error Invalid task ID： $task_id"
        exit 1
    else
        echo "Error or unknown status."
        exit 1
    fi

    # 检查轮询次数
    if [ $CHECK_COUNT == $CHECK_MAX_COUNT ];then
        echo "已达到查询次数上限[$CHECK_MAX_COUNT]，push终止。"
        exit 1
    fi

    # 任务未完成时暂停，之后继续轮询
    sleep $CHECK_INTERVAL
done


# 输出服务器消息
sever_task=$(echo "$status_response" | jq -r '.task')
echo "$sever_task" | jq -c -r '.[1:][]' | while IFS= read -r remote_message; do
    echo "$remote_message"
done


# 检查服务器返回的结果
allow_push=$(echo "$sever_task" | jq -r '.[0]')
if [ "$allow_push" == "true" ]; then
    echo "允许上传"
    sleep 5
    exit 0
else
    echo "拒绝上传"
    sleep 5
    exit 1
fi