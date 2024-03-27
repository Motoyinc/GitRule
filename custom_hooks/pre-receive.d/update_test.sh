#!/bin/bash



#!/bin/bash

GL_USERNAME="Motoyinc"
GL_PROJECT_PATH="devgroup/SRPJ"
L_ID="user-3"
GL_REPOSITORY="project-2"
JSON_DATA="{\"username\":\"$GL_USERNAME\", \"project_path\":\"$GL_PROJECT_PATH\", \"id\":\"$L_ID\", \"repository\":\"$GL_REPOSITORY\"}"

# 更新规则请求
curl -X POST  http://127.0.0.1:5000/pullRule/update

# 发生数据请求
curl -X POST -H "Content-Type: application/json" -d "$JSON_DATA" http://127.0.0.1:5000/pullRule/start
curl -X POST -H "Content-Type: application/json" -d '{"key1":"value1", "key2":"value2"}' http://127.0.0.1:5000/pullRule/start