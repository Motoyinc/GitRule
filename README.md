## GitRule App 部署指南

此指南旨在帮助你在Linux服务器上部署GitRule应用。

### 【前提条件】

- 一个Linux服务器，Docker已安装在服务器上
- GitLab中的Git Hooks功能已开启

### 【部署步骤】

#### 开启Git Hooks (适用于gitlab16社区版)

1. 如果你的GitLab是通过Docker安装的，请修改GitLab配置文件`gitlab.rb`以开启GitLab Hook功能。

    ```bash
    docker exec -it <gitlab docker 容器名称> /bin/bash
    sudo vi /etc/gitlab/gitlab.rb
    ```

2. 找到以下内容并取消注释：

    ```bash
    # gitaly['configuration'] = {
    ```

    ```bash
    # hooks: {
    # custom_hooks_dir: '/var/opt/gitlab/gitaly/custom_hooks',
    # },
    ```

    > 示例 `gitlab.rb` 配置文件片段：

    ```bash
    # gitaly['consul_service_meta'] = {}
     gitaly['configuration'] = {
    #
    #   ...
    #   中间有一大段和本主题无关的内容
    #   ...
    #   
        hooks: {
        custom_hooks_dir: '/var/opt/gitlab/gitaly/custom_hooks',
    },
    ```

3. 找到存放Git Hooks的位置：

    找到Gitaly的配置文件`config.toml`，默认地址在`/var/opt/gitlab/gitaly`。

    ```bash
    sudo vi /var/opt/gitlab/gitaly/config.toml
    ```

    在配置文件中，[[storage]]项代表单个仓库的项目地址，而[hooks]则是全局仓库hooks的位置。

    ```bash
    [[storage]]
    name = "default"
    path = "/var/opt/gitlab/git-data/repositories"

    [hooks]
    custom_hooks_dir = "/var/opt/gitlab/gitaly/custom_hooks"
    ```

    比如，`/var/opt/gitlab/git-data/repositories` 加上相对路径就是单个仓库的地址。

    创建一个`custom_hooks`文件夹：

    ```bash
    sudo mkdir /var/opt/gitlab/git-data/repositories/@hashed/d4/73/d47353d0c07d8b6c5f59718b9b51f90de3a2301965e16eee0a3a666ec13ab35.git/custom_hooks
    ```

4. 将本仓库的`gitRule/custom_hooks`里的内容拷贝到对应的`custom_hooks`文件夹下即可。

#### 生成Web镜像

将`gitrule_app`文件夹拷贝到Linux服务器上。此文件夹应包含应用的所有代码和Dockerfile。

1. 打开终端并切换到`gitrule_app`文件夹的目录下：

    ```bash
    cd gitrule_app
    ```

2. 使用Dockerfile生成Web镜像：

    ```bash
    docker build -t gitrule_app_image .
    ```

   这里，`gitrule_app_image`是镜像的名称，你可以根据需要命名。

#### 启动Web服务

启动前面创建的Docker镜像，并映射5000号端口到主机的一个可用端口。

1. 使用以下命令启动容器：

    ```bash
    docker run -d -p 5000:5000 --name gitrule_app_container gitrule_app_image
    ```

   - `-d`选项表示后台运行容器。
   - `-p 5000:5000`将容器的5000端口映射到主机的8080端口，根据实际情况调整端口号。
   - `--name gitrule_app_container`为容器命名，方便后续管理。
   - `gitrule_app_image`是之前创建的Docker镜像名称。

现在，GitRule应用应该已经在你的Linux服务器上成功部署，并通过映射的端口对外提供服务。确保GitLab服务器的钩子配置正确，以实现预期的集成效果。

-----

# 【功能说明】

这是一个用于GitLab的`pre-receive`钩子的远端Web服务，旨在检测Git推送操作并进行必要的验证。服务允许GitLab在检测到用户推送任务时，通过钩子将任务信息发送至远端应用进行检测。

## 基本流程

1. **触发检测**：当GitLab服务器上的`pre-receive`钩子检测到一个推送任务时，它会将相关任务信息发送到远端Web服务的`/pullRule/start`端点，启动检测过程。
2. **返回任务ID**：远端应用接收到检测请求后，将启动检测任务，并返回一个任务ID (`task_id`)，供后续查询使用。
3. **查询任务状态**：`pre-receive`钩子使用返回的任务ID，通过访问`/pullRule/checkStage/<task_id>`端点，查询检测任务的执行状态。
4. **获取检测结果**：一旦检测完成，`pre-receive`钩子将获取检测结果，并据此决定是否允许推送操作完成。同时，钩子会向推送者反馈检测信息，告知推送是否成功。

## 端点说明

- **启动检测**：
  - **URL**：`http://127.0.0.1/pullRule/start`
  - **方法**：POST
  - **功能**：接收推送任务信息，并启动检测过程。

- **查询任务状态**：
  - **URL**：`http://127.0.0.1/pullRule/checkStage/<task_id>`
  - **方法**：GET
  - **功能**：使用任务ID查询检测任务的执行状态，并获取结果。

- **更新检测规则**：
  - **URL**：`http://127.0.0.1/pullRule/appUpdate`
  - **方法**：POST
  - **功能**：从`https://github.com/Motoyinc/gitRule.git` 拉取最新的检测规则到远端服务，确保检测使用的是最新规则。

