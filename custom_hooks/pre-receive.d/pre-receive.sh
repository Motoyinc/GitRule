#!/bin/bash
# 还没开始写，先放个测试用的脚本
while read oldrev newrev refname; do
    branch=$(git rev-parse --symbolic --abbrev-ref $refname)
    GITLAB_TOKEN="xxxxxxxx"
    PROJECT_ID="2"
    ISSUES_URL="https://xxxxx/api/v4/projects/${PROJECT_ID}/issues"
    API_URL="https://xxxxx/api/v4/projects/${PROJECT_ID}"
    AUTH_HEADER="Authorization: Bearer ${GITLAB_TOKEN}"
    response=$(curl -sS --header "${AUTH_HEADER}" "${API_URL}")
    issues=$(curl -sS --header "${AUTH_HEADER}" "${ISSUES_URL}")

    # 检查是否有提交，如果有则拒绝
    if [ "$oldrev" != "0000000000000000000000000000000000000000" ]; then
        echo "[Error]Pushing to $branch "
        echo "$GL_USERNAME"
        echo "$GL_PROJECT_PATH"
        echo "$GL_ID"
        echo "$GL_REPOSITORY"
        echo "$response"
        echo "$issues"
        exit 1
    fi
