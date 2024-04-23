#!/bin/bash

# commit_data=$(cat)

# echo "$commit_data" | while read oldrev newrev refname; do
#     echo "Old Rev: $oldrev, New Rev: $newrev, Ref Name: $refname"

#     # 获取commis 信息
#     echo "Commit descriptions:"
#     git log --pretty=format:"%s" $oldrev..$newrev

#     # 基于 refname 的前缀来判断是分支还是标签
#     if [[ $refname =~ refs/heads/ ]]; then
#         ref_type="分支"
#         ref_name="${refname#refs/heads/}"
#     elif [[ $refname =~ refs/tags/ ]]; then
#         ref_type="标签"
#         ref_name="${refname#refs/tags/}"
#     else
#         ref_type="未知类型"
#         ref_name="$refname"
#     fi

#     # 判断是创建、删除还是更新操作
#     if [[ $oldrev == 0000000000000000000000000000000000000000 ]]; then
#         action="创建了新的 $ref_type"
#     elif [[ $newrev == 0000000000000000000000000000000000000000 ]]; then
#         action="删除了 $ref_type"M
#     else
#         action="更新了 $ref_type"
#     fi
#     exit 1
# done

# exit 1
while read oldrev newrev refname; do
    branch=$(git rev-parse --symbolic --abbrev-ref $refname)
    GITLAB_TOKEN="glpat-axmq2Wbd6MxGvyAKWJvw"
    PROJECT_ID="2"
    ISSUES_URL="https://git.motoyinc.com/api/v4/projects/${PROJECT_ID}/issues"
    API_URL="https://git.motoyinc.com/api/v4/projects/${PROJECT_ID}"
    AUTH_HEADER="Authorization: Bearer ${GITLAB_TOKEN}"
    response=$(curl -sS --header "${AUTH_HEADER}" "${API_URL}")
    issues=$(curl -sS --header "${AUTH_HEADER}" "${ISSUES_URL}")
    START_ENDPOINT="http://192.168.1.3:5000/pullRule/start"

    # 检查是否有提交，如果有则拒绝
    if [ "$oldrev" != "0000000000000000000000000000000000000000" ]; then
        echo "[Error]Pushing to $branch "
        echo "$GL_USERNAME"
        echo "$GL_PROJECT_PATH"
        # echo "$GL_ID"
        # echo "$GL_REPOSITORY"
        # echo "$response"
        echo "$issues"
        JSON_DATA="{\"username\":\"$GL_USERNAME\",  \"repository\":\"$GL_REPOSITORY\"}"
        response=$(curl -X POST -H "Content-Type: application/json" -d "$JSON_DATA" "$START_ENDPOINT")
        echo "中文文本输出"
        echo "1234567890"
        exit 1
    fi
done
exit 1