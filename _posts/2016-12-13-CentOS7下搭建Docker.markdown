---
layout:     post
title:      "CentOS7下搭建Docker"
date:       2016-12-13
author:     "Milin"
catalog:    true
tags:
 - 技术
 - CentOS7
 - Docker
---

# 1. 增加yum仓库
    tee /etc/yum.repos.d/docker.repo <<-'EOF'
    [dockerrepo]
    name=Docker Repository
    baseurl=https://yum.dockerproject.org/repo/main/centos/7/
    enabled=1
    gpgcheck=1
    gpgkey=https://yum.dockerproject.org/gpg
    EOF

# 2. 执行安装命令
    yum install docker-engine

# 3. 设置自启动
    systemctl enable docker

# 4. 注册并登录daocloud.io获取加速器
>由于国内各种墙，故需要加速器中转镜像服务器

    curl -sSL https://get.daocloud.io/daotools/set_mirror.sh | sh -s http://*********.m.daocloud.io

`以上命令中的加速器mirror url(http://*********.m.daocloud.io)需要自行注册获取`

# 5. 启动Docker并测试
    systemctl start docker
    docker run --rm hello-world

# 6. 搭建Docker私仓
执行以下命令获取对应image并运行registry

    docker run -d --name registry --restart=always -v /tmp/registry:/tmp/registry -p 5000:5000 registry

`注意：`*由于新版本docker向registry交互使用https协议，故需要以下二选一的配置*

1. 在docker启动参数中加入此registry相关配置，使用http协议，需要在/etc/docker/daemon.json中加入

    {
        ...
        "insecure-registries":["your-registry-host:5000"]
    }

2. 配置私仓使用https协议，参考<https://docs.docker.com/registry/insecure/>

### 6.1 与私仓相关操作
向私仓push image：

    docker build -t your-image:latest
    docker tag your-image your-registry-host:5000/library/your-image:latest
    docker push your-registry-host:5000/library/your-image:latest

从私仓pull image：

    docker pull your-registry-host:5000/library/your-image:latest

运行私仓image：

    docker run -d --restart=always your-registry-host:5000/library/your-image:latest

### 6.2 搭建私仓UI界面
运行以下命令
    docker run -d --name registry-ui -p 8080:8080 atcol/docker-registry-ui

通过localhost:8080访问ui界面，并配置使用