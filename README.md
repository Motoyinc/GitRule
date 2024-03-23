# GitLab服务器钩子与远端Web服务集成

这是一个用于GitLab的`pre-receive`钩子的远端Web服务，旨在检测Git推送操作并进行必要的验证。服务允许GitLab在检测到用户推送任务时，通过钩子将任务信息发送至远端应用进行检测。

## 基本流程

1. **触发检测**：当GitLab服务器上的`pre-receive`钩子检测到一个推送任务时，它会将相关任务信息发送到远端Web服务的`/start-pullRule`端点，启动检测过程。
2. **返回任务ID**：远端应用接收到检测请求后，将启动检测任务，并返回一个任务ID (`task_id`)，供后续查询使用。
3. **查询任务状态**：`pre-receive`钩子使用返回的任务ID，通过访问`/checkStage-pullRule/<task_id>`端点，查询检测任务的执行状态。
4. **获取检测结果**：一旦检测完成，`pre-receive`钩子将获取检测结果，并据此决定是否允许推送操作完成。同时，钩子会向推送者反馈检测信息，告知推送是否成功。

## 端点说明

- **启动检测**：
  - **URL**：`http://xxxxx/start-pullRule`
  - **方法**：POST
  - **功能**：接收推送任务信息，并启动检测过程。

- **查询任务状态**：
  - **URL**：`http://xxxxx/checkStage-pullRule/<task_id>`
  - **方法**：GET
  - **功能**：使用任务ID查询检测任务的执行状态，并获取结果。

- **更新检测规则**：
  - **URL**：`http://xxxxx/update-pullRule`
  - **方法**：POST
  - **功能**：从`https://github.com/Motoyinc/gitRule.git`拉取最新的检测规则到远端服务，确保检测使用的是最新规则。

## 设置指南

1. **配置GitLab服务器的`pre-receive`钩子**：在GitLab服务器上，配置`pre-receive`钩子，使其能够在检测到推送时调用远端Web服务的相应端点。
2. **部署远端Web服务**：确保远端Web服务已按照上述端点描述进行配置，并可从GitLab服务器访问。
3. **更新检测规则**：定期或根据需要调用`/update-pullRule`端点，从指定的Git仓库更新检测规则。
