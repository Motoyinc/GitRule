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

-----

# 【配置必要环境】
# 为git-bash配置jp命令
为了确保开发和测试的便捷性，本文档主要介绍如何在Windows环境下配置`jp`（jq）命令，以及在Linux环境下安装jq。`jp`是`jq`的一个别名，jq是一款轻量级且灵活的命令行JSON处理器。

## 为windows安装jp

1. **简介**：由于在Linux上测试代码可能不太方便，我们需要在Windows环境中设置测试环境。

2. **下载 jp.exe**：
   - 访问[jq官方下载页面](https://stedolan.github.io/jq/download/)以获取jq的Windows版本。
   - 直接点击链接 [https://jqlang.github.io/jq/download/](https://jqlang.github.io/jq/download/) 下载`jp.exe`文件。

3. **选择对应版本**：
   - 查找并下载适用于你的系统架构的jq可执行文件。
   - AMD64适用于Windows 64位系统。
   - i386适用于Windows 32位系统（x86）。

4. **保存 jp.exe**：
   - 为了方便使用，建议将`jp.exe`文件保存到git的安装目录下的`bin`文件夹中，例如：`D:\Program Files\Git\mingw64\bin`。

5. **启用 jp.exe**：
   - 在git bash中执行以下命令来设置`jp`别名：
     ```bash
     alias jq="D:/Program\ Files/Git/mingw64/bin/jq-windows-amd64.exe"
     ```
   - 注意路径中的空格需要使用`\`进行转义。

6. **测试 jp.exe**：
   - 执行以下命令测试`jp`是否配置成功：
     ```bash
     jq --version
     ```
   - 如果返回了jq的版本号，则表示`jp`已经可以在git bash中正常使用。


## 为linux安装jp

1. **简介**：由于最终的运行环境通常是Linux，因此在Linux上也需要安装jq。

2. **安装jq**：
   - 使用以下命令更新软件包列表并安装jq：
     ```bash
     sudo apt update
     sudo apt install jq
     ```
   - 这些命令适用于基于Debian的发行版，如Ubuntu。其他发行版可能需要使用不同的包管理器，如`yum`或`zypper`。

通过以上步骤，你应该已经在Windows和Linux环境中成功配置了`jp`命
