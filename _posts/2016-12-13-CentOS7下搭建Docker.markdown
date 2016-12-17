---
layout:     post
title:      "CentOS7下搭建Docker"
date:       2016-12-13
author:     "Milin"
catalog:    true
tags:
 - 技术
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

# 4. 注册并登录daocload.io获取加速器
>由于国内各种墙，故需要加速器中转镜像服务器

    curl -sSL https://get.daocloud.io/daotools/set_mirror.sh | sh -s http://*********.m.daocloud.io

`以上命令中的加速器mirror url(http://*********.m.daocloud.io)需要自行注册获取`

# 5. 启动Docker并测试
    systemctl start docker
    docker run --rm hello-world